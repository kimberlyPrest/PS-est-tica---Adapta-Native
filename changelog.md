# Changelog — Adapta Cliente

## 2026-10-09 — P1-S05-T01 CONCLUÍDA
- Aceite humano: "teste ok" (Felipe, 2026-10-09, canal web) após roteiro roteiro-t01-cliente-v1-20261009.html (11 passos, módulo real embutido, API simulada local) validado 11/11 ✔ no navegador antes da entrega.
- Revalidação de fechamento com evidência fresca: runner scripts/test_s05_t01.mjs 21/21 (API simulada local); sha256 do módulo clinic_experts_client.mjs = 4b12c95a… (inalterado desde a implementação).
- Recortes provados: timeout por tentativa (AbortController) sem travar; rate limiter janela deslizante 120 req/min com 121ª chamada RETIDA (não rejeitada; espera não consome tentativa); retry/backoff máx. 3 para 5xx/timeout/rede; 429 respeita retry-after (persistente → rate_limit_externo); erros tipados ErroOperacional com correlation_id; telemetria sanitizada — varredura: 0 ocorrências do token em 127 telemetrias + 3 erros; 404 = zero resultados; múltiplos devolvidos por completo (classificação é da T02).
- Sem migration (módulo puro de rede). Edge Function search-expert-patient (T02) consumirá este módulo; token virá do Vault (SPEC P1-S04).
- Artefatos: artifacts/RELATORIO_P1_S05_T01_20261008.md · artifacts/roteiro-t01-cliente-v1-20261009.html · scripts/clinic_experts_client.mjs · scripts/test_s05_t01.mjs
- Fase 1: 13/16 (81,25%). Próxima: P1-S05-T02 (busca + normalização E.164 + deduplicação + vínculo humano + cache TTL), mediante pedido.
