-- P2-S05-T01: tickets, expediente, presença e política de distribuição (config)
-- Tabelas: ticket_queues, business_hours, business_closures, user_shifts,
-- attendant_presence, routing_policies (versionada), tickets, ticket_events,
-- ticket_sla_events + emenda aditiva team_members (skills, max_concurrent).
-- RLS: leitura is_clinic_member; config só owner/clinic_admin; presença só o próprio.
-- RPCs de configuração: admin_save_queue, admin_save_hours, admin_save_policy,
-- admin_publish_policy, admin_rollback_policy, admin_list_policy_versions.
-- (v2: fix do expediente — UNIQUE com COALESCE(team_id) e upsert manual em admin_save_hours)

-- ===== Helper de papel (has_clinic_role não existe no banco real — lição P2-S02-T03).
-- Checagem direta em memberships ativas; SECURITY DEFINER para uso em policies.
CREATE OR REPLACE FUNCTION public.has_clinic_role(p_clinic uuid, p_roles text[])
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships m
    WHERE m.clinic_id = p_clinic
      AND m.user_id = auth.uid()
      AND m.active = true
      AND m.role = ANY (p_roles)
  );
$$;

-- ===== Emenda aditiva team_members (P1-S01) =====
ALTER TABLE public.team_members ADD COLUMN IF NOT EXISTS skills text[] NOT NULL DEFAULT '{}';
ALTER TABLE public.team_members ADD COLUMN IF NOT EXISTS max_concurrent int NOT NULL DEFAULT 5;

-- ===== ticket_queues =====
CREATE TABLE IF NOT EXISTS public.ticket_queues (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.organizations(id),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id),
  team_id uuid NOT NULL REFERENCES public.teams(id),
  name text NOT NULL,
  purpose text NOT NULL CHECK (purpose IN ('comercial','recepcao','pos_venda','geral')),
  priority_default int NOT NULL DEFAULT 2 CHECK (priority_default BETWEEN 1 AND 3),
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (clinic_id, name)
);

-- ===== business_hours =====
CREATE TABLE IF NOT EXISTS public.business_hours (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id),
  team_id uuid REFERENCES public.teams(id),
  weekday int NOT NULL CHECK (weekday BETWEEN 0 AND 6),
  opens_at time NOT NULL,
  closes_at time NOT NULL,
  timezone text NOT NULL DEFAULT 'America/Recife',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_business_hours_dia
  ON public.business_hours (clinic_id, COALESCE(team_id, '00000000-0000-0000-0000-000000000000'::uuid), weekday);

-- ===== business_closures =====
CREATE TABLE IF NOT EXISTS public.business_closures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id),
  date date NOT NULL,
  reason text NOT NULL CHECK (reason IN ('feriado','evento')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (clinic_id, date)
);

-- ===== user_shifts =====
CREATE TABLE IF NOT EXISTS public.user_shifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id),
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  status text NOT NULL DEFAULT 'planned' CHECK (status IN ('planned','absent')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_at > starts_at)
);

-- ===== attendant_presence =====
CREATE TABLE IF NOT EXISTS public.attendant_presence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id),
  state text NOT NULL DEFAULT 'offline' CHECK (state IN ('online','away','offline')),
  active_load int NOT NULL DEFAULT 0,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, clinic_id)
);

-- ===== routing_policies (versionada) =====
CREATE TABLE IF NOT EXISTS public.routing_policies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id),
  queue_id uuid NOT NULL REFERENCES public.ticket_queues(id),
  strategy text NOT NULL DEFAULT 'least_load' CHECK (strategy IN ('round_robin','least_load','skills_based','manual')),
  skills text[] NOT NULL DEFAULT '{}',
  accept_timeout_seconds int NOT NULL DEFAULT 120 CHECK (accept_timeout_seconds > 0),
  max_reoffers int NOT NULL DEFAULT 2 CHECK (max_reoffers >= 0),
  first_response_sla_minutes int NOT NULL DEFAULT 10 CHECK (first_response_sla_minutes > 0),
  backup_queue_id uuid REFERENCES public.ticket_queues(id),
  escalation_role text NOT NULL DEFAULT 'manager',
  after_hours_text text,
  fallback_mode text NOT NULL DEFAULT 'fila_aberta' CHECK (fallback_mode IN ('fila_aberta','plantonista')),
  version int NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published','archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_routing_policies_queue ON public.routing_policies(queue_id, status);

