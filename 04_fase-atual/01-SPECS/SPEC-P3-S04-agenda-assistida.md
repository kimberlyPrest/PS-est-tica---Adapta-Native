# P3-S04 — Agenda assistida no atendimento

**Fase:** 3  
**Status:** liberada para implementação (29/10/2026)  
**Dono:** técnico de integração; aceite de reception  
**Origem no escopo:** AG-06, DEC-06, RT-07, GATE-05; fluxos 13.3 e 13.4; §12.1 (`/available-hours`)  
**Degrau da solução:** reuso — cliente HTTP e catálogos espelhados; nenhuma gravação externa.

## Contexto e decisões fechadas

- `/available-hours` exige profissional e data e devolve uma lista de horários ("09:30", "17:00"); sem profissional responde 422.
- Só 5 dos 112 procedimentos têm profissional vinculado no Clínica Experts: a relação procedimento → profissionais precisa ser mantida aqui.
- 28 procedimentos têm duração zero; há de 78 a 96 bloqueios de agenda por mês, já considerados pela API.
- Decisão do cliente: no primeiro corte o agendamento é feito pela atendente no Clínica Experts.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

No ticket, a atendente escolhe procedimento e dia e vê os horários livres por profissional da clínica; copia a opção para a conversa, faz o agendamento no Clínica Experts, e ele aparece no ticket.

## Limites e dependências

- **Inclui:** relação procedimento → profissionais; função de contexto de agenda; painel de horários no ticket; agendamentos passados e futuros do paciente; vínculo do agendamento com a oportunidade.
- **Fora de escopo:** criar, confirmar, cancelar ou reagendar pelo sistema (P4-S02); escolha automática de horário; lembrete de consulta.
- **Entradas e pré-condições:** relação aprovada de procedimentos por profissional e intervalo padrão para procedimento sem duração (GATE-05). Esses valores não travam a construção: o agente constrói a configuração com um padrão marcado como rascunho e o cliente preenche ou confirma os valores reais no teste desta SPEC (última task).
- **Saídas/artefatos:** função `get-scheduling-context`, tabela de relação, painel de agenda, regra de vínculo.
- **Dependências e responsáveis:** P3-S01 (catálogos e agenda espelhada) e P2-S05 (ticket). Reception valida.
- **Risco e plano B:** horário mostrado já ter sido ocupado — o painel mostra a hora da consulta e a atendente confirma no Clínica Experts, que é a fonte.
- **Rollback ou reversão:** ocultar o painel por flag; a atendente consulta a agenda direto no Clínica Experts.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `GET /available-hours?professional_uuid=&date=` | Clínica Experts | lista de horários; `procedure_id` e `interval` opcionais |
| `GET /bookings?patient=&starts_at=&ends_at=` | Clínica Experts | agendamentos do paciente |
| Relação procedimento → profissionais | Supabase | configuração por clínica |

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P3-S04-01 | O sistema só lê: nenhuma chamada de gravação é emitida nesta SPEC. |
| RN-P3-S04-02 | A consulta é sob demanda, com memória de 2 minutos, e limitada a 20 chamadas por pedido. |
| RN-P3-S04-03 | Procedimento sem profissional relacionado mostra aviso e a lista de profissionais da clínica. |
| RN-P3-S04-04 | Procedimento com duração zero usa o intervalo padrão configurado. |
| RN-P3-S04-05 | O agendamento espelhado é ligado ao ticket e à oportunidade; a mudança automática para "avaliação agendada" entra com a lista de procedimentos de avaliação da P3-S06. |
| RN-P3-S04-06 | Reagendamento e cancelamento são feitos pela atendente; o painel só mostra os agendamentos do paciente. |

## Fluxo e regras

