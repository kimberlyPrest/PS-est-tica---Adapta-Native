# Status do projeto — CRM Estética (Adapta Native)

Atualizado: 2026-10-28 00:20 (BRT)

## Visão geral

- **Fase 1 (P1-S01..S05, 16 tasks): 16/16 ✔ CONCLUÍDA (2026-10-09)**
- **Fase 2 (P2-S01..S07, 28 tasks): 25/28 (89%) — restam 3: P2-S03-T04 (bloqueio do dono na Z-API) e as duas de aceite visual já implementadas.**
  - P2-S01 base/hardening/UI: ✔ COMPLETA (T01–T04)
  - P2-S02 conexão Clínica Experts: ✔ COMPLETA (T01–T03, aceite 27/10) — token do painel no Vault, API real autenticada; bug `date_birth` corrigido
  - P2-S03 canais WhatsApp: T01 ✔, **T02 ✔ CONCLUÍDA (aceite 28/10 — canal Meta real, recebimento e envio provados com `delivered`)**, T03 ✔ (aceite 24/10), T04 ☐ liberada (bloqueio: instância Z-API trial vencida)
  - P2-S04 conversas/caixa de entrada: ✔ COMPLETA (T01–T04, aceites 26/10)
  - P2-S05 tickets/filas/SLA: ✔ COMPLETA (T01–T04, aceites 26/10)
  - P2-S06 triagem/guardião/respostas: ✔ COMPLETA (T01–T04, aceites 26/10)
  - P2-S07 copiloto/prompts: ✔ COMPLETA (T01–T04, aceites 26 e 27/10)

## Estado dos canais de WhatsApp (28/10)

| Provedor | Número | Status | Observação |
|---|---|---|---|
| Meta Cloud API | +55 81 98234-9927 | **active** | Webhook registrado no app `CRM PS Estetica` (1063262590063176), app inscrito no WABA 1068799338488708; verify token no Vault; pipeline provado ponta a ponta |
| Z-API | +55 81 98234-9927 | disabled | Instância trial vencida (responde 400 "subscribe again"); o número migrou para o Cloud API — os dois não podem ficar ativos no mesmo telefone |

## Pendências do dono

1. **P2-S03-T04** — decidir entre renovar/criar instância Z-API de teste para a matriz real dos dois provedores, ou aceitar desvio documentado (matriz Z-API por provedor simulado + desconexão provada no banco).
2. **Modelos (templates) da Meta**: 0 aprovados — hoje o CRM só responde dentro da janela de 24 h; não inicia conversa nova.
3. Publicação do app em produção (roda em preview — decisão do dono).

## Próximos passos

- P2-S03-T02 fechada em 28/10: bug real do `payload_ref` corrigido na v4 do webhook Meta (commit `5c517cc`) — sem o payload gravado, o consumidor descartava toda mensagem em silêncio com recibo `accepted`.
- Falta apenas P2-S03-T04 para a fase 2 fechar 28/28.
