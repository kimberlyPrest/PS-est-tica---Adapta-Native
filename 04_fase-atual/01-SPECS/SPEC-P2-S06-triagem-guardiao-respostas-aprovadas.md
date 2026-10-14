# P2-S06 — Triagem automática, guardião de políticas e respostas aprovadas

**Fase:** 2  
**Status:** liberada para implementação (em paralelo ao fechamento da fase 1)  
**Dono:** técnico de IA; aceite do owner e do manager  
**Origem no escopo:** AG-01, AG-03, AG-04, AG-05, AG-13; §7.6; §14; RT-14; GATE-04; fluxo 13.1 (passos 10–11)  
**Degrau da solução:** construção mínima — um único ambiente de execução de agentes e um guardião determinístico, reutilizados por todos os agentes seguintes.

## Contexto e decisões fechadas

- Os quatorze agentes do escopo são papéis lógicos sobre um mesmo ambiente de execução, catálogo de ferramentas e guardião.
- Não há orientação clínica automática: preço, desconto, sintoma, foto e reclamação sempre vão para humano.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

Mensagem de baixo risco com resposta aprovada é respondida sozinha; preço, desconto, tema clínico, reclamação ou pedido de humano vão direto para a fila, com intenção e motivo registrados e visíveis no ticket.

## Limites e dependências

- **Inclui:** ambiente de execução de agentes; classificação de intenção em dez classes; guardião determinístico; resposta só com conteúdo aprovado; base de conhecimento e modelos de mensagem por provedor; tabela de rotas; interruptor por clínica; registro de cada execução com custo e duração.
- **Fora de escopo:** sugestão para a atendente (P2-S07); follow-up (fase 3); qualquer orientação clínica, avaliação de foto, promessa de resultado, preço não cadastrado ou desconto.
- **Entradas e pré-condições:** intenções, rotas, textos aprovados, horários e consentimento (GATE-04); chave do provedor de IA no Vault; política de não retenção do provedor (GATE-11).
- **Saídas/artefatos:** função `run-agent-job`, guardião, tabelas de agente e conhecimento, console de conhecimento, rotas e interruptores.
- **Dependências e responsáveis:** P2-S04 e P2-S05. Cliente aprova os textos; owner aprova o provedor de IA.
- **Risco e plano B:** classificação errada liberar resposta indevida — o guardião decide por regra, não por modelo, e falha fechada; a auto-resposta nasce desligada e é ligada por clínica.
- **Rollback ou reversão:** desligar o interruptor da clínica: tudo passa a ir para humano, sem afetar a outra clínica.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `agent_definitions`, `agent_clinic_configs` | Supabase | catálogo versionado e configuração por clínica |
| `agent_runs`, `agent_steps`, `agent_decisions` | Supabase | versão, passos, decisão, confiança, custo e duração; sem dado sensível |
| `knowledge_items`, `policy_rules`, `message_templates`, `feature_flags` | Supabase | conteúdo aprovado, regras, modelos e interruptores, todos versionados |
| Provedor de IA (Claude, via API) | provedor | chave no Vault; sem uso das conversas para treino |

## Contrato técnico detalhado

Segue o `00-CONTRATO-COMUM-FASE-2.md`. Esta SPEC cria o ambiente de execução de agentes reutilizado por todos os agentes seguintes (AG-01 a AG-14).

### Provedor de IA

| Item | Valor |
|---|---|
| API | Claude (Anthropic Messages API), chamada só de Edge Function |
| Chave | Vault, conexão `provider='anthropic'` no `/admin/conexoes` |
| Modelo da triagem | `claude-haiku-5-5` (configurável por clínica em `agent_clinic_configs.model_policy`) |
| Saída | JSON validado por schema (zod); resposta fora do schema = falha |
| Tempo limite | 15 s; 1 nova tentativa; depois caminho humano |
| Retenção | sem uso das conversas para treino; conta com política de retenção aprovada (GATE-11) |
| Dados enviados | últimas 10 mensagens da conversa (texto), clínica, identificação; **nunca** CPF, RG, endereço, e-mail, telefone completo |

