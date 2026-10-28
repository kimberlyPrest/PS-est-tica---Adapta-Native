## 2026-10-28 (2) — P2-S03-T04 adiantada: dois bugs de fila corrigidos e as duas provas que não dependem da Z-API

- Decisão do owner: **caminho A** para a T04 — criar instância Z-API nova com número diferente em outra clínica (cumpre a SPEC literal). Bloqueio atual: a instância antiga está com trial vencido e o número migrou para o Cloud API.
- Adiantadas as duas provas da T04 que **não** dependem de instância viva:
  - **Provedor fora do ar** → 5 tentativas até esgotar → `outbound_requests.status=failed` (attempts=5) + linha em `dead_letters` + mensagem arquivada.
  - **Conta não ativa** → bloqueio imediato com `conta_desconectada` (attempts=0) e dead letter; a outra conta não é afetada.
- **BUG 1 (grave, encontrado nesta prova):** `dead_letters.organization_id` é NOT NULL e o consumidor não o enviava; o erro era **engolido** porque o retorno de `.insert()` não era checado. Consequência: **12.106 itens presos** na fila `dead_letter` com a tabela `dead_letters` VAZIA — a "fila de falha visível" exigida pela SPEC era invisível.
- **BUG 2 (grave):** a mensagem consumida nunca era arquivada no pgmq. Sucesso, reenfileiramento e falha saíam do laço sem `fila_arquivar`, então o pgmq devolvia a mesma mensagem após a vt e ela era reprocessada indefinidamente (itens vistos com `read_ct` **657** e **1579**). O `process-inbound-event` já arquivava corretamente; o consumidor de saída não.
- **BUG 3:** `dead_letters.ref_id` gravava o `msg_id` da fila, não o id do pedido — a linha da fila de falha ficava sem rastro. Corrigido para o id de `outbound_requests`.
- Corretiva publicada: Edge **`send-whatsapp-message` v4** (versão 9 no projeto), autossuficiente com os adaptadores meta/zapi inlined (o deploy por MCP não resolve imports relativos para `_shared/providers`).
- Fixtures removidas: `dead_letters`=0, pedidos `system_test`=0, canais de prova=0, fila de saída=0. Canais reais preservados: Meta `active`, Z-API `disabled`.
- Resta para fechar a T04: instância Z-API nova (pré-requisito do dono) → matriz dos dois provedores + desconexão real.
- Evidências: `.adapta-cliente/estado-atual.md`, `supabase/functions/send-whatsapp-message/index.ts` (v4) neste commit.
