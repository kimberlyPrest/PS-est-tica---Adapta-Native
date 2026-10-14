# P2-S04 — Conversas e caixa de entrada em tempo real

**Fase:** 2  
**Status:** liberada para implementação (em paralelo ao fechamento da fase 1)  
**Dono:** técnico de implementação; aceite de reception/sales  
**Origem no escopo:** §7.2, §8.1, §6.5, §6.9, fluxo 13.1, RT-04, RT-17; console §7.1–7.2  
**Degrau da solução:** nativo da plataforma — Realtime e Storage do Supabase; componentes de interface já instalados no repositório.

## Contexto e decisões fechadas

- O repositório não tem tela de atendimento; `contacts` e `contact_identities` existem desde a P1-S01.
- A identificação do contato usa a busca da P2-S02 e precisa tolerar a indisponibilidade do Clínica Experts.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

Cada mensagem recebida aparece em segundos na caixa de entrada da clínica certa, dentro da conversa do contato, com o selo paciente, novo lead ou ambíguo, e a atendente responde pela própria tela.

## Limites e dependências

- **Inclui:** conversas, mensagens, anexos e linha do tempo; consumidor da fila de entrada; identificação do contato; caixa de entrada e conversa em tempo real; envio de resposta; consentimento e saída da lista por palavra-chave.
- **Fora de escopo:** fila, prazo e distribuição (P2-S05); resposta automática (P2-S06); sugestão de IA (P2-S07).
- **Entradas e pré-condições:** eventos normalizados da P2-S03; lista aprovada de tipos de anexo e palavras de saída (GATE-04).
- **Saídas/artefatos:** tabelas de conversa, função `process-inbound-event`, telas de caixa de entrada e conversa, bucket privado.
- **Dependências e responsáveis:** P2-S02 e P2-S03. Reception/sales validam a tela.
- **Risco e plano B:** canal em tempo real vazar conversa entre clínicas — canais privados por clínica com autorização no banco; teste negativo obrigatório.
- **Rollback ou reversão:** ocultar a caixa de entrada por flag; os eventos continuam sendo gravados para reprocessar.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `conversations`, `messages`, `message_attachments`, `conversation_events` | Supabase | campos do §7.2; estados do §8.1 |
| `contacts`, `contact_identities`, `consents` | Supabase | contato localizado pela identidade do canal (`contact_identities`); telefone não é único por pessoa; consentimento por canal e finalidade |
| Realtime | Supabase | canal privado por clínica; autorização por vínculo |
| Storage | Supabase | bucket privado por organização e clínica; URL assinada temporária |

## Contrato técnico detalhado

Segue o `00-CONTRATO-COMUM-FASE-2.md`. Usa `contacts` e `contact_identities` da P1-S01 sem alterar suas chaves (telefone **não** é único por pessoa).

### Tabelas novas

**`conversations`**

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid PK | |
| `organization_id`, `clinic_id` | uuid not null | clínica = clínica da conta de canal |
| `contact_id` | uuid not null | FK `contacts` |
| `channel_account_id` | uuid not null | FK `channel_accounts`; nunca muda |
| `status` | text not null | `new`, `triaging`, `waiting_human`, `in_human_service`, `waiting_customer`, `resolved`, `blocked`, `spam`, `opted_out`, `integration_error` |
| `identification` | text not null default `pendente` | `pendente`, `paciente`, `novo_lead`, `ambiguo`, `provavel`, `indisponivel` |
| `expert_patient_uuid` | uuid null | só após vínculo confirmado |
| `owner_user_id` | uuid null | |
| `team_id` | uuid null | |
| `automation_paused` | boolean not null default false | true após transbordo (P2-S05) |
| `last_inbound_at`, `last_outbound_at`, `last_message_at`, `next_action_at` | timestamptz | `last_inbound_at` define a janela de 24 h da Meta |
| `unread_count` | int not null default 0 | |

Única parcial: uma conversa **aberta** (`status not in ('resolved','spam')`) por `(contact_id, channel_account_id)`. Check: `owner_user_id is not null or team_id is not null or status in ('new','triaging','resolved','spam','opted_out')`.

**`messages`**

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid PK | |
| `organization_id`, `clinic_id`, `conversation_id` | uuid not null | |
| `direction` | text not null | `inbound`, `outbound` |
| `sender_type` | text not null | `contact`, `user`, `agent`, `system`, `device` |
| `sender_user_id` | uuid null | autor humano |
| `provider` | text not null | provedor real da mensagem |
| `provider_message_id` | text null | |
| `content_type` | text not null | `text`, `image`, `audio`, `video`, `document`, `sticker`, `location`, `unsupported` |
| `body` | text null | texto; nunca vai para log |
| `status` | text not null | `received`, `queued`, `sent`, `delivered`, `read`, `failed`, `blocked` |
| `outbound_request_id` | uuid null | FK `outbound_requests` (P2-S03) |
| `sent_at`, `delivered_at`, `read_at` | timestamptz | atualizados por `provider_message_status` |
| `occurred_at` | timestamptz not null | horário do provedor |

