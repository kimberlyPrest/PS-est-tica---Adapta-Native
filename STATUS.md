# Status do pacote do cliente

- Projeto: PS Estética.
- Fase 1: COMPLETA (16/16, 100%) — todas as SPECs com aceite humano.
- Fase 2 (7 SPECs / 28 tasks): 12/28 concluídas (43%) + 3 implementadas aguardando aceites.
  - P2-S01: T01–T04 concluídas (2026-10-14/18).
  - P2-S02: T01–T03 implementadas (2026-10-19) — token Experts recusado 401 (com o suporte); aceite da tela pendente.
  - P2-S03: T01 concluída (2026-10-24), T02 implementada (aguarda credenciais Meta reais), T03 CONCLUÍDA (2026-10-24). T04 aguarda T02.
  - P2-S04: COMPLETA (T01-T04 ✔, 2026-10-26).
  - P2-S05: COMPLETA (T01-T04 ✔, 2026-10-26) — tickets, motor de distribuição, tela do ticket/presença//filas e matriz 27/27 com demonstração ao vivo.
  - P2-S06: T01 CONCLUÍDA (2026-10-26, aceite "teste ok") — migration p2_s06_t01_agentes_guardiao no Supabase real (10 tabelas + feature_flags + 13 defs + 10 regras globais + 16 policies); runner 31/31 PASS; cartão IA no /admin/conexoes (Skip v0.0.46). Chave Anthropic pendente do dono — necessária na T02.
  - Pendências do dono: credenciais Meta reais no Vault; token Experts com o suporte; chave Anthropic no Vault (antes da P2-S06-T02).
  - DÚVIDA-2026-10-20-01 (INTERNAL_JOB_SECRET no cron) — RESOLVIDA em 2026-10-26 (Vault + cron com Authorization + header).
- Prazos fase 2: P2-S01 16/10 · P2-S02 20/10 · P2-S03 22/10 · P2-S04 26/10 · P2-S05 28/10 · P2-S06 30/10 · P2-S07 04/11.
- Próxima ação: P2-S06-T03 (console de conhecimento — não precisa de chave de IA) em paralelo à espera da chave Anthropic para a T02.
