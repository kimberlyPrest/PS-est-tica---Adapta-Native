-- P2-S06-T01 — Ambiente de execução de agentes, tabelas de registro e guardião
-- SPEC-P2-S06-triagem-guardiao-respostas-aprovadas.md + 00-CONTRATO-COMUM-FASE-2.md
-- Migration ADITIVA. Nada existente é alterado.
-- Tabelas: agent_definitions, agent_clinic_configs, agent_runs, agent_steps,
--          agent_decisions, knowledge_items, policy_rules, message_templates,
--          intent_routes, feature_flags (SPEC cita feature_flags — não existia; criada aqui).
-- RLS: leitura is_clinic_member; config escrita has_clinic_role(owner,clinic_admin);
--      execuções/eventos só service_role (sem policy INSERT para authenticated).
-- Regras globais do guardião (AG-13) vêm por migration (policy_rules scope='global').

-- ===== feature_flags (interruptor por clínica; a auto-resposta nasce DESLIGADA) =====
CREATE TABLE IF NOT EXISTS public.feature_flags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL,
  clinic_id uuid NOT NULL,
  flag_key text NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  config jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (clinic_id, flag_key)
);

-- ===== agent_definitions (catálogo global AG-01..AG-14; escrita só servidor/migration) =====
CREATE TABLE IF NOT EXISTS public.agent_definitions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE CHECK (key ~ '^AG-[0-9]{2}$'),
  name text NOT NULL,
  version int NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published')),
  tool_allowlist text[] NOT NULL DEFAULT '{}',
  max_autonomy text NOT NULL DEFAULT 'sugerir' CHECK (max_autonomy IN ('sugerir','responder_aprovado')),
  output_schema jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ===== agent_clinic_configs (valor efetivo: clínica → organização) =====
CREATE TABLE IF NOT EXISTS public.agent_clinic_configs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL,
  clinic_id uuid NOT NULL REFERENCES public.clinics(id),
  agent_key text NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  model_policy jsonb NOT NULL DEFAULT '{}',
  thresholds jsonb NOT NULL DEFAULT '{"confianca_min": 0.85}',
  budgets jsonb NOT NULL DEFAULT '{"custo_dia_centavos": 2000, "chamadas_dia": 3000}',
  prompt_version_id uuid,
  version int NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','paused')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (clinic_id, agent_key)
);

-- ===== agent_runs (sem texto de entrada ou saída — só metadados) =====
CREATE TABLE IF NOT EXISTS public.agent_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL,
  clinic_id uuid NOT NULL,
  agent_key text NOT NULL,
  agent_version int NOT NULL DEFAULT 1,
  prompt_version_id uuid,
  trigger_ref uuid,
  status text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued','running','waiting_human','succeeded','failed','discarded')),
  input_tokens int,
  output_tokens int,
  cost_cents int,
  started_at timestamptz,
  finished_at timestamptz,
  error_code text,
  correlation_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_agent_runs_clinic ON public.agent_runs(clinic_id, created_at);

-- ===== agent_steps (imutável) =====
CREATE TABLE IF NOT EXISTS public.agent_steps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id uuid NOT NULL REFERENCES public.agent_runs(id),
  step int NOT NULL,
  tool text NOT NULL,
  status text NOT NULL CHECK (status IN ('ok','failed','skipped')),
  duration_ms int,
  error_code text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ===== agent_decisions =====
CREATE TABLE IF NOT EXISTS public.agent_decisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id uuid NOT NULL REFERENCES public.agent_runs(id),
  decision_type text NOT NULL CHECK (decision_type IN ('intent','route','reply')),
  value text,
  confidence numeric(4,3),
  guard_effect text CHECK (guard_effect IN ('allow','require_human','deny')),
  guard_reason text,
  knowledge_item_id uuid,
  human_outcome text CHECK (human_outcome IN ('sem_revisao','aceito','rejeitado')),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ===== knowledge_items (conteúdo aprovado; check de termos comerciais na aprovação) =====
CREATE TABLE IF NOT EXISTS public.knowledge_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL,
  clinic_id uuid REFERENCES public.clinics(id),
  category text NOT NULL CHECK (category IN ('endereco','horario','como_chegar','contato','procedimento_info','outro')),
  question_examples text[] NOT NULL DEFAULT '{}',
  answer text NOT NULL,
  auto_reply_allowed boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','approved','archived')),
  approved_by uuid,
  approved_at timestamptz,
  version int NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ===== policy_rules (regras do guardião; globais por migration; clínica só acrescenta) =====
CREATE TABLE IF NOT EXISTS public.policy_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scope text NOT NULL DEFAULT 'clinic' CHECK (scope IN ('global','clinic')),
  clinic_id uuid REFERENCES public.clinics(id),
  rule_key text NOT NULL,
  condition jsonb NOT NULL DEFAULT '{}',
  effect text NOT NULL CHECK (effect IN ('allow','require_human','deny')),
  reason_code text NOT NULL,
  priority int NOT NULL DEFAULT 100,
  version int NOT NULL DEFAULT 1,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ===== message_templates (por provedor; check de termos comerciais calculado) =====
