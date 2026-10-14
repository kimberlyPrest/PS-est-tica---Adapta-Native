# P2-S07 — Copiloto da atendente e versões de prompt

**Fase:** 2  
**Status:** liberada para implementação (em paralelo ao fechamento da fase 1)  
**Dono:** técnico de IA; aceite das atendentes e do owner  
**Origem no escopo:** AG-14; §6.10 (agentes, prompts e conhecimento); console §6 e §7.3; RT-06, RT-20; GATE-15  
**Degrau da solução:** reuso — usa o ambiente de execução e o guardião da P2-S06; acrescenta sugestão, painel e ciclo de versão.

## Contexto e decisões fechadas

- A atendente continua autora da resposta: a sugestão não é mensagem enviada.
- Prompts e limites precisam ser ajustáveis por clínica sem alterar código.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

No ticket, a atendente vê resumo, motivo do contato, identificação e uma sugestão de resposta; ela usa, edita ou descarta, e nada sai sem o clique dela. O administrador publica uma nova versão de prompt e volta à anterior.

## Limites e dependências

- **Inclui:** função de sugestão; painel lateral do ticket; registro de uso; console de agentes e prompts com rascunho, teste, publicação e volta à versão anterior; herança organização → clínica; indicador de aceitação.
- **Fora de escopo:** envio automático da sugestão; treino de modelo com dado de paciente; edição livre de regra do guardião.
- **Entradas e pré-condições:** administradores e política de publicação aprovados (GATE-15); prompts iniciais do pacote de setup (persona e tom da PS Estética).
- **Saídas/artefatos:** funções `ticket-suggest-action` e `approve-agent-action`, funções de publicação e volta de versão, painel do copiloto, console de prompts.
- **Dependências e responsáveis:** P2-S05 e P2-S06. Atendentes validam o painel; owner valida a publicação.
- **Risco e plano B:** sugestão inadequada ser enviada sem leitura — toda sugestão passa pelo guardião e exige ação explícita; o painel mostra as evidências usadas.
- **Rollback ou reversão:** desligar o copiloto por clínica: o ticket mostra contexto local e a lista manual de conferência.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `ai_suggestions` | Supabase | ticket, execução, tipo, conteúdo, confiança, situação, revisor, conteúdo editado |
| `prompt_sets`, `prompt_versions` | Supabase | versões imutáveis, variáveis permitidas, aprovador, data de publicação |
| `config_audit_logs`, `config_change_requests` | Supabase | antes e depois sanitizados, motivo, autor e aprovação |

## Contrato técnico detalhado

Segue o `00-CONTRATO-COMUM-FASE-2.md`. Reusa o ambiente de agentes, o guardião e a conexão de IA da P2-S06.

### Provedor de IA

| Item | Valor |
|---|---|
| Modelo do copiloto | `claude-sonnet-5-5` (configurável por clínica) |
| Tempo limite | 25 s; 1 nova tentativa |
| Contexto enviado | últimas 30 mensagens da conversa, identificação (nome e situação do paciente, sem documentos), intenção, motivo do transbordo, itens de conhecimento aprovados da clínica, regras do guardião em linguagem simples |
| Saída (schema) | `{"resumo": "...", "motivo": "...", "resposta_sugerida": "...", "proxima_acao": "...", "dados_faltantes": ["..."], "sinal_de_risco": "nenhum|baixo|alto", "evidencias": [{"tipo": "mensagem|conhecimento", "ref": "id"}], "confianca": 0.0}` |

### Tabelas novas

**`ai_suggestions`**

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid PK | |
| `organization_id`, `clinic_id`, `ticket_id`, `conversation_id` | uuid not null | |
| `agent_run_id` | uuid not null | FK `agent_runs` |
| `kind` | text | `resumo_e_resposta` |
| `content` | jsonb | saída validada, depois do guardião |
| `confidence` | numeric | |
| `guard_effect`, `guard_reason` | text | |
| `status` | text | `generated`, `blocked`, `used`, `edited`, `discarded`, `expired` |
| `edited_content` | text null | texto efetivamente enviado quando editado |
| `reviewed_by`, `reviewed_at` | uuid, timestamptz | |
| `message_id` | uuid null | mensagem enviada a partir da sugestão |

