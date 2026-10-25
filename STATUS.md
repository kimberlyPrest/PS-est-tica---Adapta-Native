# Status do pacote do cliente

- Projeto: PS Estética.
- Fase 1: COMPLETA (16/16, 100%) — todas as SPECs com aceite humano.
- Fase 2 (7 SPECs / 28 tasks): 6/28 concluídas (21%) + 3 implementadas aguardando aceites pontuais.
  - P2-S01: T01–T04 concluídas (2026-10-14/18) — base versionada, hardening, tipos/guardas, suíte de testes.
  - P2-S02: T01–T03 implementadas (2026-10-19) — conexão real Experts; token recusado 401 pela API (com o suporte); aceite da tela pendente.
  - P2-S03: T01 concluída (2026-10-24), T02 implementada (2026-10-20, aguarda credenciais Meta reais), T03 CONCLUÍDA (2026-10-24) — troca real Z-API provada (recebimento + envio + situação).
  - Pendências do dono: credenciais Meta reais no Vault; capturas de aceite (P2-S01-T03, P2-S02-T03).
  - Pendência com consultora: DÚVIDA do INTERNAL_JOB_SECRET no pg_cron (06_notas/2026-10-20) — consumidores não processam via cron até resolver; envio/recebimento provados por disparo direto.
- Prazos fase 2: P2-S01 16/10 · P2-S02 20/10 · P2-S03 22/10 · P2-S04 26/10 · P2-S05 28/10 · P2-S06 30/10 · P2-S07 04/11.
- Próxima ação: P2-S03-T04 (matriz de contrato dos dois provedores + desconexão real) — última da SPEC P2-S03.