CREATE TABLE IF NOT EXISTS public.message_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL,
  clinic_id uuid NOT NULL,
  provider text NOT NULL CHECK (provider IN ('meta_cloud','z_api')),
  purpose text NOT NULL CHECK (purpose IN ('fora_expediente','espera','resposta_aprovada','followup','campanha')),
  name text NOT NULL,
  language text NOT NULL DEFAULT 'pt_BR',
  body text NOT NULL,
  contains_commercial_terms boolean NOT NULL DEFAULT false,
  external_template_id text,
  provider_status text NOT NULL DEFAULT 'not_required' CHECK (provider_status IN ('not_required','pending','approved','rejected')),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','approved','archived')),
  version int NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (clinic_id, provider, purpose, name)
);

-- ===== intent_routes (tabela de rotas por clínica; carga inicial da SPEC) =====
CREATE TABLE IF NOT EXISTS public.intent_routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id),
  intent text NOT NULL CHECK (intent IN ('informacao_geral','interesse_procedimento','preco_condicao','pedido_agendamento','reagendamento_cancelamento','pos_procedimento','reclamacao','financeiro','atendimento_humano','desconhecido')),
  queue_id uuid,
  priority int NOT NULL DEFAULT 2 CHECK (priority IN (1,2,3)),
  auto_reply_allowed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (clinic_id, intent)
);

-- ===== updated_at (gatilho) =====
CREATE OR REPLACE FUNCTION public.tg_touch_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at := now(); RETURN NEW; END $$;

DO $$ DECLARE t text;
BEGIN
  FOR t IN SELECT y FROM unnest(ARRAY['feature_flags','agent_definitions','agent_clinic_configs','agent_runs','knowledge_items','policy_rules','message_templates','intent_routes']) AS y LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_touch_%s ON public.%I', t, t);
    EXECUTE format('CREATE TRIGGER trg_touch_%s BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.tg_touch_updated_at()', t, t);
  END LOOP;
END $$;

-- ===== RLS =====
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_clinic_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.knowledge_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.policy_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intent_routes ENABLE ROW LEVEL SECURITY;

-- feature_flags: leitura por vínculo; escrita owner/clinic_admin
CREATE POLICY rls_ff_select ON public.feature_flags FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_ff_write ON public.feature_flags FOR ALL USING (public.has_clinic_role(clinic_id, ARRAY['owner','clinic_admin'])) WITH CHECK (public.has_clinic_role(clinic_id, ARRAY['owner','clinic_admin']));

-- agent_definitions: catálogo global — leitura por qualquer vínculo da organização
CREATE POLICY rls_ad_select ON public.agent_definitions FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.memberships m WHERE m.user_id = auth.uid() AND m.active));

-- agent_clinic_configs: leitura por vínculo; escrita owner/clinic_admin
CREATE POLICY rls_acc_select ON public.agent_clinic_configs FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_acc_write ON public.agent_clinic_configs FOR ALL USING (public.has_clinic_role(clinic_id, ARRAY['owner','clinic_admin'])) WITH CHECK (public.has_clinic_role(clinic_id, ARRAY['owner','clinic_admin']));

-- agent_runs/steps/decisions: leitura por vínculo; INSERT só service_role (sem policy INSERT)
CREATE POLICY rls_runs_select ON public.agent_runs FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_steps_select ON public.agent_steps FOR SELECT USING (EXISTS (SELECT 1 FROM public.agent_runs r WHERE r.id = agent_steps.run_id AND public.is_clinic_member(r.clinic_id)));
CREATE POLICY rls_decisions_select ON public.agent_decisions FOR SELECT USING (EXISTS (SELECT 1 FROM public.agent_runs r WHERE r.id = agent_decisions.run_id AND public.is_clinic_member(r.clinic_id)));

-- knowledge_items: leitura por vínculo (clínica ou organização); escrita owner/clinic_admin
CREATE POLICY rls_ki_select ON public.knowledge_items FOR SELECT USING (
  (clinic_id IS NOT NULL AND public.is_clinic_member(clinic_id))
  OR (clinic_id IS NULL AND public.is_org_member(organization_id)));
CREATE POLICY rls_ki_write ON public.knowledge_items FOR ALL USING (
  (clinic_id IS NOT NULL AND public.has_clinic_role(clinic_id, ARRAY['owner','clinic_admin']))
  OR (clinic_id IS NULL AND EXISTS (SELECT 1 FROM public.memberships m WHERE m.user_id = auth.uid() AND m.organization_id = knowledge_items.organization_id AND m.clinic_id IS NULL AND m.active AND m.role = 'owner')))
WITH CHECK (
  (clinic_id IS NOT NULL AND public.has_clinic_role(clinic_id, ARRAY['owner','clinic_admin']))
  OR (clinic_id IS NULL AND EXISTS (SELECT 1 FROM public.memberships m WHERE m.user_id = auth.uid() AND m.organization_id = knowledge_items.organization_id AND m.clinic_id IS NULL AND m.active AND m.role = 'owner')));