Sugestão expira quando chega mensagem nova do contato (o painel oferece "gerar de novo").

**`prompt_sets`** — `organization_id`, `clinic_id` (nulo = organização), `agent_key`, `name`, `active_version_id`.

**`prompt_versions`** — imutável depois de publicada: `prompt_set_id`, `version` int, `content` text, `allowed_variables` text[] (ex.: `clinica`, `nome_contato`, `horario_clinica`), `status` (`draft`, `in_review`, `published`, `archived`), `sandbox_result` jsonb (resultado do teste com conversas sintéticas), `created_by`, `approved_by`, `published_at`.

**`config_change_requests`** — `scope`, `entity_type` (`prompt_version`, `agent_clinic_config`), `entity_id`, `requested_by`, `approved_by`, `status` (`pending`, `approved`, `rejected`), `reason`. Segundo aprovador exigido quando a política do GATE-15 mandar.

### Guardião na sugestão

Antes de exibir, `resposta_sugerida` passa por `evaluateGuard` (P2-S06) com regras específicas: contém preço (`R$`, número + `%`), desconto, diagnóstico ou nome de doença, promessa (`garant`, `resultado certo`), avaliação de foto → `blocked`; o painel mostra "Sugestão bloqueada: <motivo>" e mantém resumo e próxima ação. Sinal de risco `alto` → aviso vermelho no topo do painel.

### Funções

| Função | Quem | Entrada | Saída |
|---|---|---|---|
| `ticket-suggest-action` | membro da clínica do ticket | `{"ticket_id": "uuid"}` | `{"data": {"suggestion_id", "resumo", "motivo", "resposta_sugerida" ou null, "bloqueio" ou null, "proxima_acao", "dados_faltantes", "evidencias", "confianca"}}` |
| `approve-agent-action` | autor da ação no ticket | `{"suggestion_id", "action": "use|edit|discard", "edited_text"?}` | `use`/`edit` chamam `send_human_message` com o texto (autor = atendente) e gravam o resultado |
| `admin-publish-agent-version` | owner ou aprovador do GATE-15 | `{"prompt_version_id"}` | exige `sandbox_result.ok = true` e, se a política pedir, `config_change_requests` aprovado |
| `admin-rollback-agent-version` | idem | `{"prompt_set_id", "to_version"}` | reativa a versão anterior, arquiva a atual, registra auditoria |
| `admin-sandbox-test` | owner, clinic_admin | `{"prompt_version_id"}` | roda 10 conversas sintéticas fixas e grava `sandbox_result` (taxa de saída válida, bloqueios do guardião, tempo médio) |

### Herança e permissão

| Item | Regra |
|---|---|
| Valor efetivo | versão publicada da clínica; se não houver, a da organização |
| Tela | mostra "Herdado da organização" ou "Próprio da clínica" ao lado de cada valor |
| Escrita | `owner` (organização e clínicas); `clinic_admin` só a própria clínica |
| Leitura | membros da clínica leem só a configuração efetiva da própria clínica; usuário sem vínculo recebe 403 pela tela e pela API |

### Telas

**Painel do copiloto** (lateral direita em `/atendimento/:conversationId`, abaixo do ticket)

| Bloco | Conteúdo |
|---|---|
| Resumo | 3 a 5 linhas |
| Motivo e identificação | motivo do contato; paciente/novo lead/ambíguo com a confiança do vínculo |
| Resposta sugerida | texto + botões **Usar**, **Editar e enviar**, **Descartar**; nenhum botão envia sem clique explícito |
| Próxima ação | texto + botão "Criar tarefa" (desabilitado até a fase 3, com dica) |
| Dados faltantes | lista |
| Evidências | links para as mensagens e itens de conhecimento usados |
| Indisponível | "Sugestões indisponíveis no momento" + lista manual: confirmar nome, confirmar unidade, entender o interesse, oferecer agendamento com a recepção |