-- ===== tickets =====
CREATE TABLE IF NOT EXISTS public.tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.organizations(id),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id),
  conversation_id uuid NOT NULL REFERENCES public.conversations(id),
  queue_id uuid NOT NULL REFERENCES public.ticket_queues(id),
  status text NOT NULL DEFAULT 'new' CHECK (status IN ('new','queued','offered','assigned','in_service','waiting_customer','resolved','sla_breached','escalated','blocked','provider_failure','cancelled')),
  priority int NOT NULL DEFAULT 2 CHECK (priority BETWEEN 1 AND 3),
  handoff_reason text NOT NULL CHECK (handoff_reason IN ('pedido_humano','risco','baixa_confianca','falha_automacao','regra_negocio','manual')),
  intent text,
  assigned_to uuid REFERENCES auth.users(id),
  offered_to uuid REFERENCES auth.users(id),
  offer_expires_at timestamptz,
  reoffer_count int NOT NULL DEFAULT 0,
  sla_due_at timestamptz,
  accepted_at timestamptz,
  first_response_at timestamptz,
  resolved_at timestamptz,
  resolution_code text CHECK (resolution_code IN ('atendido','agendamento_encaminhado','sem_resposta_cliente','spam','transferido_outra_clinica')),
  resolution_note text,
  next_action_at timestamptz,
  version int NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (assigned_to IS NOT NULL OR status IN ('new','queued','offered','escalated','blocked','provider_failure','cancelled','resolved'))
);
-- RN-P2-S05-01: um ticket aberto por conversa
CREATE UNIQUE INDEX IF NOT EXISTS uq_ticket_aberto_por_conversa
  ON public.tickets(conversation_id)
  WHERE status NOT IN ('resolved','cancelled');
CREATE INDEX IF NOT EXISTS idx_tickets_clinic_status ON public.tickets(clinic_id, status);

-- ===== ticket_events (imutável) =====
CREATE TABLE IF NOT EXISTS public.ticket_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL,
  clinic_id uuid NOT NULL,
  ticket_id uuid NOT NULL REFERENCES public.tickets(id),
  event_type text NOT NULL CHECK (event_type IN ('created','offered','offer_expired','accepted','transferred','returned','escalated','sla_breached','after_hours_notice','resolved','reopened')),
  from_user_id uuid,
  to_user_id uuid,
  reason_code text,
  metadata_sanitized jsonb NOT NULL DEFAULT '{}',
  occurred_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ticket_events_ticket ON public.ticket_events(ticket_id, occurred_at);
-- Imutável: sem UPDATE/DELETE via RLS (só INSERT para o servidor/RPCs)

-- ===== ticket_sla_events =====
CREATE TABLE IF NOT EXISTS public.ticket_sla_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL,
  clinic_id uuid NOT NULL,
  ticket_id uuid NOT NULL REFERENCES public.tickets(id),
  metric text NOT NULL CHECK (metric IN ('accept','first_response')),
  due_at timestamptz NOT NULL,
  breached_at timestamptz,
  acknowledged_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (ticket_id, metric)
);

-- ===== RLS =====
ALTER TABLE public.ticket_queues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_closures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendant_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routing_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_sla_events ENABLE ROW LEVEL SECURITY;

-- Leitura: membros da clínica
CREATE POLICY rls_ticket_queues_select ON public.ticket_queues FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_business_hours_select ON public.business_hours FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_business_closures_select ON public.business_closures FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_user_shifts_select ON public.user_shifts FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_attendant_presence_select ON public.attendant_presence FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_routing_policies_select ON public.routing_policies FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_tickets_select ON public.tickets FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_ticket_events_select ON public.ticket_events FOR SELECT USING (public.is_clinic_member(clinic_id));
CREATE POLICY rls_ticket_sla_events_select ON public.ticket_sla_events FOR SELECT USING (public.is_clinic_member(clinic_id));