-- policy_rules: leitura por vínculo (global para todos); escrita owner/clinic_admin (clínica) — globais só migration
CREATE POLICY rls_pr_select ON public.policy_rules FOR SELECT USING (
  scope = 'global'
  OR (clinic_id IS NOT NULL AND public.is_clinic_member(clinic_id)));
CREATE POLICY rls_pr_write ON public.policy_rules FOR ALL USING (
  scope = 'clinic' AND clinic_id IS NOT NULL AND public.has_clinic_role(clinic_id, ARRAY['owner','clinic_admin']))
WITH CHECK (
  scope = 'clinic' AND clinic_id IS NOT NULL AND public.has_clinic_role(clinic_id, ARRAY['owner','clinic_admin']));

-- message_templates: leitura por vínculo; escrita owner/clinic_admin
CREATE POLICY rls_mt_select ON public.message_templates FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_mt_write ON public.message_templates FOR ALL USING (public.has_clinic_role(clinic_id, ARRAY['owner','clinic_admin'])) WITH CHECK (public.has_clinic_role(clinic_id, ARRAY['owner','clinic_admin']));

-- intent_routes: leitura por vínculo; escrita owner/clinic_admin
CREATE POLICY rls_ir_select ON public.intent_routes FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_ir_write ON public.intent_routes FOR ALL USING (public.has_clinic_role(clinic_id, ARRAY['owner','clinic_admin'])) WITH CHECK (public.has_clinic_role(clinic_id, ARRAY['owner','clinic_admin']));

-- ===== Catálogo inicial de agentes (AG-01..AG-14) =====
INSERT INTO public.agent_definitions (key, name, status, tool_allowlist, max_autonomy) VALUES
  ('AG-01','Triagem de intenção','published','{}','responder_aprovado'),
  ('AG-03','Agendamento (sugestão)','draft','{}','sugerir'),
  ('AG-04','Reagendamento/cancelamento (sugestão)','draft','{}','sugerir'),
  ('AG-05','Pós-procedimento (sugestão)','draft','{}','sugerir'),
  ('AG-06','Follow-up','draft','{}','sugerir'),
  ('AG-07','Pipeline/vendas (sugestão)','draft','{}','sugerir'),
  ('AG-08','Agenda (espelho)','draft','{}','sugerir'),
  ('AG-09','Vendas (espelho)','draft','{}','sugerir'),
  ('AG-10','Escrita controlada','draft','{}','sugerir'),
  ('AG-11','Gerente (resumos)','draft','{}','sugerir'),
  ('AG-12','Campanhas','draft','{}','sugerir'),
  ('AG-13','Guardião de políticas','published','{}','sugerir'),
  ('AG-14','Copiloto da atendente','draft','{}','sugerir')
ON CONFLICT (key) DO NOTHING;

-- ===== Regras globais do guardião (ordem = priority; a primeira que casar decide) =====
INSERT INTO public.policy_rules (scope, clinic_id, rule_key, condition, effect, reason_code, priority, version) VALUES
  ('global', NULL, 'transbordo_ativo', '{"conversa_automation_paused": true}', 'deny', 'transbordo_ativo', 10, 1),
  ('global', NULL, 'auto_resposta_desligada', '{"flag": "auto_resposta", "enabled": false}', 'require_human', 'auto_resposta_desligada', 20, 1),
  ('global', NULL, 'recusa_do_contato', '{"consent_purpose": "promocional", "status": "recusado", "acao_diferente_de": "atendimento"}', 'deny', 'recusa_do_contato', 30, 1),
  ('global', NULL, 'fora_do_horario', '{"em_expediente": false}', 'require_human', 'fora_do_horario', 40, 1),
  ('global', NULL, 'intencao_exige_humano', '{"rota_auto_reply_allowed": false}', 'require_human', 'intencao_exige_humano', 50, 1),
  ('global', NULL, 'baixa_confianca', '{"confidence_menor_que": "confianca_min"}', 'require_human', 'baixa_confianca', 60, 1),
  ('global', NULL, 'tema_sensivel', '{"termos": ["preço","preco","desconto","sintoma","dor","foto","alergia","reação","reacao","reclama","reclamação","reclamacao"]}', 'require_human', 'tema_sensivel', 70, 1),
  ('global', NULL, 'sem_conteudo_aprovado', '{"knowledge_item_aprovado": false}', 'require_human', 'sem_conteudo_aprovado', 80, 1),
  ('global', NULL, 'texto_nao_aprovado', '{"resposta_difere_do_aprovado": true}', 'deny', 'texto_nao_aprovado', 90, 1),
  ('global', NULL, 'orcamento_esgotado', '{"custo_dia_esgotado": true, "chamadas_dia_esgotadas": true}', 'require_human', 'orcamento_esgotado', 100, 1);

-- ===== grants =====
GRANT SELECT ON public.agent_definitions TO authenticated;
GRANT SELECT ON public.agent_runs, public.agent_steps, public.agent_decisions TO authenticated;
GRANT SELECT ON public.feature_flags, public.agent_clinic_configs, public.knowledge_items, public.policy_rules, public.message_templates, public.intent_routes TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.feature_flags, public.agent_clinic_configs, public.knowledge_items, public.policy_rules, public.message_templates, public.intent_routes TO authenticated;
