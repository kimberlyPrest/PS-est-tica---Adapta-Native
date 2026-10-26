// Runner P2-S06-T01 — Ambiente de agentes + guardião (PGlite)
// Uma prova por regra do guardião (10 regras) + falha fechada + RLS.
const { PGlite } = require('@electric-sql/pglite');
const fs = require('fs');
const path = require('path');

const REPO = '/home/ethos/.assistant/workspace/repos/ps-adapta';
const MIG = fs.readFileSync(path.join(REPO, 'supabase/migrations/20261026210000_p2_s06_t01_agentes_guardiao.sql'), 'utf8');

let pass = 0, fail = 0;
const failures = [];
function check(name, cond, extra) {
  if (cond) { pass++; console.log(`  PASS ${name}`); }
  else { fail++; failures.push(name); console.log(`  FAIL ${name}${extra ? ' — ' + extra : ''}`); }
}

// evaluateGuard — função pura (espelho da lógica que vai para a Edge/SQL).
// ctx: { automation_paused, flag_auto_resposta, contato_recusou_promo, acao_e_atendimento,
//        em_expediente, rota_auto_reply_allowed, confidence, confianca_min,
//        texto_contato, item_aprovado, resposta_candidata, custo_esgotado, chamadas_esgotadas }
// Regras em ordem; a primeira que casar decide. Falha = require_human.
const TERMOS_SENSIVEIS = ['preço','preco','desconto','sintoma','dor','foto','alergia','reação','reacao','reclama','reclamação','reclamacao'];
function evaluateGuard(a, ctx) {
  try {
    if (ctx.automation_paused) return { effect: 'deny', reason: 'transbordo_ativo' };
    if (!ctx.flag_auto_resposta) return { effect: 'require_human', reason: 'auto_resposta_desligada' };
    if (ctx.contato_recusou_promo && !ctx.acao_e_atendimento) return { effect: 'deny', reason: 'recusa_do_contato' };
    if (!ctx.em_expediente) return { effect: 'require_human', reason: 'fora_do_horario' };
    if (!ctx.rota_auto_reply_allowed) return { effect: 'require_human', reason: 'intencao_exige_humano' };
    if (typeof ctx.confidence !== 'number' || ctx.confidence < ctx.confianca_min) return { effect: 'require_human', reason: 'baixa_confianca' };
    const texto = (ctx.texto_contato || '').toLowerCase();
    if (TERMOS_SENSIVEIS.some((t) => texto.includes(t))) return { effect: 'require_human', reason: 'tema_sensivel' };
    if (!ctx.item_aprovado) return { effect: 'require_human', reason: 'sem_conteudo_aprovado' };
    if (ctx.resposta_candidata !== ctx.item_aprovado.answer) return { effect: 'deny', reason: 'texto_nao_aprovado' };
    if (ctx.custo_esgotado || ctx.chamadas_esgotadas) return { effect: 'require_human', reason: 'orcamento_esgotado' };
    return { effect: 'allow', reason: null };
  } catch {
    return { effect: 'require_human', reason: 'falha_avaliacao' };
  }
}

const BASE_OK = {
  automation_paused: false, flag_auto_resposta: true, contato_recusou_promo: false, acao_e_atendimento: false,
  em_expediente: true, rota_auto_reply_allowed: true, confidence: 0.95, confianca_min: 0.85,
  texto_contato: 'qual o endereço de vocês?', item_aprovado: { answer: 'Estamos na Rua Exemplo, 123 — Recife/PE.' },
  resposta_candidata: 'Estamos na Rua Exemplo, 123 — Recife/PE.', custo_esgotado: false, chamadas_esgotadas: false,
};

