# Estado atual — Adapta Cliente

- task_id: P1-S05-T02
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P1-S05-clinica-experts-paciente.md
- etapa: implementada (aguarda teste humano)
- autorizacao_implementacao: confirmada — 2026-10-09, "implementar a proxima task" (Felipe, owner)
- verificacao_automatica: passou — runner scripts/test_s05_t02.js 22/22 (PGlite, instalação limpa T01→T02: normalização E.164 6 provas, TTL/invalidação 4, vínculo humano/dedup 5, permissões/isolamento 5, replay idempotente)
- prova ao vivo: login owner OK; Edge Function autenticada → 503 api_nao_configurada + correlation_id (correto — EXPERT_API_BASE_URL ainda não configurada, sem falso sucesso); sem JWT → 401 (verify_jwt). Banco: 2 tabelas novas com RLS (4 policies), 6 índices, 3 RPCs, normalize_e164 funcionando
- ultima_acao: migration p1_s05_t02_search_cache aplicada no Supabase + Edge Function search-expert-patient v1 deployada (verify_jwt)
- pendencias: EXPERT_API_BASE_URL (env) + token real da API via /admin→Vault (quando Felipe fornecer; até lá função responde 503 sanitizado)
- proxima_acao: teste humano do Felipe conclui a task; depois P1-S05-T03 (fluxo demonstrável + matriz zero/um/múltiplos/falhas) fecha a fase 1
- atualizado_em: 2026-10-09T01:05:00-03:00
