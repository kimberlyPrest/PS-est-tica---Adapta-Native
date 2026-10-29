# P3-S03 — Tarefas e próxima ação obrigatória

**Fase:** 3  
**Status:** liberada para implementação (29/10/2026)  
**Dono:** técnico de implementação; aceite do manager  
**Origem no escopo:** §7.4 (`tasks`, `activities`), §8.3, §1 (100% com próxima ação), §16 (alertas), RT-03  
**Degrau da solução:** construção mínima — tabela de tarefas e uma varredura diária; reusa o agendador.

## Contexto e decisões fechadas

- A segunda perda apontada pelo cliente é o lead que não avança por falta de próxima ação.
- O resultado mensurável do escopo pede 100% das conversas em atendimento com responsável e próxima ação.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

Na tela "Minha fila do dia", cada atendente vê as tarefas vencidas e as de hoje; nenhuma oportunidade ou conversa aberta fica sem próxima ação — o sistema acusa as órfãs e avisa o gestor.

## Limites e dependências

- **Inclui:** tarefas e atividades; "Minha fila do dia"; linha do tempo do contato; regra de próxima ação ao concluir; varredura de órfãs; alerta de atraso por etapa.
- **Fora de escopo:** geração de tarefa por cadência (P3-S05); recuperação pós-avaliação (P3-S06); agenda pessoal.
- **Entradas e pré-condições:** prazos por etapa aprovados (GATE-06); tipos de tarefa aprovados. Esses valores não travam a construção: o agente constrói a configuração com um padrão marcado como rascunho e o cliente preenche ou confirma os valores reais no teste desta SPEC (última task).
- **Saídas/artefatos:** tabelas `tasks` e `activities`, varredura diária, telas de fila do dia e linha do tempo.
- **Dependências e responsáveis:** P3-S02. Manager valida os alertas.
- **Risco e plano B:** excesso de tarefas automáticas virar ruído — a varredura cria no máximo uma tarefa aberta por caso e agrupa o alerta ao gestor em um resumo diário.
- **Rollback ou reversão:** desligar a varredura por flag; as tarefas manuais continuam.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `tasks` | Supabase | entidade, responsável, equipe, tipo, vencimento, situação; estados do §8.3 |
| `activities` | Supabase | mensagens, ligações, avaliações, mudanças de etapa e decisões por contato |

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P3-S03-01 | Nenhuma oportunidade é criada ou tem a última tarefa concluída sem próxima ação com data: a regra é validada na escrita. A varredura diária é a rede de segurança para o que escapar, com alerta em até 24 horas. |
| RN-P3-S03-02 | Concluir a última tarefa de um caso aberto exige criar a próxima ou encerrar o caso. |
| RN-P3-S03-03 | A varredura diária cria tarefa para o dono do caso órfão; sem dono, para o gestor. |
| RN-P3-S03-04 | Tarefa vencida além do prazo da etapa entra no alerta diário do gestor. |
| RN-P3-S03-05 | No máximo uma tarefa automática aberta por caso; a repetição da varredura não duplica. |

## Fluxo e regras

1. A atendente abre "Minha fila do dia" e vê vencidas e de hoje.
2. Ao concluir, informa o resultado e define a próxima ação ou encerra.
3. Toda manhã a varredura procura casos abertos sem próxima ação.
4. Cria a tarefa faltante e inclui os atrasos no alerta do gestor.
5. A linha do tempo do contato reúne tudo o que aconteceu.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | atendente com tarefas do dia | lista ordenada por vencimento; conclusão pede a próxima ação | caso segue com data definida |
| Limite | caso aberto sem tarefa ou sem dono | varredura cria uma tarefa para o dono ou o gestor | segunda execução não duplica |
| Falha | varredura falha | alerta técnico; nenhuma tarefa parcial repetida | nova execução completa o que faltou |

## Checklist de execução

- [ ] Prazos por etapa carregados.
- [ ] Fila do dia testada por duas atendentes.
- [ ] Varredura executada duas vezes no mesmo dia.
- [ ] Alerta do gestor conferido.
- [ ] Manager validou.

## Critérios de aceite

- [ ] **CA-P3-S03-01:** A atendente cria, conclui e reatribui tarefa ligada a oportunidade, conversa ou contato.
- [ ] **CA-P3-S03-02:** Concluir a última tarefa de uma oportunidade aberta exige criar a próxima ou encerrar a oportunidade.
- [ ] **CA-P3-S03-03:** A varredura diária encontra todo caso aberto sem próxima ação e cria uma tarefa para o dono, ou para o gestor quando não há dono.
- [ ] **CA-P3-S03-04:** Tarefa vencida além do prazo da etapa aparece no alerta diário do gestor.
- [ ] **CA-P3-S03-05:** A linha do tempo do contato reúne mensagens, tarefas, mudanças de etapa e agendamentos em ordem.
- [ ] **CA-P3-S03-06:** Rodar a varredura duas vezes no mesmo dia não cria tarefa repetida, e cada usuário vê só tarefas das suas clínicas.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | caso aberto sem próxima ação | criar oportunidade sem tarefa e rodar a varredura | nenhuma tarefa criada: CA-P3-S03-03 falha | saída versionada do runner ou roteiro, anexada à task |
| GREEN | tarefas e fila do dia | criar, concluir com próxima ação, reatribuir | CA-P3-S03-01, CA-P3-S03-02 e CA-P3-S03-05 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | varredura, atraso e repetição | casos órfãos com e sem dono; tarefa vencida; segunda execução; outra clínica | CA-P3-S03-03, CA-P3-S03-04 e CA-P3-S03-06 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** oportunidades e conversas sintéticas com e sem tarefa, com e sem dono; relógio controlado.  
**Caminhos de erro obrigatórios:** caso sem dono, tarefa vencida, repetição da varredura, usuário sem permissão.  
**Evidência exigida:** gravação da fila do dia, resultado de duas varreduras e alerta do gestor.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P3-S03-T01 | Criar tarefas e atividades com as regras de próxima ação no servidor. | técnico de banco | CA-P3-S03-01, CA-P3-S03-02 | RED/GREEN das regras | relatório do runner | P3-S02-T01 | 11/11/2026 | ☐ Liberada |
| P3-S03-T02 | Construir "Minha fila do dia" e a linha do tempo do contato. | técnico de frontend | CA-P3-S03-01, CA-P3-S03-05 | cenário principal em tela | gravação da tela | T01 concluída | 11/11/2026 | ☐ Liberada |
| P3-S03-T03 | Implementar a varredura de casos sem próxima ação e o alerta de atraso, e demonstrar com o gestor. | técnico de integração + manager | CA-P3-S03-03, CA-P3-S03-04, CA-P3-S03-06 | REGRESSÃO com duas execuções | resultado das varreduras e aceite | T01 concluída | 12/11/2026 | ☐ Liberada |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| 2026-10-29 | Liberação da fase 3 | Pré-condições das tasks e teste do cliente | Valor que depende do cliente deixa de travar a construção: entra como rascunho e é confirmado no teste da SPEC, na última task, conforme o contrato comum (seção 8) |