-- Escrita de config: owner/clinic_admin (via RPCs security definer; policies de escrita
-- direta só para owner/clinic_admin como defesa extra)
CREATE POLICY rls_ticket_queues_write ON public.ticket_queues FOR ALL USING (public.has_clinic_role(clinic_id, '{owner,clinic_admin}')) WITH CHECK (public.has_clinic_role(clinic_id, '{owner,clinic_admin}'));
CREATE POLICY rls_business_hours_write ON public.business_hours FOR ALL USING (public.has_clinic_role(clinic_id, '{owner,clinic_admin}')) WITH CHECK (public.has_clinic_role(clinic_id, '{owner,clinic_admin}'));
CREATE POLICY rls_business_closures_write ON public.business_closures FOR ALL USING (public.has_clinic_role(clinic_id, '{owner,clinic_admin}')) WITH CHECK (public.has_clinic_role(clinic_id, '{owner,clinic_admin}'));
CREATE POLICY rls_routing_policies_write ON public.routing_policies FOR ALL USING (public.has_clinic_role(clinic_id, '{owner,clinic_admin}')) WITH CHECK (public.has_clinic_role(clinic_id, '{owner,clinic_admin}'));
CREATE POLICY rls_user_shifts_write ON public.user_shifts FOR ALL USING (public.has_clinic_role(clinic_id, '{owner,clinic_admin,manager}')) WITH CHECK (public.has_clinic_role(clinic_id, '{owner,clinic_admin,manager}'));

-- Presença: o próprio usuário
CREATE POLICY rls_attendant_presence_write ON public.attendant_presence FOR ALL USING (user_id = auth.uid() AND public.is_clinic_member(clinic_id)) WITH CHECK (user_id = auth.uid() AND public.is_clinic_member(clinic_id));

-- tickets/ticket_events/ticket_sla_events: escrita só pelo servidor (service_role) e RPCs
-- (sem policy de escrita para authenticated; service_role bypassa RLS)

