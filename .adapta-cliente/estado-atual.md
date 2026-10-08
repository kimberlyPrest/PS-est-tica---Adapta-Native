# Estado atual — Adapta Cliente

- task_id: P1-S05-T01
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P1-S05-clinica-experts-paciente.md
- etapa: implementada (aguarda teste humano)
- autorizacao_implementacao: confirmada — 2026-10-08, "implementar a proxima task" (Felipe, owner)
- teste_humano: pendente — revisar o relatório artifacts/RELATORIO_P1_S05_T01_20261008.md (módulo scripts/clinic_experts_client.mjs)
- verificacao_automatica: passou — runner scripts/test_s05_t01.mjs 21/21 contra API simulada local (zero/um/múltiplos sem classificar sozinho; 401/422/timeout/429/5xx com erros tipados + correlation_id; 429 transitório recupera, persistente vira rate_limit_externo; limiter retém a 121ª chamada sem estourar 120/min; token ausente de toda telemetria/erro)
- ultima_acao: módulo client server-side implementado (timeout, rate limiter janela 120/min, retry/backoff, telemetria sanitizada, erros tipados); relatório em artifacts/
- proxima_acao: teste humano do Felipe conclui a task; depois P1-S05-T02 (busca + normalização E.164 + deduplicação + vínculo humano + cache TTL)
- atualizado_em: 2026-10-08T18:20:00-03:00
