// Runner P2-S05-T02 — Motor de distribuição (PGlite)
const { PGlite } = require('@electric-sql/pglite');
const fs = require('fs');
const path = require('path');

const REPO = '/home/ethos/.assistant/workspace/repos/ps-adapta';
const MIG_T01 = fs.readFileSync(path.join(REPO, 'supabase/migrations/20261026170000_p2_s05_t01_tickets_config.sql'), 'utf8');
const MIG_T02 = fs.readFileSync(path.join(REPO, 'supabase/migrations/20261026182000_p2_s05_t02_motor_rpc.sql'), 'utf8');

let pass = 0, fail = 0;
const failures = [];
function check(name, cond, extra) {
  if (cond) { pass++; console.log(`  PASS ${name}`); }
  else { fail++; failures.push(name); console.log(`  FAIL ${name}${extra ? ' — ' + extra : ''}`); }
}

async function main() {
  const db = new PGlite();
  await db.exec(`CREATE SCHEMA IF NOT EXISTS auth;
    CREATE TABLE auth.users (id uuid primary key default gen_random_uuid(), email text);
    CREATE ROLE anon NOLOGIN; CREATE ROLE authenticated NOLOGIN; CREATE ROLE service_role NOLOGIN;
    GRANT anon TO authenticated;
    CREATE TABLE public._session (user_id uuid);
    CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql AS 'SELECT user_id FROM public._session LIMIT 1';`);

  await db.exec(`
    CREATE TABLE organizations (id uuid primary key default gen_random_uuid(), name text);
    CREATE TABLE clinics (id uuid primary key default gen_random_uuid(), organization_id uuid references organizations(id), name text, timezone text default 'America/Recife');
    CREATE TABLE profiles (id uuid primary key references auth.users(id), email text);
    CREATE TABLE memberships (id uuid primary key default gen_random_uuid(), organization_id uuid, clinic_id uuid, user_id uuid references auth.users(id), role text, active boolean default true);
    CREATE TABLE teams (id uuid primary key default gen_random_uuid(), clinic_id uuid, name text, queue_type text);
    CREATE TABLE team_members (id uuid primary key default gen_random_uuid(), team_id uuid, user_id uuid, capacity int default 1, active boolean default true);
    CREATE TABLE conversations (id uuid primary key default gen_random_uuid(), organization_id uuid, clinic_id uuid, contact_id uuid, channel_account_id uuid, status text, identification text, unread_count int default 0, automation_paused boolean default false);
    CREATE TABLE config_audit_logs (id uuid primary key default gen_random_uuid(), organization_id uuid, clinic_id uuid, connection_id uuid, action text, actor_id uuid, details jsonb default '{}', created_at timestamptz default now());
    INSERT INTO organizations (id) VALUES ('a0000000-0000-0000-0000-000000000001');
    INSERT INTO clinics (id, organization_id, name) VALUES ('c0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','PS Recife'), ('c0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000001','PS Caruaru');
    INSERT INTO auth.users (id, email) VALUES
      ('11111111-1111-1111-1111-111111111111','owner@teste.local'),
      ('22222222-2222-2222-2222-222222222222','atendente1@teste.local'),
      ('44444444-4444-4444-4444-444444444444','atendente2@teste.local'),
      ('55555555-5555-5555-5555-555555555555','gestor@teste.local'),
      ('33333333-3333-3333-3333-333333333333','fora@teste.local');
    INSERT INTO memberships (organization_id, clinic_id, user_id, role) VALUES
      ('a0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111','owner'),
      ('a0000000-0000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','reception'),
      ('a0000000-0000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','44444444-4444-4444-4444-444444444444','reception'),
      ('a0000000-0000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','55555555-5555-5555-5555-555555555555','manager'),
      ('a0000000-0000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000002','33333333-3333-3333-3333-333333333333','reception');
    INSERT INTO teams (id, clinic_id, name) VALUES ('99000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','Recepção Recife');
    INSERT INTO team_members (team_id, user_id) VALUES
      ('99000000-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222'),
      ('99000000-0000-0000-0000-000000000001','44444444-4444-4444-4444-444444444444');
    INSERT INTO conversations (id, organization_id, clinic_id) VALUES ('88000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001');
  `);
  await db.exec(`CREATE FUNCTION is_clinic_member(p_clinic uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS
    'SELECT EXISTS (SELECT 1 FROM memberships m WHERE m.clinic_id=p_clinic AND m.user_id=auth.uid() AND m.active)'`);

  let erro = null;
  try { await db.exec(MIG_T01); await db.exec(MIG_T02); } catch (e) { erro = e.message; }
  check('migrations T01+T02 instalam sem erro', !erro, erro);

  await db.exec(`DELETE FROM public._session; INSERT INTO public._session VALUES ('11111111-1111-1111-1111-111111111111');`);
  const fila = await db.query(`SELECT admin_save_queue('c0000000-0000-0000-0000-000000000001','99000000-0000-0000-0000-000000000001','Atendimento','recepcao') AS id`);
  const filaId = fila.rows[0].id;
  const pol = await db.query(`SELECT admin_save_policy('c0000000-0000-0000-0000-000000000001','${filaId}','least_load',120,2,10) AS id`);
  await db.query(`SELECT admin_publish_policy('c0000000-0000-0000-0000-000000000001','${pol.rows[0].id}')`);
  await db.query(`SELECT admin_save_hours('c0000000-0000-0000-0000-000000000001',1,'08:00','23:59')`);
  await db.exec(`INSERT INTO attendant_presence (user_id, clinic_id, state) VALUES
    ('22222222-2222-2222-2222-222222222222','c0000000-0000-0000-0000-000000000001','online'),
    ('44444444-4444-4444-4444-444444444444','c0000000-0000-0000-0000-000000000001','online')`);

  await db.exec(`DELETE FROM public._session; INSERT INTO public._session VALUES ('22222222-2222-2222-2222-222222222222');`);
  const t1 = await db.query(`SELECT open_ticket('88000000-0000-0000-0000-000000000001','pedido_humano') AS id`);
  const ticketId = t1.rows[0].id;
  check('CA-01: ticket criado', !!ticketId);

  await db.exec('RESET ROLE;');
  const eleg = await db.query(`SELECT * FROM fila_elegiveis('${filaId}')`);
  check('elegíveis: 2 atendentes da equipe', eleg.rows.length === 2, `n=${eleg.rows.length}`);
  const fora = eleg.rows.filter(r => r.user_id === '33333333-3333-3333-3333-333333333333');
  check('RN-04: atendente de outra clínica nunca elegível', fora.length === 0);
  // owner na equipe também é elegível (fix T02 v2 — clínicas pequenas, dono atende)
  await db.exec(`DELETE FROM public._session; INSERT INTO public._session VALUES ('11111111-1111-1111-1111-111111111111');`);
  await db.exec(`INSERT INTO team_members (team_id, user_id) VALUES ('99000000-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111');`);
  await db.exec(`INSERT INTO attendant_presence (user_id, clinic_id, state) VALUES ('11111111-1111-1111-1111-111111111111','c0000000-0000-0000-0000-000000000001','online');`);
  await db.exec('RESET ROLE;');
  const eleg3 = await db.query(`SELECT * FROM fila_elegiveis('${filaId}')`);
  check('owner na equipe também é elegível (v2)', eleg3.rows.some(r => r.user_id === '11111111-1111-1111-1111-111111111111'), `n=${eleg3.rows.length}`);

  await db.query(`UPDATE tickets SET status='offered', offered_to='22222222-2222-2222-2222-222222222222',
    offer_expires_at=now() + interval '120 seconds', version=version+1 WHERE id='${ticketId}'`);
  await db.query(`INSERT INTO ticket_events (organization_id, clinic_id, ticket_id, event_type, to_user_id)
    SELECT organization_id, clinic_id, id, 'offered', '22222222-2222-2222-2222-222222222222' FROM tickets WHERE id='${ticketId}'`);

  const ver = (await db.query(`SELECT version FROM tickets WHERE id='${ticketId}'`)).rows[0].version;
  await db.exec(`DELETE FROM public._session; INSERT INTO public._session VALUES ('22222222-2222-2222-2222-222222222222');`);
  const a1 = await db.query(`SELECT accept_ticket('${ticketId}', ${ver}) AS r`);
  check('CA-02: primeiro aceite vence', a1.rows[0].r.ok === true, JSON.stringify(a1.rows[0].r));
  await db.exec(`DELETE FROM public._session; INSERT INTO public._session VALUES ('44444444-4444-4444-4444-444444444444');`);
  const a2 = await db.query(`SELECT accept_ticket('${ticketId}', ${ver}) AS r`).catch(e => ({ rows: [{ r: { ok: false, code: e.message } }] }));
  const r2 = typeof a2.rows[0].r === 'string' ? JSON.parse(a2.rows[0].r) : a2.rows[0].r;
  const conflitou = r2.ok === false || (r2.code || '').includes('conflito') || (r2.code || '').includes('oferta_de_outro') || (r2.code || '').includes('ticket_inexistente');
  check('CA-02: segundo aceite recebe conflito', conflitou, JSON.stringify(r2));

  await db.exec(`DELETE FROM public._session; INSERT INTO public._session VALUES ('33333333-3333-3333-3333-333333333333');`);
  const neg = await db.query(`SELECT accept_ticket('${ticketId}', 99)`).catch(e => ({ err: e.message }));
  check('RN-04: aceite de fora da clínica falha', !!neg.err, JSON.stringify(neg).slice(0, 120));

  await db.exec(`DELETE FROM public._session; INSERT INTO public._session VALUES ('22222222-2222-2222-2222-222222222222');`);
