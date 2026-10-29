# P3-S02 — Funil comercial: leads, oportunidades e motivos de perda

**Fase:** 3  
**Status:** liberada para implementação (29/10/2026)  
**Dono:** técnico de implementação; aceite de sales e manager  
**Origem no escopo:** §7.4, §8.2, AG-07, RT-03, RT-08, GATE-06, GATE-07, GATE-17; fluxo 13.5  
**Degrau da solução:** construção mínima — o funil é próprio; componentes de quadro e formulário já instalados.

## Contexto e decisões fechadas

- GATE-17 reverificado em 13/10/2026: o módulo de CRM do Clínica Experts segue desabilitado (403). O caminho desta fase é o CRM próprio, com ganho comprovado pela venda espelhada.
- A origem do lead não existe no Clínica Experts (`origin` nulo em 2.180 de 2.181 cadastros): precisa ser capturada aqui.
- Processo comercial observado: Comercial 1 (primeiro contato até avaliação), Comercial 2 (não fechamento) e pós-venda.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

Um quadro por clínica em que cada lead novo vira oportunidade com dono, etapa e valor; mover para "perdido" exige motivo, e "ganho" exige venda vinculada ou confirmação do gestor.

## Limites e dependências

- **Inclui:** leads, funis, etapas, oportunidades, histórico e motivos de perda; funil padrão; criação a partir da conversa; quadro e ficha; regras de ganho e perda; sugestão de ganho pela venda espelhada; console do funil.
- **Fora de escopo:** gravar oportunidade no Clínica Experts; tarefas (P3-S03); cadências (P3-S05); previsão de receita.
- **Entradas e pré-condições:** etapas, responsáveis e motivos de perda aprovados (GATE-06, GATE-07); origens de lead aprovadas. Esses valores não travam a construção: o agente constrói a configuração com um padrão marcado como rascunho e o cliente preenche ou confirma os valores reais no teste desta SPEC (última task).
- **Saídas/artefatos:** tabelas do §7.4, função `upsert-opportunity`, telas de quadro, ficha e configuração do funil.
- **Dependências e responsáveis:** P2-S04 (conversa) e P3-S01 (vendas espelhadas). Sales e manager validam.
- **Risco e plano B:** equipe não registrar a etapa — a criação é automática a partir da conversa e a próxima ação é obrigatória (P3-S03).
- **Rollback ou reversão:** ocultar o quadro por flag; conversas e tickets seguem funcionando.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `leads`, `opportunities`, `opportunity_history` | Supabase | estados do §8.2; histórico imutável |
| `pipelines`, `pipeline_stages`, `loss_reasons` | Supabase | configuração versionada por clínica |
| `sales_mirror` | Supabase (espelho) | evidência de ganho |

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P3-S02-01 | Etapas: novo, qualificado, agendamento solicitado, avaliação agendada, avaliação realizada, ganho, perdido, em relacionamento. |
| RN-P3-S02-02 | Todo lead tem origem obrigatória (canal, campanha, indicação, orgânico ou outra aprovada). |
| RN-P3-S02-03 | Uma oportunidade aberta por contato e funil; a segunda é bloqueada com link para a existente. |
| RN-P3-S02-04 | "Perdido" exige motivo da lista; "ganho" exige venda espelhada vinculada ou aprovação do gestor. |
| RN-P3-S02-05 | Venda espelhada de um contato com oportunidade aberta gera sugestão de ganho; um humano confirma. |
| RN-P3-S02-06 | Toda mudança de etapa grava origem, destino, autor e motivo, sem edição posterior. |
| RN-P3-S02-07 | Vendedor vê as suas oportunidades; gestor vê todas as da clínica. |

## Fluxo e regras

1. A conversa de um novo lead cria lead e oportunidade na etapa inicial, com dono ou fila e origem.
2. A atendente move a oportunidade pelo quadro e registra valor e observações.
3. Mover para perdido pede o motivo; mover para ganho pede a venda ou a aprovação.
4. Uma venda espelhada dispara a sugestão de ganho.
5. O histórico mostra cada passagem de etapa.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | novo lead vindo da caixa de entrada | lead e oportunidade criados com dono, etapa e origem | histórico iniciado |
| Limite | oportunidade repetida, perda sem motivo, ganho sem venda | bloqueio com explicação no servidor | usuário corrige e segue |
| Falha | espelho de vendas desatualizado | ganho aceita aprovação do gestor e fica marcado "a conferir" | conferência diária vincula a venda depois |

