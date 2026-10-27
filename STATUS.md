# Status do projeto — CRM Estética (Adapta Native)

Atualizado: 2026-10-27 19:20 (BRT)

## Visão geral

- **Fase 1 (P1-S01..S05, 16 tasks): 16/16 ✔ CONCLUÍDA (2026-10-09)**
- **Fase 2 (P2-S01..S07, 28 tasks): 24/28 (86%) — SPECs P2-S02 e P2-S07 COMPLETAS. Restam as 2 tasks da P2-S03 que dependem das credenciais Meta do dono (T02 e T04).**
  - P2-S01 base/hardening/UI: ✔ COMPLETA (T01–T03)
  - P2-S02 conexão Clínica Experts: ✔ COMPLETA (T01–T03, aceite 27/10) — token do painel no Vault, API real autenticada; bug `date_birth` corrigido
  - P2-S03 canais WhatsApp: T01 ✔, T02 ✔ (implementada — aguarda credenciais Meta reais no Vault + webhook no painel da Meta), T03 ✔ (aceite 24/10), T04 ☐ liberada (pré-condição: T02 com credenciais reais)
  - P2-S04 conversas/caixa de entrada: ✔ COMPLETA (T01–T04, aceites 26/10)
  - P2-S05 tickets/filas/SLA: ✔ COMPLETA (T01–T04, aceites 26/10)
  - P2-S06 triagem/guardião/respostas: ✔ COMPLETA (T01–T04, aceites 26/10)
  - P2-S07 copiloto/prompts: T01 ✔ (aceite 26/10), T02 ✔ (aceite 26/10), T03 ✔ (aceite 27/10), T04 ☑ implementada (27/10 — matriz 13 cenários, fecha a SPEC e a fase 2)

## Pendências do dono

1. Credenciais Meta reais no Vault (/admin/canais) + webhook no painel da Meta — fecha P2-S03-T02/T04
2. Publicação do app em produção (roda em preview — decisão do dono)

## Próximos passos

- P2-S02 fechada em 27/10 (token Experts validado, bug de nascimento corrigido na Edge v10)
- Restam na fase 2: P2-S03-T02 (credenciais Meta) e P2-S03-T04 (matriz de contrato + desconexão)
