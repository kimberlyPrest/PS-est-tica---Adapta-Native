# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPECs P1-S01, P1-S02, P1-S03, P1-S04 completas; P1-S05-T01 concluída em 2026-10-09.
- Progresso da fase 1: 13/16 tasks concluídas (81,25%).
- P1-S05: T01 CONCLUÍDA em 2026-10-09 — aceite humano "teste ok" (roteiro 11/11 no navegador). Módulo server-side clinic_experts_client.mjs: timeout por tentativa, rate limiter janela deslizante 120 req/min (121ª retida), retry/backoff máx. 3 para 5xx/timeout/rede, 429 respeita retry-after (persistente → rate_limit_externo), erros tipados ErroOperacional com correlation_id, telemetria sanitizada (token nunca aparece), 404 = zero resultados, múltiplos devolvidos por completo. Runner 21/21 (revalidado no fechamento).
- Próxima ação: P1-S05-T02 (busca + normalização E.164 + deduplicação + vínculo humano + cache TTL) — mediante pedido do Felipe. Depois P1-S05-T03 (fluxo demonstrável + matriz zero/um/múltiplos/falhas) fecha a fase 1.
- Nenhuma credencial foi incluída (token de teste é sintético).