-- ===== RPCs de configuração (security definer) =====
CREATE OR REPLACE FUNCTION public.admin_save_queue(
  p_clinic uuid, p_team uuid, p_name text, p_purpose text, p_priority int DEFAULT 2, p_queue uuid DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid(); v_org uuid; v_id uuid;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'nao_autenticado' USING ERRCODE='42501'; END IF;
  IF NOT public.has_clinic_role(p_clinic, '{owner,clinic_admin}') THEN
    RAISE EXCEPTION 'papel_insuficiente' USING ERRCODE='42501';
  END IF;
  SELECT organization_id INTO v_org FROM public.clinics WHERE id = p_clinic;
  IF p_queue IS NULL THEN
    INSERT INTO public.ticket_queues (organization_id, clinic_id, team_id, name, purpose, priority_default)
    VALUES (v_org, p_clinic, p_team, p_name, p_purpose, p_priority)
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.ticket_queues SET team_id=p_team, name=p_name, purpose=p_purpose, priority_default=p_priority, updated_at=now()
    WHERE id = p_queue AND clinic_id = p_clinic RETURNING id INTO v_id;
  END IF;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_save_hours(
  p_clinic uuid, p_weekday int, p_opens time, p_closes time, p_team uuid DEFAULT NULL, p_timezone text DEFAULT 'America/Recife'
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT public.has_clinic_role(p_clinic, '{owner,clinic_admin}') THEN
    RAISE EXCEPTION 'papel_insuficiente' USING ERRCODE='42501';
  END IF;
  -- upsert manual (UNIQUE usa COALESCE(team_id) — ON CONFLICT inline não casa)
  UPDATE public.business_hours SET opens_at = p_opens, closes_at = p_closes, timezone = p_timezone, updated_at = now()
    WHERE clinic_id = p_clinic AND weekday = p_weekday
      AND COALESCE(team_id, '00000000-0000-0000-0000-000000000000'::uuid) = COALESCE(p_team, '00000000-0000-0000-0000-000000000000'::uuid)
    RETURNING id INTO v_id;
  IF v_id IS NULL THEN
    INSERT INTO public.business_hours (clinic_id, team_id, weekday, opens_at, closes_at, timezone)
    VALUES (p_clinic, p_team, p_weekday, p_opens, p_closes, p_timezone)
    RETURNING id INTO v_id;
  END IF;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_save_closure(p_clinic uuid, p_date date, p_reason text) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT public.has_clinic_role(p_clinic, '{owner,clinic_admin}') THEN
    RAISE EXCEPTION 'papel_insuficiente' USING ERRCODE='42501';
  END IF;
  INSERT INTO public.business_closures (clinic_id, date, reason) VALUES (p_clinic, p_date, p_reason)
  ON CONFLICT (clinic_id, date) DO UPDATE SET reason = EXCLUDED.reason
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_save_policy(
  p_clinic uuid, p_queue uuid, p_strategy text, p_accept_timeout int, p_max_reoffers int,
  p_sla_minutes int, p_backup_queue uuid DEFAULT NULL, p_escalation_role text DEFAULT 'manager',
  p_after_hours_text text DEFAULT NULL, p_fallback text DEFAULT 'fila_aberta', p_skills text[] DEFAULT '{}'
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid(); v_id uuid; v_next int;
BEGIN
  IF v_user IS NULL OR NOT public.has_clinic_role(p_clinic, '{owner,clinic_admin}') THEN
    RAISE EXCEPTION 'papel_insuficiente' USING ERRCODE='42501';
  END IF;
  -- rascunho novo: versão = última versão da fila + 1
  SELECT COALESCE(MAX(version),0)+1 INTO v_next FROM public.routing_policies WHERE queue_id = p_queue;
  INSERT INTO public.routing_policies
    (clinic_id, queue_id, strategy, skills, accept_timeout_seconds, max_reoffers, first_response_sla_minutes, backup_queue_id, escalation_role, after_hours_text, fallback_mode, version, status)
  VALUES
    (p_clinic, p_queue, p_strategy, p_skills, p_accept_timeout, p_max_reoffers, p_sla_minutes, p_backup_queue, p_escalation_role, p_after_hours_text, p_fallback, v_next, 'draft')
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_publish_policy(p_clinic uuid, p_policy uuid) RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid(); v_queue uuid; v_ver int; v_prev int;
BEGIN
  IF v_user IS NULL OR NOT public.has_clinic_role(p_clinic, '{owner,clinic_admin}') THEN
    RAISE EXCEPTION 'papel_insuficiente' USING ERRCODE='42501';
  END IF;
  SELECT queue_id, version INTO v_queue, v_ver FROM public.routing_policies WHERE id = p_policy AND clinic_id = p_clinic AND status = 'draft';
  IF v_queue IS NULL THEN RAISE EXCEPTION 'rascunho_invalido' USING ERRCODE='42501'; END IF;
  -- arquiva a publicada anterior
  UPDATE public.routing_policies SET status='archived', updated_at=now()
    WHERE queue_id = v_queue AND status='published'
    RETURNING version INTO v_prev;
  UPDATE public.routing_policies SET status='published', updated_at=now() WHERE id = p_policy;
  INSERT INTO public.config_audit_logs (organization_id, clinic_id, action, actor_id, details)
    SELECT organization_id, clinic_id, 'publish_routing_policy', v_user,
      jsonb_build_object('policy_id', p_policy, 'queue_id', v_queue, 'version', v_ver, 'previous_version', v_prev)
    FROM public.ticket_queues WHERE id = v_queue;
  RETURN v_ver;
END $$;

CREATE OR REPLACE FUNCTION public.admin_rollback_policy(p_clinic uuid, p_queue uuid) RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid(); v_prev int; v_id uuid;
BEGIN
  IF v_user IS NULL OR NOT public.has_clinic_role(p_clinic, '{owner,clinic_admin}') THEN
    RAISE EXCEPTION 'papel_insuficiente' USING ERRCODE='42501';
  END IF;
  -- publica a versão arquivada anterior mais recente
  SELECT id, version INTO v_id, v_prev FROM public.routing_policies
    WHERE queue_id = p_queue AND clinic_id = p_clinic AND status='archived'
    ORDER BY version DESC LIMIT 1;
  IF v_id IS NULL THEN RAISE EXCEPTION 'sem_versao_anterior' USING ERRCODE='42501'; END IF;
  UPDATE public.routing_policies SET status='archived', updated_at=now() WHERE queue_id = p_queue AND status='published';
  UPDATE public.routing_policies SET status='published', updated_at=now() WHERE id = v_id;
  INSERT INTO public.config_audit_logs (organization_id, clinic_id, action, actor_id, details)
    SELECT organization_id, clinic_id, 'rollback_routing_policy', v_user,
      jsonb_build_object('queue_id', p_queue, 'restored_version', v_prev)
    FROM public.ticket_queues WHERE id = p_queue;
  RETURN v_prev;
END $$;

CREATE OR REPLACE FUNCTION public.admin_list_policy_versions(p_clinic uuid, p_queue uuid)
RETURNS TABLE (id uuid, version int, status text, strategy text, created_at timestamptz)
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$
  SELECT id, version, status, strategy, created_at FROM public.routing_policies
  WHERE queue_id = p_queue AND clinic_id = p_clinic
  ORDER BY version DESC;
$$;

-- ===== RPCs de presença =====
CREATE OR REPLACE FUNCTION public.update_presence(p_clinic uuid, p_state text) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid();
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'nao_autenticado' USING ERRCODE='42501'; END IF;
  IF p_state NOT IN ('online','away','offline') THEN RAISE EXCEPTION 'estado_invalido' USING ERRCODE='22023'; END IF;
  IF NOT public.is_clinic_member(p_clinic) THEN RAISE EXCEPTION 'sem_vinculo' USING ERRCODE='42501'; END IF;
  INSERT INTO public.attendant_presence (user_id, clinic_id, state, last_seen_at, updated_at)
  VALUES (v_user, p_clinic, p_state, now(), now())
  ON CONFLICT (user_id, clinic_id) DO UPDATE SET state=EXCLUDED.state, last_seen_at=now(), updated_at=now();
END $$;

-- ===== RPCs de ticket (T01: criação/leitura; motor na T02) =====
CREATE OR REPLACE FUNCTION public.open_ticket(p_conversation uuid, p_reason text, p_priority int DEFAULT 2)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid(); v_conv RECORD; v_org uuid; v_clinic uuid; v_queue uuid; v_id uuid; v_aberto uuid;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'nao_autenticado' USING ERRCODE='42501'; END IF;
  IF p_reason NOT IN ('pedido_humano','risco','baixa_confianca','falha_automacao','regra_negocio','manual') THEN
    RAISE EXCEPTION 'motivo_invalido' USING ERRCODE='22023';
  END IF;
  SELECT c.organization_id, c.clinic_id INTO v_org, v_clinic FROM public.conversations c WHERE c.id = p_conversation;
  IF v_clinic IS NULL OR NOT public.is_clinic_member(v_clinic) THEN RAISE EXCEPTION 'sem_vinculo' USING ERRCODE='42501'; END IF;
  -- fila padrão da clínica (primeira ativa por prioridade)
  SELECT id INTO v_queue FROM public.ticket_queues WHERE clinic_id = v_clinic AND active ORDER BY priority_default LIMIT 1;
  IF v_queue IS NULL THEN RAISE EXCEPTION 'sem_fila_configurada' USING ERRCODE='22023'; END IF;
  -- RN-P2-S05-01: devolve o ticket aberto se existir
  SELECT id INTO v_aberto FROM public.tickets WHERE conversation_id = p_conversation AND status NOT IN ('resolved','cancelled');
  IF v_aberto IS NOT NULL THEN RETURN v_aberto; END IF;
  INSERT INTO public.tickets (organization_id, clinic_id, conversation_id, queue_id, status, priority, handoff_reason)
  VALUES (v_org, v_clinic, p_conversation, v_queue, 'new', COALESCE(p_priority,2), p_reason)
  RETURNING id INTO v_id;
  INSERT INTO public.ticket_events (organization_id, clinic_id, ticket_id, event_type, from_user_id, metadata_sanitized)
  VALUES (v_org, v_clinic, v_id, 'created', v_user, jsonb_build_object('reason', p_reason));
  RETURN v_id;
END $$;

-- Grants
GRANT EXECUTE ON FUNCTION public.has_clinic_role(uuid,text[]) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.admin_save_queue(uuid,uuid,text,text,int,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_save_hours(uuid,int,time,time,uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_save_closure(uuid,date,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_save_policy(uuid,uuid,text,int,int,int,uuid,text,text,text,text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_publish_policy(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_rollback_policy(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_list_policy_versions(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_presence(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.open_ticket(uuid,text,int) TO authenticated;
GRANT SELECT ON public.ticket_queues, public.business_hours, public.business_closures,
  public.user_shifts, public.attendant_presence, public.routing_policies,
  public.tickets, public.ticket_events, public.ticket_sla_events TO authenticated;