Única parcial `(provider, provider_message_id)` quando não nulo — é o que impede mensagem duplicada.

**`message_attachments`** — `message_id`, `storage_path` (`attachments/<org>/<clinic>/<conversation>/<uuid>`), `mime_declared`, `mime_detected`, `size_bytes`, `sha256`, `scan_status` (`pending`, `clean`, `rejected`), `reject_reason`. Tipos permitidos (GATE-04): `image/jpeg`, `image/png`, `image/webp`, `application/pdf`, `audio/ogg`, `audio/mpeg`; máximo 16 MB.

**`conversation_events`** — imutável: `conversation_id`, `event_type` (`created`, `status_changed`, `identified`, `assigned`, `opt_out`, `attachment_rejected`, `message_blocked`…), `actor_type` (`system`, `user`, `agent`), `actor_id`, `payload_sanitized` jsonb (sem texto de mensagem), `occurred_at`.

**`consents`** — `organization_id`, `contact_id`, `channel` (`whatsapp`), `purpose` (`atendimento`, `promocional`), `status` (`granted`, `revoked`), `source` (`palavra_chave`, `atendente`, `importacao`), `captured_at`, `captured_by`. Valor vigente = registro mais recente por `(contact_id, channel, purpose)`.

### RLS

| Tabela | select | insert | update | delete |
|---|---|---|---|---|
| `conversations` | `is_clinic_member(clinic_id)` | servidor | membro da clínica só pelos RPCs de atribuição/estado | ninguém |
| `messages` | `is_clinic_member(clinic_id)` | servidor (envio humano passa pelo RPC `send_human_message`) | servidor | ninguém |
| `message_attachments` | `is_clinic_member` via conversa | servidor | servidor | ninguém (retenção na P5-S04) |
| `conversation_events` | `is_clinic_member` | servidor | ninguém | ninguém |
| `consents` | `is_org_member(organization_id)` | servidor e RPC `register_consent` | ninguém (novo registro substitui) | ninguém |

Storage `attachments`: leitura só por URL assinada de 5 min gerada pelo servidor após checar `is_clinic_member`.

Realtime: canal privado `clinic:<clinic_id>`; autorização por `realtime.messages` com policy `is_clinic_member`. Publica apenas `{tipo, conversation_id, message_id}` — o conteúdo é lido pela API com RLS.

### Consumidor `process-inbound-event` (completa o da P2-S03)

1. Ler o recibo e o evento normalizado; resolver `channel_account` → clínica.
2. Localizar contato por `contact_identities(channel='whatsapp', external_id=<telefone E.164>)` dentro da organização. Mais de um contato com a mesma identidade → usar o mais recente e registrar evento `contato_ambiguo` (sem fundir contatos).
3. Sem contato: criar `contacts` (`name` = nome exibido no WhatsApp, `primary_phone_e164`) e `contact_identities`.
4. Abrir ou reaproveitar a conversa aberta; gravar a mensagem com `on conflict do nothing` pela chave do provedor.
5. Conversa nova → chamar a identificação (P2-S02) uma vez; resultado em `identification`; erro → `indisponivel` e segue.
6. Palavras de saída (GATE-04; padrão: `sair`, `parar`, `cancelar inscrição`, `não quero receber`) → `consents(promocional, revoked)` e evento `opt_out`.
7. Mídia: baixar do provedor (Meta: `GET /<media-id>` e depois a URL com o token; Z-API: URL do corpo), conferir tipo real pelos primeiros bytes, tamanho e antivírus (ClamAV em função dedicada ou serviço de varredura aprovado); aprovado → bucket; reprovado → `rejected` + evento.
8. Atualizar contadores, `last_inbound_at`, publicar no Realtime e enfileirar `agent_jobs` (consumido na P2-S06; até lá, fica parado sem efeito).

### Envio humano — RPC `send_human_message(conversation_id, body)`

1. Checa `is_clinic_member` e se a conversa está aberta.
2. Cria `messages` (`outbound`, `user`, `queued`) e `outbound_requests` (`origin='human'`) com a conta da conversa.
3. **Conferência de recusa:** origem `human` em conversa aberta pelo próprio contato passa (atendimento); qualquer origem automática ou promocional para contato com `promocional=revoked` é bloqueada com `recusa_do_contato` — regra aplicada em `enqueue-outbound-message` para todas as origens.
4. Janela da Meta fechada → resposta 422 `regra_de_negocio` com a mensagem "Fora da janela de 24 h: use um modelo aprovado".