### Tabelas novas

**`agent_definitions`** — `key` (`AG-01`…`AG-14`), `name`, `version`, `status` (`draft`, `published`), `tool_allowlist` text[], `max_autonomy` (`sugerir`, `responder_aprovado`), `output_schema` jsonb. Global (sem clínica); escrita só servidor/migration.

**`agent_clinic_configs`** — `organization_id`, `clinic_id` (nulo = padrão da organização), `agent_key`, `enabled` bool (padrão false), `model_policy` jsonb, `thresholds` jsonb (ex.: `{"confianca_min": 0.85}`), `budgets` jsonb (ex.: `{"custo_dia_centavos": 2000, "chamadas_dia": 3000}`), `prompt_version_id` uuid null (P2-S07), `version`, `status`. Valor efetivo: clínica → organização.

**`agent_runs`** — `organization_id`, `clinic_id`, `agent_key`, `agent_version`, `prompt_version_id`, `trigger_ref` (id do evento/mensagem), `status` (`queued`, `running`, `waiting_human`, `succeeded`, `failed`, `discarded`), `input_tokens`, `output_tokens`, `cost_cents`, `started_at`, `finished_at`, `error_code`, `correlation_id`. Sem texto de entrada ou saída.

**`agent_steps`** — imutável: `run_id`, `step`, `tool`, `status`, `duration_ms`, `error_code`.

**`agent_decisions`** — `run_id`, `decision_type` (`intent`, `route`, `reply`), `value` (ex.: `informacao_geral`), `confidence` numeric, `guard_effect` (`allow`, `require_human`, `deny`), `guard_reason`, `knowledge_item_id`, `human_outcome` (`sem_revisao`, `aceito`, `rejeitado`).

**`knowledge_items`** — `organization_id`, `clinic_id` (nulo = organização), `category` (`endereco`, `horario`, `como_chegar`, `contato`, `procedimento_info`, `outro`), `question_examples` text[], `answer` text, `auto_reply_allowed` bool, `status` (`draft`, `approved`, `archived`), `approved_by`, `approved_at`, `version`. Check do servidor ao aprovar com `auto_reply_allowed=true`: o texto não pode conter `R$`, número seguido de `%`, as palavras `desconto`, `promoção`, `garant`, `resultado`, `indicad`, nem nome de procedimento do catálogo — se contiver, a aprovação é recusada com o motivo.

**`policy_rules`** — `scope` (`global`, `clinic`), `clinic_id`, `rule_key`, `condition` jsonb, `effect` (`allow`, `require_human`, `deny`), `reason_code`, `priority`, `version`, `active`. Regras globais vêm por migration; a clínica só acrescenta regras mais restritivas.

**`message_templates`** — `organization_id`, `clinic_id`, `provider` (`meta_cloud`, `z_api`), `purpose` (`fora_expediente`, `espera`, `resposta_aprovada`, `followup`, `campanha`), `name`, `language` (`pt_BR`), `body` com variáveis `{{nome}}`, `{{clinica}}`, `contains_commercial_terms` bool (calculado pelo mesmo check do conhecimento), `external_template_id` (Meta), `provider_status` (`not_required`, `pending`, `approved`, `rejected`), `status`, `version`.

**`intent_routes`** — tabela de rotas por clínica: `clinic_id`, `intent`, `queue_id`, `priority`, `auto_reply_allowed` bool. Carga inicial:

| Intenção | Rota | Responde sozinho |
|---|---|---|
| `informacao_geral` | fila geral | **sim**, se houver item aprovado |
| `interesse_procedimento` | comercial | não |
| `preco_condicao` | comercial | não |
| `pedido_agendamento` | recepção | não |
| `reagendamento_cancelamento` | recepção | não |
| `pos_procedimento` | recepção, prioridade alta | não |
| `reclamacao` | gestor, prioridade alta | não |
| `financeiro` | recepção | não |
| `atendimento_humano` | fila geral | não |
| `desconhecido` | fila geral | não |

### Guardião (AG-13) — função pura `evaluateGuard(action, ctx)`

Regras globais, em ordem; a primeira que casar decide:

| # | Condição | Efeito | Motivo |
|---|---|---|---|
| 1 | conversa com `automation_paused` | `deny` | `transbordo_ativo` |
| 2 | interruptor `auto_resposta` desligado na clínica | `require_human` | `auto_resposta_desligada` |
| 3 | contato com recusa promocional e ação não é atendimento | `deny` | `recusa_do_contato` |
| 4 | fora do expediente da clínica | `require_human` | `fora_do_horario` |
| 5 | intenção sem `auto_reply_allowed` na rota | `require_human` | `intencao_exige_humano` |
| 6 | confiança abaixo de `confianca_min` | `require_human` | `baixa_confianca` |
| 7 | texto do contato menciona preço, desconto, sintoma, dor, foto, alergia, reação, reclamação (lista de termos versionada) | `require_human` | `tema_sensivel` |
| 8 | sem item de conhecimento aprovado com `auto_reply_allowed` | `require_human` | `sem_conteudo_aprovado` |
| 9 | resposta candidata difere do texto aprovado | `deny` | `texto_nao_aprovado` |
| 10 | orçamento diário de custo ou chamadas esgotado | `require_human` | `orcamento_esgotado` |
| — | nenhuma acima | `allow` | — |

Falha ao avaliar (erro, dado faltando) = `require_human`.

### `run-agent-job` (triagem — AG-01, AG-03, AG-04, AG-05)

1. Ler a mensagem e o contexto mínimo; registrar `agent_runs` (`running`).
2. Chamar a IA pedindo `{"intent": "...", "confidence": 0.0, "missing": [], "knowledge_item_id": "uuid|null"}`; a lista de itens aprovados da clínica vai no contexto como `id + perguntas exemplo` (sem o texto da resposta).
3. Validar a saída; inválida → `failed` e caminho humano.
4. Montar a ação candidata: resposta = **texto exato** do item aprovado.
5. `evaluateGuard`; `allow` → `outbound_requests` (`origin='auto_reply'`); outro efeito → `open_ticket` com `intent` e motivo.
6. Gravar `agent_decisions`, `agent_steps`, custo e duração.

Tempo total máximo: 30 s entre a mensagem recebida e o ticket ou a resposta.

### Telas

**`/admin/conhecimento`**: lista por categoria; editor com perguntas exemplo e resposta; aviso em tempo real se o texto contiver termos comerciais; fluxo rascunho → aprovar (owner/clinic_admin) → arquivar; aba "Modelos de mensagem" com a mesma regra e campo de situação na Meta.

**`/admin/agentes`** (parte desta SPEC): interruptor "Resposta automática" por clínica, limite de confiança, orçamento diário, tabela de rotas por intenção (fila, prioridade, responde sozinho — só `informacao_geral` pode ser marcada nesta fase).

