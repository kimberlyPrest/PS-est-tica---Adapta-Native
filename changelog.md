# Changelog

## 2026-10-20 — P2-S03-T02 IMPLEMENTADA (v0.0.20; aguarda credenciais Meta no Vault para a troca real)

- Adaptador Meta `supabase/functions/_shared/providers/meta.ts`: assinatura X-Hub-Signature-256 HMAC-SHA256 com comparação em tempo constante; verificação GET (hub.mode/hub.verify_token/hub.challenge → 200 challenge | 403); mapeamento de mensagens (wamid, E.164, nome do contato, texto, media_id, tipos suportados/não suportados) e situações (sent/delivered/read/failed + error_code, external_event_id `wamid:status`); lote com múltiplos itens; stale >24h; corpos de envio texto e modelo (Graph API, versão configurável); timeout 10s sem retry interno (a fila controla).
- Edge Function `webhook-whatsapp-meta` (rota pública sem JWT): GET verifica verify_token contra os segredos no Vault das contas Meta ativas; POST valida assinatura → 401 inválida (recibo rejected_signature) / 200 válida (mesmo duplicata — RN-P2-S03-02/03); recibos idempotentes por item (única (provider, external_event_id)); rejected_unmapped (número sem conta), rejected_stale (>24h), ignored (tipo não suportado); situações → provider_message_status (upsert); mensagens → fila inbound_events (envelope do contrato comum, sem conteúdo).
- Edge Function `enqueue-outbound-message` (JWT de usuário): conta ativa obrigatória (RN-P2-S03-07), destino normalizado E.164 server-side, janela 24h — texto livre só com entrada <24h, fora → outbound_request `blocked` com `janela_fechada` (RN-P2-S03-06, CA-P2-S03-07); idempotency_key = hash(canal+destino+kind+conteúdo+minuto); enfileira em outbound_messages.
- Edge Function `send-whatsapp-message` (consumidor, header x-internal-job): lote 10, lê outbound_request pelo ref_id, token do Vault, envia pelo adaptador, grava provider_message_id + status sent + provider_message_status; falha → reenfileira até 5 tentativas em 30min, depois dead_letters + fila dead_letter.
- Edge Function `process-inbound-event` (consumidor): confirma processamento do recibo accepted e arquiva da fila (P2-S04 completa a conversa).
- pg_cron ativo no Supabase real: jobs `p2-consumidor-outbound` e `p2-consumidor-inbound` a cada 10s via net.http_post. INTERNAL_JOB_SECRET configurado como Edge Function secret no Skip (DÚVIDA registrada no relatório: o contrato pede o segredo no header do cron, mas o Vault SQL não aceita INSERT do postgres — emenda candidata para a consultora definir o mecanismo).
- Runner `scripts/test_p2_s03_t02.mjs` 48/48 (Node + strip-types, fetch stub com gancho de cenário): assinatura (4 casos), verificação GET (3), mapeamento (texto/mídia/raro/4 situações/lote 3/stale/não mapeado), corpos de envio, envio ok/erro com sanitização, decisão de recibo, janela 24h, envelope de fila sem conteúdo, telemetria sem corpo/token.
- Skip v0.0.20 (831653d) QA verde. Relatório: `05_entregas/RELATORIO_P2_S03_T02_20261020.md`. Pendências para fechar: credenciais Meta no Vault (via /admin/canais), webhook no painel da Meta, troca real de mensagem.

## 2026-10-19 — P2-S03-T01 IMPLEMENTADA (v0.0.16; aguarda aceite)

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