### Telas

**`/atendimento`** (caixa de entrada)

| Elemento | Detalhe |
|---|---|
| Lista | contato (nome ou telefone mascarado), selo de identificação, prévia de 80 caracteres, horário, não lidas, situação, responsável ou fila |
| Filtros | minhas, da minha equipe, sem responsável, aguardando cliente, resolvidas (7 dias) |
| Ordenação | última mensagem, mais recente primeiro |
| Tempo real | nova mensagem sobe a conversa e incrementa não lidas sem recarregar |
| Clínica | só a selecionada no seletor |

**`/atendimento/:conversationId`**

| Área | Detalhe |
|---|---|
| Cabeçalho | contato, telefone mascarado (botão "mostrar" registra evento), selo de identificação com ação "Identificar" (abre a busca da P2-S02 com o telefone preenchido), número e provedor de origem |
| Histórico | mensagens com situação (✓ enviado, ✓✓ entregue, lido), anexos por URL temporária, eventos do sistema em cinza |
| Resposta | caixa de texto; Enter envia; aviso de janela da Meta; botão "Usar modelo" (lista modelos aprovados da P2-S06) |
| Lateral | reservada para ticket (P2-S05) e copiloto (P2-S07) |

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P2-S04-01 | Uma conversa aberta por contato e por conta de canal; nova mensagem entra na conversa aberta. |
| RN-P2-S04-02 | A identificação é chamada uma vez por conversa nova, com cache; falha da identificação mostra "indisponível" e não bloqueia a conversa. |
| RN-P2-S04-03 | Toda conversa aberta tem responsável ou fila; nunca fica sem os dois. |
| RN-P2-S04-04 | As palavras de saída aprovadas registram a recusa de mensagens promocionais para aquele contato e canal. |
| RN-P2-S04-05 | Anexo só de tipo permitido, com conferência do tipo real do arquivo e verificação de vírus antes de liberar; fora da lista é recusado com aviso; o acesso é por URL temporária. |
| RN-P2-S04-06 | Toda mensagem de saída, de qualquer origem, passa pela conferência de recusa ao entrar na fila: mensagem automática ou promocional para quem recusou é bloqueada com motivo; resposta humana em conversa aberta pelo próprio contato segue a política aprovada e fica registrada. |
| RN-P2-S04-07 | Toda mudança de estado grava um evento imutável na linha do tempo. |

## Fluxo e regras

1. O consumidor lê o evento, resolve conta e clínica e cria ou atualiza o contato.
2. Abre ou reaproveita a conversa e grava a mensagem.
3. Chama a identificação e grava o selo.
4. Publica a mudança no canal privado da clínica; a caixa de entrada atualiza sem recarregar.
5. A atendente responde; a mensagem entra na fila de saída pela conta de origem.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | mensagem nova de número desconhecido | contato, conversa e mensagem na clínica do número; visível em até 5 segundos | selo conforme a identificação |
| Limite | segunda mensagem, evento repetido, palavra de saída, anexo não permitido | mesma conversa; sem duplicar; recusa registrada; anexo recusado | linha do tempo registra cada caso |
| Falha | Clínica Experts ou Realtime indisponível | conversa criada com selo "indisponível"; a tela recupera ao reconectar | nova tentativa de identificação sob demanda |

## Checklist de execução

- [ ] Tipos de anexo e palavras de saída aprovados carregados.
- [ ] Caixa de entrada testada por duas clínicas em paralelo.
- [ ] Teste negativo de isolamento por tela, API e Realtime.
- [ ] Envio e situação conferidos em número real de teste.
- [ ] Reception/sales validaram a tela.

## Critérios de aceite