**`/admin/agentes`** (complementa a P2-S06): por agente e clínica — modelo, limites, orçamento, interruptor do copiloto; aba "Instruções" com editor do prompt, variáveis permitidas, botão "Testar no sandbox", comparação lado a lado com a versão publicada, "Enviar para aprovação", "Publicar", "Voltar para a versão N".

**Indicador de uso** (na visão do gestor `/filas`): sugestões geradas, usadas, editadas, descartadas e bloqueadas por clínica e período.

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P2-S07-01 | Gerar não envia: só "usar" ou "editar e enviar" colocam a mensagem na fila de saída. |
| RN-P2-S07-02 | Toda sugestão passa pelo guardião antes de aparecer. |
| RN-P2-S07-03 | Aceita, editada e rejeitada ficam registradas; conversas não treinam modelo externo. |
| RN-P2-S07-04 | Publicar cria versão imutável; editar depois cria nova versão; voltar reativa a anterior com auditoria. |
| RN-P2-S07-05 | O valor efetivo mostra de onde vem (organização ou clínica); a exceção de uma clínica não altera a outra. |
| RN-P2-S07-06 | Sem IA, sem Clínica Experts ou sem conhecimento, o painel mostra contexto local e a lista manual; o ticket segue operável. |

## Fluxo e regras

1. A atendente abre o ticket; o painel pede a sugestão.
2. O agente monta resumo, motivo, identificação, resposta recomendada, próxima ação e evidências.
3. O guardião valida; o painel exibe com as ações usar, editar, descartar e ver evidências.
4. A escolha da atendente é registrada; usar ou editar envia pela conta de origem.
5. O administrador edita o prompt em rascunho, testa com dado sintético, publica e, se preciso, volta à versão anterior.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | ticket aberto com contexto disponível | resumo e sugestão em até 10 segundos; envio só após ação | uso registrado |
| Limite | sugestão com conteúdo proibido, ou prompt incompleto | sugestão barrada; rascunho não publica | aviso com o motivo |
| Falha | IA ou Clínica Experts indisponível | contexto local e lista manual; ticket operável | nova tentativa sob demanda |

## Checklist de execução

- [ ] Prompts iniciais revisados com o tom da PS Estética.
- [ ] Painel testado pelas atendentes em tickets de teste.
- [ ] Publicação e volta de versão demonstradas.
- [ ] Herança entre clínicas conferida.
- [ ] Demonstração ponta a ponta da fase 2 registrada.

## Critérios de aceite

