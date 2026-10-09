# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPECs P1-S01..P1-S04 completas; P1-S05: T01 e T02 concluídas em 2026-10-09.
- Progresso da fase 1: 14/16 tasks concluídas (87,5%).
- P1-S05-T02 (2026-10-09): CONCLUÍDA — aceite humano "teste ok" (roteiro 8/8 contra o Supabase real: login owner, normalização E.164, 22023, 503 api_nao_configurada com correlation_id, 400 entrada, 401 anon, invalidação idempotente, RLS anon 0). Migration p1_s05_t02_search_cache (normalize_e164, external_patient_links com vínculo só humano + dedup, expert_patients_cache com TTL/invalidação, RPCs invalidate/link) + Edge Function search-expert-patient v1 (verify_jwt: JWT→normaliza→permissão→cache TTL→API via módulo T01 com token do Vault→classifica zero/um/múltiplos sem escolher múltiplos→grava cache 1h). Runner 22/22; revalidação viva no fechamento (banco + função).
- Pendências: EXPERT_API_BASE_URL + token real da API (via /admin→Vault) quando Felipe fornecer — não bloqueia a última task.
- Próxima ação: P1-S05-T03 (fluxo demonstrável + matriz zero/um/múltiplos/falhas) — ÚLTIMA da fase 1 — mediante pedido do Felipe.
- Nenhuma credencial foi incluída (tokens nos testes são sintéticos).