**No ticket**: intenção e motivo do guardião em linguagem simples (ex.: "Enviado para a recepção: pedido de agendamento").

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P2-S06-01 | O guardião é determinístico e falha fechada: na dúvida, exige humano. |
| RN-P2-S06-02 | Classes: informação geral, interesse em procedimento, preço ou condição, pedido de agendamento, reagendamento ou cancelamento, pós-procedimento, reclamação, financeiro, atendimento humano, desconhecido. |
| RN-P2-S06-03 | Resposta automática só quando todas valem: interruptor ligado na clínica, classe na lista permitida, confiança acima do limite, conteúdo aprovado, horário permitido, sem recusa do contato e conversa não transbordada. |
| RN-P2-S06-04 | A lista inicial de resposta automática contém só "informação geral" (endereço, horário de funcionamento, como chegar e formas de contato). Interesse em procedimento, preço ou condição, pedido de agendamento, pós-procedimento, reclamação, financeiro, pedido de humano e desconhecido sempre transbordam. |
| RN-P2-S06-05 | A resposta usa somente o texto de um item de conhecimento aprovado, que não pode conter preço, indicação de procedimento nem promessa de resultado, e registra a fonte. |
| RN-P2-S06-06 | IA indisponível ou acima do tempo limite vira ticket; nunca resposta improvisada. |
| RN-P2-S06-07 | Depois do transbordo, nenhuma resposta automática até devolução explícita ou resolução. |

## Fluxo e regras

1. A mensagem nova gera um trabalho de triagem.
2. O agente classifica intenção e confiança e identifica dados faltantes.
3. O guardião avalia a ação candidata e devolve permitir, exigir humano ou negar, com código de motivo.
4. Permitido: a resposta aprovada entra na fila de saída. Caso contrário: ticket com intenção e motivo.
5. A execução grava versão, passos, decisão, custo e duração.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | pergunta de baixo risco com conteúdo aprovado e interruptor ligado | resposta aprovada enviada, com a fonte registrada | execução auditável |
| Limite | preço, desconto, sintoma, foto, reclamação, pedido de humano, fora do horário, contato que recusou | ticket com intenção e motivo; nenhuma resposta de conteúdo | atendente assume |
| Falha | IA fora do ar, lenta ou com resposta inválida | ticket em até 30 segundos; nenhuma resposta automática | alerta e nova tentativa só da classificação |

## Checklist de execução

- [ ] Textos, rotas e horários aprovados carregados por clínica.
- [ ] Chave do provedor de IA gravada no Vault.
- [ ] Conjunto de 20 mensagens de teste revisado pelo manager.
- [ ] Interruptor testado por clínica.
- [ ] Owner e manager validaram o resultado.

## Critérios de aceite

