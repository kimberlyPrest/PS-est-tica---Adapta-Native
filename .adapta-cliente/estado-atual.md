# Estado atual — Adapta Cliente

- task_id: P2-S03-T01
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S03-numeros-whatsapp-meta-zapi.md
- etapa: T01 IMPLEMENTADA (2026-10-19) — Skip v0.0.16 (f2ef528), QA verde; runner 18/18 (PGlite); migrations p2_s03_t01_canais + p2_s03_t01b_rpcs aplicadas no Supabase REAL (5 tabelas + 5 filas pgmq confirmadas em pgmq.pg_tables); AGUARDA aceite humano (capturas do cadastro)
- entregue_T01: 5 tabelas (channel_accounts com únicas (provider, external_account_id) e número ativo único por clínica + trigger org coerente; webhook_receipts imutável escrita só servidor; provider_message_status; outbound_requests idempotente; dead_letters) com RLS por papel; filas pgmq inbound_events/outbound_messages/dead_letter + 2 DLQ; RPCs admin_save_channel_account (segredos → Vault; segredo do webhook gerado e devolvido UMA única vez; RN-01), admin_set_channel_status, admin_test_channel (diagnóstico sanitizado sem token); tela /admin/canais (cadastro Meta/Z-API, teste, pausar/reativar/desativar, segredo único na tela) + rotas/menu; scripts/test_p2_s03_t01.mjs
- pendencias_da_task: aceite humano (capturas do cadastro — CA-P2-S03-01); pg_cron 10s fica para a T02 (com as funções consumidoras)
- pendencias_do_dono (arrastadas): toggles Auth (signup off + TOTP); capturas 3.b/3.c da P2-S01-T03; capturas dos 4 estados da P2-S02-T03; token Clínica Experts no Vault; decisão histórico Git
- fase_2: 4/28 concluídas + P2-S02 T01/T02/T03 e P2-S03-T01 implementadas (aguardam aceites/token)
- proxima_acao: P2-S03-T02 (adaptador e webhook da Meta + pg_cron + teste de rede real do canal)
- atualizado_em: 2026-10-19T20:10:00-03:00