1. A atendente abre o painel de agenda no ticket e escolhe procedimento e dia.
2. O sistema resolve os profissionais da clínica para o procedimento.
3. Consulta os horários de cada um e mostra as opções com a hora da consulta.
4. A atendente copia a opção para a conversa e agenda no Clínica Experts.
5. O agendamento chega ao espelho e é ligado ao ticket e à oportunidade.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | procedimento com profissionais relacionados | horários livres por profissional iguais aos da API | opção copiada para a conversa |
| Limite | procedimento sem relação ou sem duração; dia sem horário | aviso claro e alternativa (outros profissionais ou outro dia) | atendente ajusta a busca |
| Falha | Clínica Experts indisponível | aviso e roteiro manual; ticket segue operável | nova tentativa sob demanda |

## Checklist de execução

- [ ] Relação procedimento → profissionais carregada.
- [ ] Cinco amostras de horários conferidas contra a API.
- [ ] Bloqueio de gravação conferido.
- [ ] Vínculo do agendamento com a oportunidade conferido.
- [ ] Reception validou o painel.

## Critérios de aceite

- [ ] **CA-P3-S04-01:** Os horários exibidos são iguais à resposta da API para o profissional e o dia, em cinco amostras.
- [ ] **CA-P3-S04-02:** Procedimento sem profissional relacionado mostra mensagem clara e a lista de profissionais da clínica.
- [ ] **CA-P3-S04-03:** Com o Clínica Experts indisponível, o painel avisa e mostra o roteiro manual, e o ticket segue operável.
- [ ] **CA-P3-S04-04:** Nenhuma chamada de gravação é emitida ao Clínica Experts; a lista de operações permitidas bloqueia qualquer tentativa.
- [ ] **CA-P3-S04-05:** Um agendamento criado no Clínica Experts aparece no ticket em até 15 minutos e fica ligado à oportunidade do contato.
- [ ] **CA-P3-S04-06:** Para paciente existente, o painel mostra agendamentos futuros e passados.
- [ ] **CA-P3-S04-07:** Cada pedido de horários usa no máximo 20 chamadas.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | painel sem horários | pedir horários de um procedimento | nada exibido: CA-P3-S04-01 falha | saída versionada do runner ou roteiro, anexada à task |
| GREEN | consulta e exibição | procedimento com relação; paciente existente | CA-P3-S04-01, CA-P3-S04-06 e CA-P3-S04-07 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | bordas, bloqueio e vínculo | sem relação; API fora do ar; tentativa de gravação; agendamento novo no espelho | CA-P3-S04-02 a CA-P3-S04-05 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** API simulada com horários e erros; conferência das cinco amostras contra a API real em ambiente autorizado.  
**Caminhos de erro obrigatórios:** 422 sem profissional, dia sem horário, timeout, procedimento sem relação, tentativa de gravação.  
**Evidência exigida:** tabela das cinco amostras, registro do bloqueio de gravação e aceite da recepção.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P3-S04-T01 | Criar a relação procedimento → profissionais e a função de contexto de agenda. | técnico de integração | CA-P3-S04-01, CA-P3-S04-02, CA-P3-S04-04, CA-P3-S04-07 | RED/GREEN da consulta; bloqueio de gravação | relatório do runner | P3-S01-T02 | 12/11/2026 | ☐ Liberada |
| P3-S04-T02 | Construir o painel de agenda no ticket com horários e agendamentos do paciente. | técnico de frontend | CA-P3-S04-01, CA-P3-S04-03, CA-P3-S04-06 | cenário principal e indisponibilidade | gravação do painel | T01; P2-S05-T03 | 12/11/2026 | ☐ Liberada |
| P3-S04-T03 | Ligar o agendamento espelhado ao ticket e à oportunidade, conferir as amostras e demonstrar com a recepção. | QA + reception | CA-P3-S04-01, CA-P3-S04-05 | REGRESSÃO e cinco amostras | tabela de amostras e aceite | T02; P3-S02-T02 | 13/11/2026 | ☐ Liberada |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| 2026-10-29 | Liberação da fase 3 | Pré-condições das tasks e teste do cliente | Valor que depende do cliente deixa de travar a construção: entra como rascunho e é confirmado no teste da SPEC, na última task, conforme o contrato comum (seção 8) |