- [ ] **CA-P2-S06-01:** Em 20 mensagens de teste cobrindo as dez classes, pelo menos 18 caem na classe esperada e 100% das classes de risco são transbordadas.
- [ ] **CA-P2-S06-02:** Mensagens sobre preço, desconto, sintoma ou pós-procedimento, foto e reclamação nunca recebem resposta automática; o guardião registra o código do motivo.
- [ ] **CA-P2-S06-03:** Toda resposta automática usa somente o texto de um item de conhecimento aprovado, sem preço, indicação de procedimento nem promessa de resultado, e registra a fonte.
- [ ] **CA-P2-S06-04:** Com a IA fora do ar ou acima do tempo limite, um ticket é criado em até 30 segundos e nenhuma resposta automática é enviada.
- [ ] **CA-P2-S06-05:** Com o interruptor desligado numa clínica, 100% das mensagens dela vão para humano e a outra clínica não é afetada.
- [ ] **CA-P2-S06-06:** Cada execução tem registro com versão, passos, decisão, custo e duração, sem dado sensível.
- [ ] **CA-P2-S06-07:** Depois do transbordo, a conversa não recebe resposta automática até devolução explícita ou resolução.
- [ ] **CA-P2-S06-08:** Fora do horário permitido ou para contato que recusou mensagens, nenhuma resposta automática é enviada.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | mensagem de risco sem guardião | enviar mensagem de preço e de sintoma | sem bloqueio registrado: CA-P2-S06-02 falha | saída versionada do runner ou roteiro, anexada à task |
| GREEN | triagem e resposta aprovada | rodar as 20 mensagens de teste | CA-P2-S06-01 a CA-P2-S06-03 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | falha de IA, interruptor e pós-transbordo | simular queda e lentidão; desligar a clínica A; responder após transbordo; fora do horário; contato que recusou | CA-P2-S06-04 a CA-P2-S06-08 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** 20 mensagens sintéticas rotuladas (duas por classe); base de conhecimento de teste; provedor de IA simulado para falhas.  
**Caminhos de erro obrigatórios:** IA indisponível, tempo limite, resposta malformada, conteúdo sem aprovação, contato que recusou, fora do horário.  
**Evidência exigida:** tabela das 20 mensagens com classe e rota, registros de execução e aceite do owner e do manager.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P2-S06-T01 | Criar o ambiente de execução de agentes, as tabelas de registro e o guardião determinístico. | técnico de IA | CA-P2-S06-02, CA-P2-S06-06 | RED/GREEN do guardião | relatório do runner do guardião | P2-S04-T01; chave de IA no Vault | 29/10/2026 | ☐ Liberada |
| P2-S06-T02 | Implementar a triagem de intenção e a resposta com conteúdo aprovado. | técnico de IA | CA-P2-S06-01, CA-P2-S06-03, CA-P2-S06-07 | 20 mensagens de teste | tabela de classes e rotas | T01; P2-S05-T02 | 29/10/2026 | ☐ Liberada |
| P2-S06-T03 | Construir o console de conhecimento, modelos de mensagem, rotas e interruptores por clínica. | técnico de frontend | CA-P2-S06-03, CA-P2-S06-05 | mudança de conteúdo e interruptor | capturas e versão publicada | T01 concluída | 30/10/2026 | ☐ Liberada |
| P2-S06-T04 | Executar a matriz das 20 mensagens, as falhas de IA e a demonstração. | QA + manager | CA-P2-S06-01, CA-P2-S06-02, CA-P2-S06-04, CA-P2-S06-05, CA-P2-S06-07, CA-P2-S06-08 | REGRESSÃO completa | relatório e aceite | T02 e T03 concluídas | 30/10/2026 | ☐ Liberada |

## Roteiro das tasks

### P2-S06-T01 — Ambiente de agentes, tabelas e guardião
1. Migration com as tabelas, regras globais do guardião e RLS (leitura `is_clinic_member`; escrita de configuração `owner`/`clinic_admin`; execuções só servidor).
2. `evaluateGuard` como função pura com testes de cada regra e da falha fechada.
3. Conexão `anthropic` no `/admin/conexoes` com teste sanitizado.
**Pronto quando:** testes do guardião verdes (uma prova por regra).

### P2-S06-T02 — Triagem e resposta aprovada
1. `run-agent-job` com os seis passos e o schema de saída.
2. Conjunto de 20 mensagens sintéticas rotuladas (2 por intenção) em `scripts/fixtures/triagem-20.json`.
3. Rodar contra a IA real em ambiente de teste e registrar a tabela mensagem → intenção → rota → efeito.
4. Simular IA fora do ar, lenta e com JSON inválido.
**Pronto quando:** ≥ 18/20 corretas, 100% das intenções de risco transbordadas e falhas indo para humano em até 30 s.

### P2-S06-T03 — Console de conhecimento, modelos, rotas e interruptores
1. Telas `/admin/conhecimento` e a parte de `/admin/agentes` desta SPEC.
2. Check de termos comerciais na aprovação (servidor) e no editor (aviso).
3. Carregar os textos aprovados pela clínica (GATE-04): endereço, horários, como chegar e contatos de cada unidade.
**Pronto quando:** itens aprovados das duas clínicas publicados e aprovação recusada para texto com preço.

### P2-S06-T04 — Matriz e demonstração
1. Repetir as 20 mensagens com o interruptor ligado na clínica A e desligado na B.
2. Fora do horário, contato que recusou, conversa transbordada.
3. Demonstrar ao owner e ao gestor e registrar o aceite.
**Pronto quando:** relatório da matriz e "teste ok".

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| — | — | Nenhuma | SPEC inicial |
