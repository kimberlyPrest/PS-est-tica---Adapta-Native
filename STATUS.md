# Status do pacote do cliente

- Projeto: PS Estética.
- Fase 1: COMPLETA (16/16, 100%) — todas as SPECs com aceite humano.
- Fase 2 (7 SPECs / 28 tasks): 11/28 concluídas (39%).
  - P2-S01: T01–T04 concluídas (2026-10-14/18).
  - P2-S02: T01–T03 implementadas (2026-10-19) — token Experts recusado 401 (com o suporte); aceite da tela pendente.
  - P2-S03: T01 concluída (2026-10-24), T02 implementada (aguarda credenciais Meta reais), T03 CONCLUÍDA (2026-10-24). T04 aguarda T02.
  - P2-S04: COMPLETA (T01–T04, 2026-10-26 — aceites "reteste ok" e "T04 ok").
  - P2-S05: T01 CONCLUÍDA (2026-10-26 — migration 9 tabelas + console /admin/filas v0.0.42; aceite "teste ok") e T02 CONCLUÍDA (2026-10-26 — RPCs do motor + Edge process-ticket-routing + cron 30s; runner 13/13 + fumaça real com oferta ao owner). T03 liberada (prazo 28/10).
  - Pendências do dono: credenciais Meta reais no Vault (P2-S03-T02); token Experts com o suporte (P2-S02).
  - DÚVIDA-2026-10-20-01 (INTERNAL_JOB_SECRET no cron) — RESOLVIDA em 2026-10-26 (Vault + cron com Authorization + header).
- Prazos fase 2: P2-S01 16/10 · P2-S02 20/10 · P2-S03 22/10 · P2-S04 26/10 · P2-S05 28/10 · P2-S06 30/10 · P2-S07 04/11.
- Próxima ação: P2-S05-T03 — tela do ticket (aceitar, transferir, devolver, escalar, resolver), presença e visão do gestor /filas (prazo 28/10).
