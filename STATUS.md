# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPECs P1-S01..P1-S04 completas; P1-S05: T01 concluída, T02 implementada (aguarda teste humano).
- Progresso da fase 1: 13/16 concluídas (81,25%); T02 implementada, pendente de teste humano.
- P1-S05-T02 (2026-10-09): migration p1_s05_t02_search_cache — normalize_e164 (server-side, RN-P1-S05-01), external_patient_links (vínculo só humano match_method='manual', dedup por 2 índices únicos, rebind sem duplicar), expert_patients_cache (TTL expires_at + invalidated + correlation_id, result_class zero/um/multiplos/erro), RPCs invalidate_expert_cache (idempotente) e link_expert_patient (só owner/clinic_admin), EXECUTE só authenticated. Edge Function search-expert-patient v1 (verify_jwt): JWT→RPC normaliza→membro da org (RLS)→cache TTL→API via módulo T01 (token do Vault server-side)→classifica zero/um/múltiplos (nunca escolhe múltiplos)→grava cache TTL 1h; erros sanitizados com correlation_id. Runner 22/22; prova ao vivo: owner 503 sanitizado (api_nao_configurada — correto), anon 401.
- Pendências: EXPERT_API_BASE_URL + token real da API (via /admin→Vault) quando Felipe fornecer.
- Próxima ação: teste humano de P1-S05-T02; depois P1-S05-T03 fecha a fase 1.
- Nenhuma credencial foi incluída (tokens nos testes são sintéticos).
