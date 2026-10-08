# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPECs P1-S01, P1-S02, P1-S03 e P1-S04 completas; P1-S05-T01 implementada (aguarda teste humano).
- Progresso da fase 1: 12/16 tasks concluídas (75%); P1-S05-T01 implementada, pendente de teste humano.
- P1-S01: CONCLUÍDA em 2026-10-03 (4 tasks). P1-S02: CONCLUÍDA em 2026-10-06. P1-S03: COMPLETA em 2026-10-08. P1-S04: COMPLETA em 2026-10-08 (Vault + secret_ref opaco; versionamento/teste sanitizado/audit log; prova de falhas com correlation_id e rollback).
- P1-S05: T01 implementada em 2026-10-08 — módulo server-side `clinic_experts_client.mjs` para a API Clínica Experts (GET /patients?phone=<E.164> e /patients/{uuid}, Bearer server-side): timeout por tentativa (AbortController), rate limiter em janela deslizante 120 req/min (a 121ª chamada é retida, não rejeitada), retry limitado com backoff exponencial (máx. 3) para 5xx/timeout/rede, 429 respeita retry-after e persistindo vira erro rate_limit_externo, erros tipados ErroOperacional com correlation_id, telemetria sanitizada (token nunca aparece), 404 tratado como zero resultados, múltiplos devolvidos por completo (classificação é da T02). Runner contra API simulada: 21/21.
- Próxima ação: teste humano de P1-S05-T01; depois P1-S05-T02 (busca + normalização + deduplicação + vínculo humano + cache TTL).
- Nenhuma credencial foi incluída (token de teste é sintético).