async function main() {
  const db = new PGlite();
  await db.exec(`CREATE SCHEMA IF NOT EXISTS auth;
    CREATE TABLE auth.users (id uuid primary key default gen_random_uuid(), email text);
    CREATE ROLE anon NOLOGIN; CREATE ROLE authenticated NOLOGIN; CREATE ROLE service_role NOLOGIN;
    GRANT anon TO authenticated;
    CREATE TABLE public._session (user_id uuid); GRANT ALL ON public._session TO authenticated;
    CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql AS 'SELECT user_id FROM public._session LIMIT 1';`);
  await db.exec(`
    CREATE TABLE organizations (id uuid primary key default gen_random_uuid(), name text);
    CREATE TABLE clinics (id uuid primary key default gen_random_uuid(), organization_id uuid references organizations(id), name text, timezone text default 'America/Recife');
    CREATE TABLE memberships (id uuid primary key default gen_random_uuid(), organization_id uuid, clinic_id uuid, user_id uuid references auth.users(id), role text, active boolean default true); GRANT SELECT ON memberships TO authenticated;
    CREATE TABLE integration_connections (id uuid primary key default gen_random_uuid(), organization_id uuid, clinic_id uuid, provider text, connection_key text, secret_ref text, health_status text default 'not_configured', config_sanitized jsonb default '{}', last_tested_at timestamptz, created_at timestamptz default now(), updated_at timestamptz default now());
    CREATE TABLE config_audit_logs (id uuid primary key default gen_random_uuid(), organization_id uuid, clinic_id uuid, connection_id uuid, action text, actor_id uuid, details jsonb default '{}', created_at timestamptz default now());
    INSERT INTO organizations (id) VALUES ('a0000000-0000-0000-0000-000000000001');
    INSERT INTO clinics (id, organization_id, name) VALUES ('c0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','PS Recife'), ('c0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000001','PS Caruaru');
    INSERT INTO auth.users (id, email) VALUES
      ('11111111-1111-1111-1111-111111111111','owner@teste.local'),
      ('22222222-2222-2222-2222-222222222222','recep@teste.local'),
      ('33333333-3333-3333-3333-333333333333','fora@teste.local');
    INSERT INTO memberships (organization_id, clinic_id, user_id, role) VALUES
      ('a0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111','owner'),
      ('a0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','reception');
  `);
  await db.exec(`CREATE FUNCTION is_clinic_member(p_clinic uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS
    'SELECT EXISTS (SELECT 1 FROM memberships m WHERE m.clinic_id=p_clinic AND m.user_id=auth.uid() AND m.active)'`);
  await db.exec(`CREATE FUNCTION is_org_member(p_org uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS
    'SELECT EXISTS (SELECT 1 FROM memberships m WHERE m.organization_id=p_org AND m.user_id=auth.uid() AND m.active)'`);
  await db.exec(`CREATE FUNCTION has_clinic_role(p_clinic uuid, p_roles text[]) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS
    'SELECT EXISTS (SELECT 1 FROM memberships m WHERE m.clinic_id=p_clinic AND m.user_id=auth.uid() AND m.active AND m.role = ANY(p_roles))'`);

  let erro = null;
  try { await db.exec(MIG); } catch (e) { erro = e.message; }
  check('migration instala sem erro', !erro, erro);

  // Catálogo e regras globais carregados
  await db.exec('RESET ROLE;');
  const defs = await db.query(`SELECT count(*)::int AS n FROM agent_definitions`);
  check('catálogo AG-01..AG-14 carregado (13 defs)', defs.rows[0].n === 13, `n=${defs.rows[0].n}`);
  const regras = await db.query(`SELECT rule_key, effect, reason_code, priority FROM policy_rules WHERE scope='global' ORDER BY priority`);
  check('10 regras globais do guardião carregadas', regras.rows.length === 10, `n=${regras.rows.length}`);
  check('regra 1 = transbordo_ativo (deny)', regras.rows[0].rule_key === 'transbordo_ativo' && regras.rows[0].effect === 'deny');

  // ===== Provas do guardião (uma por regra, em ordem) =====
  console.log('\n--- Guardião: uma prova por regra ---');
  let g = evaluateGuard('auto_reply', { ...BASE_OK, automation_paused: true });
  check('R1 transbordo_ativo → deny', g.effect === 'deny' && g.reason === 'transbordo_ativo', JSON.stringify(g));
  g = evaluateGuard('auto_reply', { ...BASE_OK, flag_auto_resposta: false });
  check('R2 auto_resposta_desligada → require_human', g.effect === 'require_human' && g.reason === 'auto_resposta_desligada', JSON.stringify(g));
  g = evaluateGuard('auto_reply', { ...BASE_OK, contato_recusou_promo: true });
  check('R3 recusa_do_contato → deny', g.effect === 'deny' && g.reason === 'recusa_do_contato', JSON.stringify(g));
  g = evaluateGuard('auto_reply', { ...BASE_OK, contato_recusou_promo: true, acao_e_atendimento: true });
  check('R3a recusa mas ação é atendimento → passa da R3', g.reason !== 'recusa_do_contato', JSON.stringify(g));
  g = evaluateGuard('auto_reply', { ...BASE_OK, em_expediente: false });
  check('R4 fora_do_horario → require_human', g.effect === 'require_human' && g.reason === 'fora_do_horario', JSON.stringify(g));
  g = evaluateGuard('auto_reply', { ...BASE_OK, rota_auto_reply_allowed: false });
  check('R5 intencao_exige_humano → require_human', g.effect === 'require_human' && g.reason === 'intencao_exige_humano', JSON.stringify(g));
  g = evaluateGuard('auto_reply', { ...BASE_OK, confidence: 0.80 });
  check('R6 baixa_confianca → require_human', g.effect === 'require_human' && g.reason === 'baixa_confianca', JSON.stringify(g));
  g = evaluateGuard('auto_reply', { ...BASE_OK, texto_contato: 'qual é o preço do procedimento?' });
  check('R7 tema_sensivel (preço) → require_human', g.effect === 'require_human' && g.reason === 'tema_sensivel', JSON.stringify(g));
  g = evaluateGuard('auto_reply', { ...BASE_OK, texto_contato: 'estou com dor depois do procedimento' });
  check('R7b tema_sensivel (dor) → require_human', g.reason === 'tema_sensivel', JSON.stringify(g));
  g = evaluateGuard('auto_reply', { ...BASE_OK, item_aprovado: null });
  check('R8 sem_conteudo_aprovado → require_human', g.effect === 'require_human' && g.reason === 'sem_conteudo_aprovado', JSON.stringify(g));
  g = evaluateGuard('auto_reply', { ...BASE_OK, resposta_candidata: 'Texto diferente do aprovado!' });
  check('R9 texto_nao_aprovado → deny', g.effect === 'deny' && g.reason === 'texto_nao_aprovado', JSON.stringify(g));
  g = evaluateGuard('auto_reply', { ...BASE_OK, custo_esgotado: true });
  check('R10 orcamento_esgotado (custo) → require_human', g.effect === 'require_human' && g.reason === 'orcamento_esgotado', JSON.stringify(g));
  g = evaluateGuard('auto_reply', { ...BASE_OK, chamadas_esgotadas: true });
  check('R10b orcamento_esgotado (chamadas) → require_human', g.reason === 'orcamento_esgotado', JSON.stringify(g));
  g = evaluateGuard('auto_reply', BASE_OK);
  check('caminho feliz → allow', g.effect === 'allow' && g.reason === null, JSON.stringify(g));

  // Falha fechada: entrada quebrada = require_human
  g = evaluateGuard('auto_reply', { ...BASE_OK, confidence: undefined });
  check('falha fechada: dado faltando → require_human', g.effect === 'require_human', JSON.stringify(g));
