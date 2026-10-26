# Status do pacote do cliente

- Projeto: PS Estética.
- Fase 1: COMPLETA (16/16, 100%) — todas as SPECs com aceite humano.
- Fase 2 (7 SPECs / 28 tasks): 11/28 concluídas (39%) + 3 implementadas aguardando aceites.
  - P2-S01: T01–T04 concluídas (2026-10-14/18).
  - P2-S02: T01–T03 implementadas (2026-10-19) — token Experts recusado 401 (com o suporte); aceite da tela pendente.
  - P2-S03: T01 concluída (2026-10-24), T02 implementada (aguarda credenciais Meta reais), T03 CONCLUÍDA (2026-10-24). T04 aguarda T02.
  - P2-S04: T01/T02/T03 ACEITES CONFIRMADOS (2026-10-26, "teste T01 OK" + "reteste ok" do owner); fixes do dia: contexto da clínica (v0.0.28), render de anexos (v0.0.30), mídia Z-API imageUrl+caption (zapi.ts v3, webhook v5, consumidor v10) — foto da Milena recuperada e provada na tela; T04 ACEITE CONFIRMADO (2026-10-26, "T04 ok" — demonstração com a recepção realizada). SPEC P2-S04 COMPLETA (T01-T04 ✔).
  - P2-S05: T01/T02 ACEITES CONFIRMADOS ("teste ok", 26/10); T03 CONCLUÍDA (2026-10-26, aceite "teste ok") — painel do ticket (Assumir/Recusar/ações/linha do tempo), chave de presença (batimento 30s) e visão do gestor /filas; Skip v0.0.45; T04 CONCLUÍDA (2026-10-26, aceite "teste ok") — matriz 27/27 PASS + demonstração ao vivo com o gestor (oferta → vencimento → escalonamento → reoferta → aceite pela tela). SPEC P2-S05 COMPLETA (T01-T04 ✔).
  - Pendências do dono: credenciais Meta reais no Vault; token Experts com o suporte.
  - DÚVIDA-2026-10-20-01 (INTERNAL_JOB_SECRET no cron) — RESOLVIDA em 2026-10-26 (Vault + cron com Authorization + header).
- Prazos fase 2: P2-S01 16/10 · P2-S02 20/10 · P2-S03 22/10 · P2-S04 26/10 · P2-S05 28/10 · P2-S06 30/10 · P2-S07 04/11.
- Próxima ação: SPEC P2-S06 (triagem de IA e guardião, prazo 30/10) — T01 precisa da chave de IA no Vault.