- [ ] **CA-P2-S04-01:** Uma mensagem recebida cria ou atualiza contato, conversa e mensagem na clínica do número e aparece para um membro daquela clínica em até 5 segundos, sem recarregar.
- [ ] **CA-P2-S04-02:** A segunda mensagem do mesmo contato entra na mesma conversa aberta e um evento repetido não duplica mensagem.
- [ ] **CA-P2-S04-03:** O selo reflete a identificação (paciente, novo lead, ambíguo ou indisponível) e a queda do Clínica Experts não impede a conversa.
- [ ] **CA-P2-S04-04:** A atendente envia texto pela tela; a mensagem sai pela conta de origem e mostra a situação de entrega.
- [ ] **CA-P2-S04-05:** Membro de outra clínica não vê a conversa pela tela, pela API direta nem pelo canal em tempo real.
- [ ] **CA-P2-S04-06:** A palavra de saída registra a recusa; anexo fora da lista ou reprovado na conferência de tipo e de vírus é recusado; anexo aceito abre por URL temporária.
- [ ] **CA-P2-S04-07:** Toda mudança de estado gera evento imutável na linha do tempo.
- [ ] **CA-P2-S04-08:** Uma mensagem automática ou promocional para contato que recusou é bloqueada na entrada da fila de saída, com o motivo registrado.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | mensagem recebida sem conversa | enfileirar evento normalizado e abrir a caixa de entrada | nada aparece: CA-P2-S04-01 falha | saída versionada do runner ou roteiro, anexada à task |
| GREEN | consumidor, tela e envio | mensagem de entrada e resposta pela tela | CA-P2-S04-01 a CA-P2-S04-04 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | isolamento e bordas | duas clínicas em paralelo; repetição; saída; anexo; Clínica Experts fora do ar; envio automático para quem recusou | CA-P2-S04-05 a CA-P2-S04-08 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** duas clínicas sintéticas com um número cada; contatos e mensagens sintéticos; arquivos de teste permitidos e não permitidos.  
**Caminhos de erro obrigatórios:** repetição, número não mapeado, identificação indisponível, anexo inválido, usuário sem vínculo, queda do Realtime.  
**Evidência exigida:** gravação curta da caixa de entrada em duas clínicas, relatório do runner e matriz de isolamento.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P2-S04-T01 | Criar as tabelas de conversa com isolamento por clínica e o consumidor da fila de entrada. | técnico de banco + integração | CA-P2-S04-01, CA-P2-S04-02, CA-P2-S04-07 | RED/GREEN do evento de entrada | relatório do runner | P2-S03-T01 | 22/10/2026 | ☐ Liberada |
| P2-S04-T02 | Construir a caixa de entrada e a conversa em tempo real, com envio de resposta e situação. | técnico de frontend | CA-P2-S04-01, CA-P2-S04-04 | cenário principal em tela | gravação da tela | T01 concluída | 23/10/2026 | ☐ Liberada |
| P2-S04-T03 | Ligar a identificação do contato, a saída da lista por palavra-chave e os anexos privados. | técnico de integração | CA-P2-S04-03, CA-P2-S04-06, CA-P2-S04-08 | bordas de identificação, saída, anexo e recusa | relatório do runner | T01; P2-S02-T02 | 26/10/2026 | ☐ Liberada |
| P2-S04-T04 | Executar a matriz de isolamento e repetição e demonstrar a caixa de entrada em duas clínicas. | QA + reception | CA-P2-S04-02, CA-P2-S04-05, CA-P2-S04-07 | REGRESSÃO completa | matriz e aceite da recepção | T02 e T03 concluídas | 26/10/2026 | ☐ Liberada |

## Roteiro das tasks

### P2-S04-T01 — Tabelas e consumidor de entrada
1. Migration com as cinco tabelas, índices, checks e RLS.
2. Completar `process-inbound-event` (passos 1–4 e 8).
3. Runner: mensagem nova cria contato/conversa/mensagem; segunda mensagem reaproveita; evento repetido não duplica; mesma identidade em dois contatos não funde; linha do tempo registra cada passo.
**Pronto quando:** runner verde.

### P2-S04-T02 — Caixa de entrada e conversa em tempo real
1. Canal Realtime privado por clínica com policy.
2. Telas `/atendimento` e `/atendimento/:conversationId`.
3. RPC `send_human_message` e atualização da situação pelas tabelas da P2-S03.
4. Teste de tela: mensagem chega em até 5 s; resposta enviada mostra situação.
**Pronto quando:** gravação da tela com duas clínicas abertas lado a lado.

### P2-S04-T03 — Identificação, recusa e anexos
1. Passos 5, 6 e 7 do consumidor.
2. Conferência de recusa em `enqueue-outbound-message` para todas as origens.
3. Testes: identificação indisponível não bloqueia; "SAIR" registra recusa; envio automático para quem recusou é bloqueado; PDF aceito; executável renomeado para `.pdf` é recusado pela conferência de tipo; arquivo com assinatura de teste EICAR é recusado.
**Pronto quando:** runner verde com os casos acima.

### P2-S04-T04 — Isolamento e demonstração
1. Matriz: usuário da clínica B tenta ler conversa da A pela tela, pela API REST e assinando o canal Realtime da A — todos negados.
2. Repetição de eventos em lote (10 duplicatas) — nenhuma mensagem duplicada.
3. Demonstração com a recepção usando números de teste.
**Pronto quando:** matriz anexada e "teste ok" da recepção.

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| — | — | Nenhuma | SPEC inicial |