- [ ] **CA-P2-S07-01:** Ao abrir o ticket, o painel mostra resumo, motivo, identificação e sugestão com evidências em até 10 segundos.
- [ ] **CA-P2-S07-02:** "Gerar" nunca envia; só "usar" ou "editar e enviar" enviam, e cada ação fica registrada como aceita, editada ou rejeitada.
- [ ] **CA-P2-S07-03:** Uma sugestão com preço, desconto, diagnóstico, promessa de resultado ou avaliação de foto é barrada pelo guardião antes de aparecer.
- [ ] **CA-P2-S07-04:** Com IA ou Clínica Experts indisponível, o painel mostra contexto local e a lista manual, e o ticket segue operável.
- [ ] **CA-P2-S07-05:** Publicar um prompt cria versão imutável após teste com dado sintético; voltar reativa a versão anterior com auditoria.
- [ ] **CA-P2-S07-06:** A configuração da clínica A não altera a clínica B, a tela mostra a origem do valor efetivo, e usuário sem vínculo não lê prompt nem configuração de outra clínica pela tela ou pela API.
- [ ] **CA-P2-S07-07:** O indicador de uso mostra as taxas de aceitação, edição e rejeição por clínica.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | ticket sem sugestão | abrir ticket de teste | painel vazio: CA-P2-S07-01 falha | saída versionada do runner ou roteiro, anexada à task |
| GREEN | sugestão e ações da atendente | gerar, usar, editar e descartar | CA-P2-S07-01, CA-P2-S07-02 e CA-P2-S07-07 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | guardião, indisponibilidade, versões e herança | sugestão proibida; IA fora do ar; publicar e voltar; alterar só a clínica A | CA-P2-S07-03 a CA-P2-S07-06 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** tickets sintéticos por classe de intenção; prompts de teste; provedor de IA simulado.  
**Caminhos de erro obrigatórios:** IA indisponível, sugestão proibida, variável de prompt não permitida, publicação sem aprovação.  
**Evidência exigida:** gravação do painel, histórico de versões, indicador de uso e aceite das atendentes.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P2-S07-T01 | Implementar a função de sugestão com evidências e o registro de uso. | técnico de IA | CA-P2-S07-01, CA-P2-S07-03 | RED/GREEN da sugestão | relatório do runner | P2-S06-T01; P2-S05-T01 | 03/11/2026 | ☐ Liberada |
| P2-S07-T02 | Construir o painel do copiloto no ticket com usar, editar, descartar e ver evidências. | técnico de frontend | CA-P2-S07-01, CA-P2-S07-02, CA-P2-S07-04 | cenário principal e indisponibilidade | gravação do painel | T01; P2-S05-T03 | 03/11/2026 | ☐ Liberada |
| P2-S07-T03 | Construir o console de agentes e prompts com rascunho, teste, publicação, volta de versão e herança. | técnico de frontend + IA | CA-P2-S07-05, CA-P2-S07-06, CA-P2-S07-07 | ciclo de versão e herança | histórico de versões e capturas | T01 concluída | 04/11/2026 | ☐ Liberada |
| P2-S07-T04 | Executar a matriz do copiloto e a demonstração ponta a ponta da fase 2 com as atendentes. | QA + atendentes | CA-P2-S07-02, CA-P2-S07-03, CA-P2-S07-04, CA-P2-S07-06 | REGRESSÃO completa e roteiro mensagem → ticket → resposta | relatório e aceite das atendentes | T02 e T03; SPECs P2-S03 a P2-S06 concluídas | 04/11/2026 | ☐ Liberada |

## Roteiro das tasks

### P2-S07-T01 — Função de sugestão e registro
1. Migration de `ai_suggestions`, `prompt_sets`, `prompt_versions`, `config_change_requests` com RLS.
2. Prompt inicial do copiloto (tom da PS Estética, do pacote de setup) como versão 1 publicada da organização.
3. `ticket-suggest-action` com schema, guardião e evidências.
4. `deno test`: saída válida, saída inválida, sugestão com preço bloqueada, IA fora do ar.
**Pronto quando:** testes verdes e tempo médio abaixo de 10 s em 10 tickets sintéticos.

### P2-S07-T02 — Painel do copiloto
1. Painel com os blocos acima e o estado indisponível.
2. `approve-agent-action` ligado a `send_human_message`.
3. Testes de tela: "Gerar" não cria mensagem; "Usar" cria uma; "Editar" grava o texto editado; "Descartar" não envia.
**Pronto quando:** testes verdes e gravação do painel.

### P2-S07-T03 — Console de prompts, sandbox, publicação e volta
1. Editor, sandbox, comparação, aprovação, publicação e volta de versão.
2. Herança com indicação da origem do valor.
3. Runner: publicar sem sandbox é recusado; voltar reativa a anterior; alteração da clínica A não muda a B; usuário sem vínculo recebe 403.
**Pronto quando:** runner verde e histórico de versões com uma volta registrada.

### P2-S07-T04 — Demonstração ponta a ponta da fase 2
1. Roteiro: mensagem real no número de teste → identificação → triagem → ticket na fila certa → atendente assume → copiloto sugere → atendente edita e envia → situação "lido" → resolve com próxima ação.
2. Repetir com a IA desligada (lista manual aparece, atendimento segue).
3. Registrar o aceite das atendentes e do owner; atualizar `STATUS.md` com a fase 2 concluída.
**Pronto quando:** roteiro "teste ok" assinado pelas atendentes.

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| — | — | Nenhuma | SPEC inicial |
