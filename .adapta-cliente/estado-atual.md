# Estado atual — Adapta Cliente

- task_id: P2-S03-T04 (liberada — pré-requisito do dono em aberto: instância Z-API nova)
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S03-numeros-whatsapp-meta-zapi.md
- etapa: aguardando_pre_requisito_do_dono
- decisao_do_owner: **CAMINHO A** — criar instância Z-API nova com número DIFERENTE, em outra clínica (28/10). Objetivo: cumprir a SPEC literal (dois provedores, dois números, duas clínicas).
- autorizacao_implementacao: confirmada
- adiantado_em_28_10: as DUAS provas da T04 que não dependem da Z-API viva foram executadas e passaram no banco real.
  - **Prova 1 — provedor fora do ar:** pedido com credencial inválida → 5 tentativas até esgotar → `outbound_requests.status=failed` (attempts=5, erro real do provedor) + linha em `dead_letters` (attempts=5) + mensagem arquivada. Antes ficava em `queued` para sempre.
  - **Prova 2 — conta não ativa:** pedido no canal Z-API real (`disabled`) → bloqueado na 1ª passada com `conta_desconectada`, attempts=0, dead letter gravada. A saída automática daquela conta para; a conta Meta não é afetada.
- bugs_corrigidos_em_28_10 (Edge send-whatsapp-message v4 / versão 9):
  1. `dead_letters.organization_id` é NOT NULL e o insert não o enviava → todo insert falhava e o erro era engolido (não se checava `error`): **12.106 itens presos** na fila `dead_letter` com a tabela VAZIA — a fila de falha era invisível.
  2. A mensagem que falhava **nunca era arquivada** no pgmq → voltava após a vt e era reprocessada para sempre (itens vistos com `read_ct` 657 e 1579).
  3. Sucesso, reenfileiramento e pedido já resolvido também passam a arquivar.
  4. `dead_letters.ref_id` gravava o msg_id da fila; agora grava o ID DO PEDIDO (rastreável).
- pre_requisito_do_dono (pendente): criar a instância na Z-API (app.z-api.io) com um número que NÃO seja +55 81 98234-9927 (hoje o número pertence ao Cloud API da Meta) e informar Instance ID + Token + Client-Token. Clínica sugerida: PS Caruaru, PS Jaboatão ou PS OLINDA (todas sem canal, owner em todas).
- ultima_acao: provas 1 e 2 executadas e aprovadas; fixtures de teste removidas (dead_letters=0, pedidos system_test=0, canais de prova=0)
- proxima_acao: com a instância nova em mãos, cadastrar o canal pela tela /admin/canais, configurar webhooks da Z-API e concluir a matriz dos dois provedores + desconexão real
- atualizado_em: 2026-10-28T00:50:00-03:00
