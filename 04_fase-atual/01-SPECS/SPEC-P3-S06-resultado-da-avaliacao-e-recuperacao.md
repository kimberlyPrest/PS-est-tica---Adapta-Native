# P3-S06 — Resultado da avaliação e recuperação de não fechamento

**Fase:** 3  
**Status:** liberada para implementação (29/10/2026)  
**Dono:** técnico de integração; aceite de post_sales (Comercial 2) e manager  
**Origem no escopo:** AG-09, RT-10, GATE-07; fluxo 13.7; terceira perda do §1; mapa de dados verificado em 13/10/2026  
**Degrau da solução:** reuso — agenda e vendas espelhadas, tarefas e cadências já existentes.

## Contexto e decisões fechadas

- Linha de base aproximada de setembro de 2026: 90 agendamentos de avaliação; 51 realizados e 38 cancelados (42%). Dos 51 pacientes avaliados, 21 compraram até 13/10 (41%), 14 deles no mesmo dia. Cerca de 30 avaliados por mês saem sem fechar.
- Procedimentos de avaliação hoje no catálogo: Avaliação corporal, Avaliação facial, Avaliação MAMA SCULP, Avaliação GLOW BUTT, Avaliação depilação, Avaliação capilar (duas grafias), Online avaliação e Reavaliação.
- A falta do paciente não é marcada no Clínica Experts; aparece como cancelamento ou não aparece.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

Toda avaliação realizada sem venda dentro do prazo vira caso de recuperação para o Comercial 2, com resumo; toda avaliação cancelada vira tarefa de reagendamento; o gestor vê a taxa de avaliação para venda.

## Limites e dependências

- **Inclui:** lista configurável de procedimentos de avaliação; detector de avaliação sem venda; caso e tarefa de recuperação com resumo; tarefa de reagendamento; registro do resultado da avaliação; cadência de recuperação; indicador de avaliação para venda.
- **Fora de escopo:** desconto ou condição automática; contato autônomo sem modelo aprovado; marcar falta no Clínica Experts.
- **Entradas e pré-condições:** responsável por registrar o resultado (GATE-07); prazo de espera e cadência de recuperação aprovados (GATE-08). Esses valores não travam a construção: o agente constrói a configuração com um padrão marcado como rascunho e o cliente preenche ou confirma os valores reais no teste desta SPEC (última task).
- **Saídas/artefatos:** função `start-post-evaluation-recovery`, configuração de procedimentos de avaliação, tela de registro de resultado, indicador.
- **Dependências e responsáveis:** P3-S01, P3-S03 e P3-S05. Post_sales e manager validam.
- **Risco e plano B:** caso aberto para quem já comprou — a venda espelhada é conferida de novo antes de criar o caso e ao abrir a tarefa.
- **Rollback ou reversão:** desligar o detector por flag; os casos abertos permanecem como tarefas comuns.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `appointments_mirror` | Supabase (espelho) | avaliações por identificador de procedimento e situação |
| `sales_mirror` | Supabase (espelho) | venda do mesmo paciente após a avaliação |
| Resultado da avaliação | Supabase | compareceu, não compareceu, fechou, não fechou e motivo |

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P3-S06-01 | Procedimento de avaliação é configuração por identificador do catálogo, nunca por nome. |
| RN-P3-S06-02 | Avaliação realizada sem venda do mesmo paciente no prazo de espera (padrão de 2 dias, ajustável) abre um caso de recuperação. |
| RN-P3-S06-03 | Avaliação cancelada abre tarefa de reagendamento no mesmo dia. |
| RN-P3-S06-04 | Uma venda posterior encerra a recuperação e registra a conversão como recuperada. |
| RN-P3-S06-05 | "Não fechou" exige motivo da lista de perdas. |
| RN-P3-S06-06 | O mesmo agendamento nunca abre dois casos. |
| RN-P3-S06-07 | Nenhuma condição comercial é oferecida pelo sistema. |

## Fluxo e regras

