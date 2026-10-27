# Status do projeto — CRM Estética (Adapta Native)

Atualizado: 2026-10-27 13:10 (BRT)

## Visão geral

- **Fase 1 (P1-S01..S05, 16 tasks): 16/16 ✔ CONCLUÍDA (2026-10-09)**
- **Fase 2 (P2-S01..S07, 28 tasks): 18/28 (64%) — P2-S07-T03 aceita ("teste ok", 27/10). Falta só T04 para fechar a fase 2.**
  - P2-S01 base/hardening/UI: ✔ COMPLETA (T01–T03)
  - P2-S02 conexão Clínica Experts: T01 ✔, T02 ✔ (implementada), T03 ✔ (implementada) — aguarda token real do suporte Experts
  - P2-S03 canais WhatsApp: T01 ✔, T02 ✔ (implementada — aguarda credenciais Meta reais no Vault + webhook no painel da Meta), T03 ✔ (aceite 24/10), T04 ☐ liberada (pré-condição: T02 com credenciais reais)
  - P2-S04 conversas/caixa de entrada: ✔ COMPLETA (T01–T04, aceites 26/10)
  - P2-S05 tickets/filas/SLA: ✔ COMPLETA (T01–T04, aceites 26/10)
  - P2-S06 triagem/guardião/respostas: ✔ COMPLETA (T01–T04, aceites 26/10)
  - P2-S07 copiloto/prompts: T01 ✔ (aceite 26/10), T02 ✔ (aceite 26/10), T03 ✔ (aceite 27/10), T04 ☐ (matriz + demonstração, fecha a fase 2)

## Pendências do dono

1. Token real da API Clínica Experts (com o suporte deles) — fecha P2-S02
2. Credenciais Meta reais no Vault (/admin/canais) + webhook no painel da Meta — fecha P2-S03-T02/T04
3. Publicação do app em produção (roda em preview — decisão do dono)

## Próximos passos

- P2-S07-T04: matriz do copiloto + demonstração ponta a ponta da fase 2 — fecha a fase 2
