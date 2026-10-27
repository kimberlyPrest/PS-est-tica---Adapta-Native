# Status do pacote do cliente

- Projeto: PS Estética.
- Fase 1: COMPLETA (16/16, 100%) — todas as SPECs com aceite humano.
- Fase 2 (7 SPECs / 28 tasks): 15/28 concluídas (54%) + T01 da P2-S07 implementada com prova real, aguardando aceite.
  - P2-S01: T01–T04 concluídas (2026-10-14/18).
  - P2-S02: T01–T03 implementadas (2026-10-19) — token Experts recusado 401 (com o suporte); aceite da tela pendente.
  - P2-S03: T01 concluída (2026-10-24), T02 implementada (aguarda credenciais Meta reais), T03 CONCLUÍDA (2026-10-24). T04 aguarda T02.
  - P2-S04: COMPLETA (T01-T04 ✔, 2026-10-26).
  - P2-S05: COMPLETA (T01-T04 ✔, 2026-10-26).
  - P2-S06: COMPLETA (T01-T04 ✔, 2026-10-26).
  - P2-S07: T01 IMPLEMENTADA (2026-10-26) — migration p2_s07_t01_copiloto (ai_suggestions + prompt_sets + prompt_versions + config_change_requests, RLS), prompt inicial v1 publicado (organização), _shared/copiloto.ts v5 (validação de schema + guardião da sugestão + chamada IA), Edge ticket-suggest-action v2 ACTIVE (JWT + membership 403 provado, contexto local, prompt clínica→org, modelo configurável), runner 15/15 PASS. Prova real: sugestão gerada (resumo/motivo/resposta sem valores/próxima ação/6 dados faltantes/evidências/confiança 0.80) em 9,3–10,9s; mensagem com preço na conversa → blocked conteudo_proibido (CA-03); isolamento 403 sem_vinculo; indisponível + lista manual provado. Correções durante a prova: max_tokens 800→2000 (JSON truncado), parser tolera quebra de linha literal, modelo configurável (haiku-5-5 na config AG-01; sonnet-5-5 truncava). Relatório: 05_entregas/RELATORIO_P2_S07_T01_20261026.md.
  - Pendências do dono: credenciais Meta reais no Vault; token Experts com o suporte.
- Próxima ação: aceite do Felipe na T01 → P2-S07-T02 (painel do copiloto na tela do ticket).