1. O espelho registra a avaliação como realizada ou cancelada.
2. O detector espera o prazo e confere se houve venda do mesmo paciente.
3. Sem venda: abre o caso para o Comercial 2 com resumo e inicia a cadência de recuperação.
4. A atendente registra o resultado em até três cliques.
5. A venda posterior encerra o caso como recuperado.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | avaliação realizada sem venda no prazo | um caso de recuperação com resumo e tarefa prioritária | cadência de recuperação iniciada |
| Limite | venda no mesmo dia, avaliação cancelada, agendamento reprocessado | sem caso; tarefa de reagendamento; sem duplicar | oportunidade segue a etapa certa |
| Falha | espelho atrasado | o detector adia a decisão e marca "aguardando dados" | decide na próxima atualização |

## Checklist de execução

- [ ] Procedimentos de avaliação marcados com o cliente.
- [ ] Prazo de espera e responsável aprovados carregados.
- [ ] Conferência com um mês real executada.
- [ ] Registro de resultado testado pelo Comercial 2.
- [ ] Manager validou o indicador.

## Critérios de aceite

- [ ] **CA-P3-S06-01:** Uma avaliação realizada sem venda no prazo cria um único caso de recuperação com resumo e tarefa prioritária.
- [ ] **CA-P3-S06-02:** Uma venda dentro do prazo não cria caso e gera a sugestão de ganho na oportunidade.
- [ ] **CA-P3-S06-03:** Uma avaliação cancelada cria tarefa de reagendamento no mesmo dia.
- [ ] **CA-P3-S06-04:** Uma venda posterior encerra a recuperação e registra a conversão como recuperada.
- [ ] **CA-P3-S06-05:** A atendente registra o resultado da avaliação em até três cliques, com motivo obrigatório em "não fechou".
- [ ] **CA-P3-S06-06:** Reprocessar o mesmo agendamento não duplica caso nem tarefa.
- [ ] **CA-P3-S06-07:** O indicador mostra avaliações agendadas, realizadas e canceladas, a taxa de avaliação para venda e os casos em recuperação, por clínica; para setembro de 2026 os números batem com a contagem direta na API.
- [ ] **CA-P3-S06-08:** Um agendamento de procedimento marcado como avaliação move a oportunidade do contato para "avaliação agendada".

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | avaliação realizada sem caso | espelhar avaliação realizada sem venda e avançar o prazo | nenhum caso: CA-P3-S06-01 falha | saída versionada do runner ou roteiro, anexada à task |
| GREEN | detector e caso de recuperação | avaliação agendada; realizada sem venda; com venda; cancelada | CA-P3-S06-01 a CA-P3-S06-03 e CA-P3-S06-08 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | encerramento, registro, repetição e conferência | venda posterior; registrar resultado; reprocessar; comparar com um mês real | CA-P3-S06-04 a CA-P3-S06-07 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** agendamentos e vendas sintéticos nas cinco combinações; conferência do indicador contra um mês real em ambiente autorizado.  
**Caminhos de erro obrigatórios:** espelho atrasado, agendamento repetido, venda de outro paciente com mesmo nome, procedimento não marcado como avaliação.  
**Evidência exigida:** lista de casos de teste, tabela de conferência do mês real e aceite do Comercial 2.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P3-S06-T01 | Criar a configuração de procedimentos de avaliação e o detector de avaliação sem venda. | técnico de integração | CA-P3-S06-01, CA-P3-S06-02, CA-P3-S06-03, CA-P3-S06-06, CA-P3-S06-08 | RED/GREEN do detector | relatório do runner | P3-S01-T03 | 17/11/2026 | ☐ Liberada |
| P3-S06-T02 | Construir o caso de recuperação, o registro do resultado e a cadência de recuperação. | técnico de frontend + integração | CA-P3-S06-04, CA-P3-S06-05 | cenário principal e encerramento por venda | gravação do registro de resultado | T01; P3-S05-T02 | 18/11/2026 | ☐ Liberada |
| P3-S06-T03 | Conferir o indicador com um mês real e demonstrar com o Comercial 2. | QA + post_sales | CA-P3-S06-01, CA-P3-S06-06, CA-P3-S06-07 | REGRESSÃO e conferência contra a API | tabela de conferência e aceite | T02 concluída | 18/11/2026 | ☐ Liberada |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| 2026-10-29 | Liberação da fase 3 | Pré-condições das tasks e teste do cliente | Valor que depende do cliente deixa de travar a construção: entra como rascunho e é confirmado no teste da SPEC, na última task, conforme o contrato comum (seção 8) |
