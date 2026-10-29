# DESVIO para a consultora — P2-S03-T04: matriz dos dois provedores exige um segundo número

- Data: 2026-10-28 · Originada na task: P2-S03-T04 · Status: **AGUARDANDO DECISÃO DA CONSULTORA**
- Decisão do owner (Felipe, 28/10): registrar o desvio formalmente em vez de comprar um segundo número agora.
- Nenhuma alteração de schema, nenhuma mudança no CRM e nenhum número em produção foram tocados por este registro.

## O problema em linguagem simples

A T04 pede a matriz de contrato dos **dois provedores** e a demonstração de envio e recebimento reais em cada um. Para isso os dois precisam estar vivos **ao mesmo tempo**, cada um com o seu número.

Hoje só existe **um número**: `+55 81 98234-9927`. Ele está no **Cloud API da Meta** (canal ativo desde a T02) e a Z-API correspondente está `disabled` — o trial venceu em 24/10 e o número migrou para a Meta.

A regra da Meta não permite contornar isso pela via da reutilização: um número registrado no Cloud API não pode operar no aplicativo WhatsApp nem em API não oficial simultaneamente. E a exclusão do número do portfólio é caminho de ida — a própria documentação de ajuda do WhatsApp informa que número excluído não retorna para outra conta da plataforma, além de apagar os dados do número.

Ou seja: para ter os dois provedores vivos é preciso **um segundo número**. Não existe caminho técnico que use um número só.

## O que já foi provado e o que falta

**Provado no banco real, com o consumidor de saída em produção (28/10):**

- **CA-P2-S03-06, parte "provedor indisponível":** pedido com credencial inválida → 5 tentativas até o limite → `outbound_requests.status = failed` + linha em `dead_letters` + mensagem arquivada na fila. Antes desta correção o pedido ficava em `queued` indefinidamente.
- **CA-P2-S03-06, parte "Z-API desconectada pausa a saída automática só da conta afetada":** pedido no canal Z-API real (`disabled`) → bloqueado na primeira passada com `conta_desconectada`, `attempts = 0`, dead letter gravada. O canal Meta da outra clínica não foi afetado.

**Falta (depende do segundo número):**

- CA-P2-S03-02, CA-P2-S03-03, CA-P2-S03-04, CA-P2-S03-05, CA-P2-S03-07 e CA-P2-S03-08 na **matriz lado a lado dos dois provedores**.
- Ponto 3 do roteiro da T04: desconectar a instância de teste da Z-API e observar a conta mudar para `disconnected` com a saída automática parando — exige uma instância Z-API **conectada** para desconectar.

Observação importante: cada CA já foi provado **individualmente** por provedor nas T02 (Meta, runner 48/48) e T03 (Z-API, runner 94/94). O que a T04 acrescenta é a execução **simultânea e comparada** dos dois.

## Três bugs reais encontrados ao adiantar as provas

Este desvio vem acompanhado de correções que não têm relação com o número, mas que a T04 revelou:

1. `dead_letters.organization_id` é `NOT NULL` e o consumidor de saída não o enviava; como o retorno do `insert` não era checado, **todo** insert falhava em silêncio. Resultado: **12.106 itens presos** na fila `dead_letter` com a tabela `dead_letters` **vazia** — a "fila de falha visível" exigida pelo CA-P2-S03-06 não existia na prática.
2. A mensagem consumida **nunca era arquivada** no pgmq. Saía do laço sem `fila_arquivar` em nenhum desfecho, então o pgmq a devolvia depois da vt e ela era reprocessada indefinidamente — itens vistos com `read_ct` **657** e **1579**.
3. `dead_letters.ref_id` gravava o `msg_id` da fila em vez do id de `outbound_requests` — a linha da fila de falha não permitia rastrear qual envio falhou.

Corrigido e publicado na Edge `send-whatsapp-message` **v4** (versão 9 no projeto). As duas provas acima foram reexecutadas **depois** da correção e passaram. Fixtures removidas ao final.

## Decisão da consultora (29/10)

**Opção 1.** A T04 fecha com a prova por provedor (T02 e T03), as duas provas de contingência de 28/10 e o "ok" do owner. A execução simultânea dos dois provedores e o ponto 3 do roteiro ficam como pendência rastreada para quando houver o segundo número, sem travar a fase 2. Emenda registrada na SPEC P2-S03.

## Opções para a consultora decidir

1. **Aceitar a T04 com prova por provedor + as duas provas de contingência** — registra-se em ata que a execução simultânea dos dois provedores fica para quando houver segundo número, e a T04 é concluída com os CAs cobertos individualmente (T02 48/48, T03 94/94) mais CA-P2-S03-06 provado no banco real. Não exige compra.
2. **Manter a T04 bloqueada até haver um segundo número** — a fase 2 fica parada nesta task até o owner providenciar um chip/linha nova e uma instância Z-API paga. Prazo indefinido, dependente de compra.
3. **Emendar a SPEC** para separar a T04 em duas: T04a (matriz Meta + contingência, concluível hoje) e T04b (matriz Z-API simultânea, dependente do segundo número). A fase 2 fecha e a T04b entra como pendência rastreada.

**Recomendação técnica:** opção 1 ou 3. A opção 2 trava a fase inteira por um item de infraestrutura de baixo custo mas de prazo incerto, e o valor da T04 — comparar contrato entre provedores — já está substancialmente coberto pelas matrizes das T02 e T03.

## O que NÃO foi feito e não será sem decisão

- Não foi feita nenhuma alteração na SPEC (a decisão de emendar é da consultora).
- Não foi removido o número da Meta nem alterado o canal em produção.
- Não foi criada instância Z-API, nem comprado chip.
- O canal Meta segue `active` e o canal Z-API segue `disabled`.

## Referências

- SPEC: `04_fase-atual/01-SPECS/SPEC-P2-S03-numeros-whatsapp-meta-zapi.md` — seção "Roteiro das tasks", P2-S03-T04, itens 1 a 4; Critérios de aceite CA-P2-S03-02 a CA-P2-S03-08.
- Regra da Meta sobre exclusão e reutilização de número: documentação de Business phone numbers (Meta for Developers) e WhatsApp Help Center, artigo 209248051996804 — "Phone numbers deleted from a WhatsApp Business Platform account can't be used again for [another] WhatsApp Business Platform account".
- Evidências das duas provas: `.adapta-cliente/estado-atual.md`, e entrada de 2026-10-28 (2) no `changelog.md`.
- Corretiva: `supabase/functions/send-whatsapp-message/index.ts` v4.