## Checklist de execução

- [ ] Etapas, origens e motivos aprovados carregados por clínica.
- [ ] Criação a partir da conversa conferida.
- [ ] Regras de ganho e perda testadas pela API direta.
- [ ] Permissões por papel conferidas.
- [ ] Sales e manager validaram o quadro.

## Critérios de aceite

- [ ] **CA-P3-S02-01:** Um novo lead vindo da caixa de entrada cria lead e oportunidade na etapa inicial, com dono ou fila e origem obrigatória.
- [ ] **CA-P3-S02-02:** O funil é configurável por clínica (etapas, ordem, prazo e etapa final) pelo console, com versão.
- [ ] **CA-P3-S02-03:** Cada mudança de etapa grava histórico imutável com origem, destino, autor e motivo.
- [ ] **CA-P3-S02-04:** "Perdido" sem motivo é recusado pelo servidor; "ganho" exige venda espelhada vinculada ou aprovação do gestor.
- [ ] **CA-P3-S02-05:** Uma venda espelhada do mesmo paciente com oportunidade aberta gera sugestão de ganho, confirmada em um clique.
- [ ] **CA-P3-S02-06:** Uma segunda oportunidade aberta para o mesmo contato e funil é bloqueada.
- [ ] **CA-P3-S02-07:** Vendedor vê só as suas oportunidades, gestor vê as da clínica, e ninguém vê as de outra clínica pela tela ou pela API.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | lead sem oportunidade | abrir conversa de novo lead | nada criado: CA-P3-S02-01 falha | saída versionada do runner ou roteiro, anexada à task |
| GREEN | criação e movimentação | criar, mover e consultar histórico | CA-P3-S02-01 a CA-P3-S02-03 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | regras e permissões | perda sem motivo; ganho sem venda; repetição; venda espelhada; outro papel e outra clínica | CA-P3-S02-04 a CA-P3-S02-07 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** duas clínicas com funis diferentes; contatos e vendas espelhadas sintéticas; usuários por papel.  
**Caminhos de erro obrigatórios:** perda sem motivo, ganho sem evidência, repetição, etapa inexistente, usuário sem permissão.  
**Evidência exigida:** gravação do quadro, histórico de uma oportunidade e matriz de permissões.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P3-S02-T01 | Criar as tabelas do funil, o funil padrão e o console de etapas, origens e motivos. | técnico de banco + frontend | CA-P3-S02-02, CA-P3-S02-07 | configuração por clínica e permissão | capturas do console e matriz de acesso | P2-S04-T01 | 09/11/2026 | ☐ Liberada |
| P3-S02-T02 | Construir o quadro, a ficha da oportunidade e a criação a partir da conversa. | técnico de frontend | CA-P3-S02-01, CA-P3-S02-03 | cenário principal | gravação do quadro | T01 concluída | 09/11/2026 | ☐ Liberada |
| P3-S02-T03 | Implementar as regras de ganho, perda e repetição e a sugestão de ganho pela venda. | técnico de integração | CA-P3-S02-04, CA-P3-S02-05, CA-P3-S02-06 | bordas pela API direta | relatório do runner | T01; P3-S01-T02 | 10/11/2026 | ☐ Liberada |
| P3-S02-T04 | Executar a matriz de regras e permissões e demonstrar com o time comercial. | QA + sales | CA-P3-S02-03, CA-P3-S02-04, CA-P3-S02-06, CA-P3-S02-07 | REGRESSÃO completa | matriz e aceite | T02 e T03 concluídas | 10/11/2026 | ☐ Liberada |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| 2026-10-29 | Liberação da fase 3 | Pré-condições das tasks e teste do cliente | Valor que depende do cliente deixa de travar a construção: entra como rascunho e é confirmado no teste da SPEC, na última task, conforme o contrato comum (seção 8) |
