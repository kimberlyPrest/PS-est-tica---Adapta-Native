# P3-S05 — Follow-up por cadência configurável

**Fase:** 3  
**Status:** liberada para implementação (29/10/2026)  
**Dono:** técnico de integração; aceite de sales e manager  
**Origem no escopo:** AG-08, §7.5, RT-09, GATE-08; fluxo 13.6; manual comercial (cadência 5/15/30/60 dias)  
**Degrau da solução:** nativo da plataforma — agendador e filas do Supabase; reusa guardião, modelos e fila de saída.

## Contexto e decisões fechadas

- O manual comercial da clínica prevê retomadas em 5, 15, 30 e 60 dias.
- A cadência nasce em modo "tarefa com mensagem pronta"; o envio automático de modelo é ligado por clínica.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

O lead sem resposta entra numa cadência; no dia certo a atendente recebe a tarefa com a mensagem pronta (ou o modelo aprovado sai sozinho, se a clínica ligar), e a resposta do cliente pausa tudo.

## Limites e dependências

- **Inclui:** políticas de cadência por clínica; inscrição automática e manual; execução por agendador e fila; pausa por resposta; respeito a recusa, horário e máximo de tentativas; registro de cada tentativa; console de políticas.
- **Fora de escopo:** campanhas para base antiga (P4-S04); recuperação pós-avaliação (P3-S06); oferta de desconto.
- **Entradas e pré-condições:** cadências, limites, horários e mensagens aprovados (GATE-08). Esses valores não travam a construção: o agente constrói a configuração com um padrão marcado como rascunho e o cliente preenche ou confirma os valores reais no teste desta SPEC (última task). Enquanto as cadências estiverem em rascunho, nada é enviado sozinho: o modo é tarefa com rascunho.
- **Saídas/artefatos:** tabelas `followup_*`, funções `schedule-followups` e `process-followups`, console de políticas.
- **Dependências e responsáveis:** P2-S06 (guardião e modelos), P3-S02 e P3-S03. Sales e manager validam.
- **Risco e plano B:** mensagem sair depois de o cliente responder — a resposta pausa a inscrição antes de qualquer execução e o guardião confere de novo na hora do envio.
- **Rollback ou reversão:** desligar a política ou o interruptor da clínica; inscrições ficam pausadas e nada é enviado.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `followup_policies` | Supabase | gatilho, atrasos, horário permitido, máximo de tentativas, modo de aprovação, versão |
| `followup_enrollments`, `followup_runs` | Supabase | situação, próxima execução, tentativa e resultado |
| `consents`, `message_templates` | Supabase | recusa por finalidade; modelos por provedor |

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P3-S05-01 | A resposta do cliente pausa a inscrição em até um minuto e devolve o caso à fila. |
| RN-P3-S05-02 | Recusa do contato, ganho, perda ou ticket humano aberto encerram ou pausam a cadência. |
| RN-P3-S05-03 | Nunca fora do horário permitido nem acima do máximo de tentativas. |
| RN-P3-S05-04 | Modo padrão: tarefa com rascunho. Envio automático só de modelo aprovado sem preço, desconto, voucher nem indicação de procedimento, com o interruptor ligado na clínica; modelo com qualquer desses elementos exige aprovação humana de cada envio. |
| RN-P3-S05-05 | Na Meta, fora da janela de 24 horas, usa modelo aprovado ou vira tarefa. |
| RN-P3-S05-06 | A mesma execução reprocessada não envia de novo. |

## Fluxo e regras

1. O gatilho inscreve o caso na política da clínica.
2. O agendador enfileira as inscrições vencidas.
3. O consumidor confere resposta recente, recusa, horário, tentativas e situação do caso.
4. Elegível: cria a tarefa com rascunho ou envia o modelo; registra a tentativa.
5. A resposta do cliente pausa a inscrição e reabre o caso na fila.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | lead sem resposta há 5 dias | tarefa com mensagem pronta para o dono, ou envio do modelo | tentativa registrada |
| Limite | cliente respondeu, recusou, comprou ou está em atendimento humano | nada é enviado; inscrição pausada ou encerrada com motivo | caso volta à fila quando aplicável |
| Falha | canal fora do ar ou execução repetida | sem envio duplicado; item vai para nova tentativa e depois para a fila de falha | tarefa manual para o dono |

