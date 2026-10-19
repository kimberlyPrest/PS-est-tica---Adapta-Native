# Changelog — Adapta Cliente

## 2026-10-19 — P2-S03-T01 IMPLEMENTADA (v0.0.16; aceite humano pendente)
- Migration p2_s03_t01_canais APLICADA NO SUPABASE REAL: channel_accounts (únicas (provider, external_account_id) e phone_e164 único entre active/paused/disconnected — um número ativo pertence a uma só clínica; trigger organization_id coerente com a clínica), webhook_receipts (imutável, única (provider, external_event_id), escrita só servidor — sem policy de INSERT para authenticated), provider_message_status (imutável), outbound_requests (idempotency_key única), dead_letters; RLS por papel em todas (recibos/mortas só owner/clinic_admin). Filas pgmq criadas no banco real (5: inbound_events, outbound_messages, dead_letter + 2 DLQ) — confirmadas em pgmq.pg_tables.
- Migration p2_s03_t01b_rpcs APLICADA NO SUPABASE REAL: admin_save_channel_account (owner/clinic_admin; normaliza E.164; recusa número ativo em outra clínica e ID externo global duplicado; token → Vault via admin_save_integration_secret; segredo do webhook gerado pelo sistema, guardado no Vault e devolvido UMA única vez), admin_set_channel_status (pausar/reativar/desativar), admin_test_channel (diagnóstico sanitizado LOCAL sem token na resposta; teste de rede real fica na Edge Function da T02/T03). Grants só authenticated.
- Tela /admin/canais (AdminCanais.tsx): lista com situação/última entrada/última saída/erro; cadastro Meta (phone_number_id, WABA, token, app secret) e Z-API (instanceId, token, Client-Token); teste de conexão; pausar/reativar/desativar; segredo do webhook mostrado UMA única vez com aviso de cópia. Rota com RequireRole owner/clinic_admin + AAL2; item "Canais WhatsApp" no menu.
- Runner 18/18 (scripts/test_p2_s03_t01.mjs, PGlite): 5 tabelas; segredo devolvido uma vez e nunca mais; upsert sem duplicar; RN-01; unicidade global do ID externo; sales não cria (42501); RLS (sales 0, owner 1); status via RPC; vault:<uuid>; sem token no diagnóstico; org divergente recusada; replay idempotente.
- Lições: FOREACH IN ARRAY não existe no PGlite (usar FOR x IN SELECT y FROM unnest(...) AS y); template literal JS come \+ (regex SQL com [+]); public.vault.secrets = cross-database (usar vault.secrets); PGlite sem pgcrypto → fallback public.gen_random_bytes; grants SELECT antes de SET ROLE no teste RLS.
- Skip v0.0.16 (f2ef528) QA verde. Próxima: P2-S03-T02 (webhook Meta + pg_cron + teste de rede real).

## 2026-10-19 — P2-S02-T03 IMPLEMENTADA (v0.0.15; aceite pendente)
- Tela /pacientes/identificar (4 resultados + erros com correlation_id copiável + Confirmar vínculo); cartão Clínica Experts em /admin/conexoes (Testar conexão + Trocar token); emenda link_expert_patient aplicada no Supabase REAL (sales/reception/post_sales criam; unlink_expert_patient nova só owner/clinic_admin; manual_provavel 0.7). Testes tela 8/8 + suíte 20/20 + emenda 12/12.

## 2026-10-19 — P2-S02-T02 (v0.0.13) e T01 (v0.0.12) IMPLEMENTADAS
- Busca em duas etapas (b: últimos 8 + filtro DDD → provavel), classificação um/multiplos/provavel/zero, Edge Function v2 contrato SPEC, matriz 18/18 com carga 200; cliente real Experts (UA próprio, 4 formatos de erro, rateBudget 90/min), matriz 23/23. Testes com dado real aguardam token no Vault.

## 2026-10-18 — TELA DE SEGUNDO FATOR (v0.0.11) · P2-S01-T03/T04 (v0.0.8–v0.0.10) — SPEC P2-S01 COMPLETA

## 2026-10-14 — P2-S01-T01/T02 CONCLUÍDAS · FASE 2 LIBERADA (7 SPECs, 28 tasks)

## 2026-10-09 — FASE 1 COMPLETA (16/16)