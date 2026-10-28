# Estado atual — Adapta Cliente

- task_id: P2-S03-T04 (desvio registrado — aguardando decisão da consultora)
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S03-numeros-whatsapp-meta-zapi.md
- etapa: desvio_registrado_aguardando_consultora
- decisao_do_owner: **DESVIO FORMAL** (28/10, 06:41) — registrar a pendência do segundo número para a consultora em vez de comprar chip agora. A opção de retirar o número da Meta foi analisada e **descartada**.
- documento_do_desvio: `06_notas/desvio-p2-s03-t04-segundo-numero.md` (criado 28/10)
- motivo: um número registrado no Cloud API não pode operar ao mesmo tempo no aplicativo WhatsApp nem em API não oficial, e a exclusão do portfólio é caminho de ida (a ajuda do WhatsApp declara que número excluído não volta para outra conta da plataforma). A T04 exige os dois provedores vivos **ao mesmo tempo** → precisa de um segundo número.
- autorizacao_implementacao: confirmada
- adiantado_em_28_10: as DUAS provas da T04 que não dependem da Z-API viva foram executadas e passaram no banco real.
  - **Prova 1 — provedor fora do ar:** pedido com credencial inválida → 5 tentativas até esgotar → `outbound_requests.status=failed` (attempts=5, erro real do provedor) + linha em `dead_letters` (attempts=5) + mensagem arquivada. Antes ficava em `queued` para sempre.
  - **Prova 2 — conta não ativa:** pedido no canal Z-API real (`disabled`) → bloqueado na 1ª passada com `conta_desconectada`, attempts=0, dead letter gravada. A saída automática daquela conta para; a conta Meta não é afetada.
- cobertura_por_criterio (T04):
  - CA-P2-S03-06 — **coberto** na parte "provedor indisponível" e na parte "Z-API desconectada pausa a saída só da conta afetada", provado no banco real em 28/10.
  - CA-P2-S03-02, 03, 04, 05, 07, 08 — provados individualmente por provedor (T02 Meta 48/48, T03 Z-API 94/94); falta a execução **simultânea e comparada**, que é o que a T04 acrescenta.
  - Ponto 3 do roteiro (desconectar a instância de teste) — falta: exige instância Z-API **conectada** para desconectar.
- bugs_corrigidos_em_28_10 (Edge send-whatsapp-message v4 / versão 9):
  1. `dead_letters.organization_id` é NOT NULL e o insert não o enviava → todo insert falhava e o erro era engolido (não se checava `error`): **12.106 itens presos** na fila `dead_letter` com a tabela VAZIA — a fila de falha era invisível.
  2. A mensagem que falhava **nunca era arquivada** no pgmq → voltava após a vt e era reprocessada para sempre (itens vistos com `read_ct` 657 e 1579).
  3. Sucesso, reenfileiramento e pedido já resolvido também passam a arquivar.
  4. `dead_letters.ref_id` gravava o msg_id da fila; agora grava o ID DO PEDIDO (rastreável).
- opcoes_para_a_consultora (no documento do desvio):
  1. Aceitar a T04 com prova por provedor + contingência (não exige compra).
  2. Manter a T04 bloqueada até haver segundo número (fase 2 parada, prazo indefinido).
  3. Emendar a SPEC separando T04a (concluível hoje) e T04b (dependente do segundo número).
  - Recomendação técnica registrada: opção 1 ou 3.
- nao_feito_por_decisao: nada foi alterado em schema, SPEC, canal de produção ou número. Canal Meta `active` (+5581982349927), Z-API `disabled`. Nenhuma instância criada, nenhum chip comprado.
- ultima_acao: desvio registrado em `06_notas/desvio-p2-s03-t04-segundo-numero.md` e changelog atualizado (commit 35a8e21)
- proxima_acao: aguardar a decisão da consultora. Se opção 1 ou 3: fechar a T04 com a prova por provedor e o aceite do owner. Se opção 2: aguardar o segundo número e então rodar a matriz simultânea.
- atualizado_em: 2026-10-28T06:45:00-03:00