## Checklist de execução

- [ ] Cadências e mensagens aprovadas carregadas.
- [ ] Relógio controlado cobrindo os quatro atrasos.
- [ ] Pausa por resposta medida.
- [ ] Reprocessamento testado.
- [ ] Sales e manager validaram.

## Critérios de aceite

- [ ] **CA-P3-S05-01:** A política por clínica define gatilho, atrasos, horário, máximo de tentativas e modo de aprovação, com versão.
- [ ] **CA-P3-S05-02:** A inscrição acontece pelo gatilho e também manualmente.
- [ ] **CA-P3-S05-03:** No dia previsto, a execução gera tarefa com rascunho ou envia o modelo aprovado, conforme o modo.
- [ ] **CA-P3-S05-04:** A resposta do cliente pausa a inscrição em até um minuto e devolve o caso à fila.
- [ ] **CA-P3-S05-05:** Recusa do contato, ganho, perda ou ticket humano aberto encerram ou pausam a cadência.
- [ ] **CA-P3-S05-06:** Nenhuma execução ocorre fora do horário permitido ou acima do máximo de tentativas.
- [ ] **CA-P3-S05-07:** Reprocessar a mesma execução não envia mensagem repetida.
- [ ] **CA-P3-S05-08:** Na Meta, fora da janela, a execução usa modelo aprovado ou vira tarefa.
- [ ] **CA-P3-S05-09:** Um modelo com preço, desconto, voucher ou indicação de procedimento não é enviado sem a aprovação humana daquele envio.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | lead parado sem cadência | avançar o relógio 5 dias | nenhuma tarefa nem envio: CA-P3-S05-03 falha | saída versionada do runner ou roteiro, anexada à task |
| GREEN | política, inscrição e execução | inscrever e avançar o relógio nos quatro atrasos | CA-P3-S05-01 a CA-P3-S05-03 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | pausa, limites e repetição | resposta do cliente; recusa; fora do horário; máximo; reprocessar; fora da janela; modelo com preço | CA-P3-S05-04 a CA-P3-S05-09 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** leads sintéticos em cada situação; relógio controlado; canal simulado.  
**Caminhos de erro obrigatórios:** resposta tardia, recusa, fora do horário, máximo atingido, canal fora do ar, execução repetida.  
**Evidência exigida:** linha do tempo de uma inscrição completa, relatório do runner e aceite.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P3-S05-T01 | Criar as tabelas de cadência e o console de políticas por clínica. | técnico de banco + frontend | CA-P3-S05-01, CA-P3-S05-02 | configuração e inscrição | capturas e versão publicada | P3-S02-T01 | 13/11/2026 | ☐ Liberada |
| P3-S05-T02 | Implementar o agendador, o consumidor e as regras de elegibilidade. | técnico de integração | CA-P3-S05-03, CA-P3-S05-06, CA-P3-S05-08 | GREEN com relógio controlado | relatório do runner | T01; P3-S03-T01; P2-S06-T01 | 16/11/2026 | ☐ Liberada |
| P3-S05-T03 | Implementar a pausa por resposta, o respeito à recusa e a proteção contra repetição. | técnico de integração | CA-P3-S05-04, CA-P3-S05-05, CA-P3-S05-07, CA-P3-S05-09 | bordas de pausa, repetição e conteúdo do modelo | relatório do runner | T02 concluída | 16/11/2026 | ☐ Liberada |
| P3-S05-T04 | Executar a matriz completa e demonstrar com o time comercial. | QA + sales | CA-P3-S05-03, CA-P3-S05-04, CA-P3-S05-05, CA-P3-S05-06, CA-P3-S05-07 | REGRESSÃO completa | matriz e aceite | T03 concluída | 17/11/2026 | ☐ Liberada |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| 2026-10-29 | Liberação da fase 3 | Pré-condições das tasks e teste do cliente | Valor que depende do cliente deixa de travar a construção: entra como rascunho e é confirmado no teste da SPEC, na última task, conforme o contrato comum (seção 8) |
