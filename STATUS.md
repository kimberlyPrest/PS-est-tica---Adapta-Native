# Status do pacote do cliente

- Projeto: PS Estética.
- Fase 1: COMPLETA (16/16, 100%) — todas as SPECs com aceite humano.
- Fase 2 (7 SPECs / 28 tasks): 6/28 concluídas (21%) + 7 implementadas aguardando aceites.
  - P2-S01: T01–T04 concluídas (2026-10-14/18).
  - P2-S02: T01–T03 implementadas (2026-10-19) — token Experts recusado 401 (com o suporte); aceite da tela pendente.
  - P2-S03: T01 concluída (2026-10-24), T02 implementada (aguarda credenciais Meta reais), T03 CONCLUÍDA (2026-10-24). T04 aguarda T02.
  - P2-S04: T01 ACEITE CONFIRMADO (2026-10-26, "teste T01 OK"); T02 implementada e FILA DESTRAVADA (2026-10-26 — pgmq.send 406 corrigido com wrappers + trigger; 9 mensagens reprocessadas → 4 conversas) — AGUARDANDO FELIPE REFAZER O TESTE; T03 implementada (runner 63/63; aceite pendente); T04 matriz técnica APROVADA (2026-10-24; demonstração da recepção pendente).
  - Pendências do dono: refazer teste T02/T03; credenciais Meta reais no Vault; token Experts com o suporte.
  - DÚVIDA-2026-10-20-01 (INTERNAL_JOB_SECRET no cron) — RESOLVIDA em 2026-10-26 (Vault + cron com Authorization + header).
- Prazos fase 2: P2-S01 16/10 · P2-S02 20/10 · P2-S03 22/10 · P2-S04 26/10 · P2-S05 28/10 · P2-S06 30/10 · P2-S07 04/11.
- Próxima ação: Felipe refaz teste T02 (mensagem real) → aceite T02/T03 → demonstração da recepção (fecha T04) → SPEC P2-S05.
