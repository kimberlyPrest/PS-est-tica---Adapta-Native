# P2-S03 — Números de WhatsApp conectados (Meta Cloud API e Z-API)

**Fase:** 2  
**Status:** liberada para implementação (em paralelo ao fechamento da fase 1)  
**Dono:** técnico de integração; aceite do owner  
**Origem no escopo:** §6.11, §7.2, §11 (webhooks), DEC-09, RT-04, GATE-03, GATE-13, GATE-16  
**Degrau da solução:** construção mínima — dois adaptadores atrás de um contrato único; reusa `integration_connections` e o Vault da P1-S04.

## Contexto e decisões fechadas

- Cada clínica tem número próprio; Meta Cloud API (oficial) e Z-API (não oficial) operam ao mesmo tempo em números diferentes.
- Nada de canal existe hoje no banco: `channel_accounts`, recibos de webhook e filas são criados aqui.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

O administrador cadastra um número por clínica, escolhe Meta ou Z-API e testa a conexão; uma mensagem enviada ao número fica registrada, e uma mensagem enviada pelo sistema chega ao celular com situação de entregue e lida.

## Limites e dependências

- **Inclui:** `channel_accounts`; adaptadores Meta e Z-API; dois webhooks; recibos idempotentes; filas de entrada, saída e falha; envio de texto e de modelo aprovado; situação de entrega; cadastro e teste do canal no `/admin`.
- **Fora de escopo:** tela de conversa (P2-S04); Instagram; envio em massa; troca automática de número ou provedor.
- **Entradas e pré-condições:** mapa aprovado de números, provedor e titularidade (GATE-03); credenciais gravadas pelo `/admin`; plano de contingência da Z-API (GATE-16).
- **Saídas/artefatos:** funções `webhook-whatsapp-meta`, `webhook-whatsapp-zapi`, `send-whatsapp-message`; filas `inbound_events`, `outbound_messages`, `dead_letter`; telas de canal.
- **Dependências e responsáveis:** P2-S01; P1-S04 (segredos). Cliente fornece números de teste; técnico configura os webhooks nos provedores.
- **Risco e plano B:** sessão da Z-API cair ou o número sofrer restrição — a conta é marcada como desconectada, a saída automática dela pausa e o administrador é alertado; o atendimento segue por registro interno.
- **Rollback ou reversão:** desativar a conta do canal no `/admin`; eventos recebidos continuam registrados e nada é enviado.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `channel_accounts` | Supabase | clínica, provedor, telefone E.164, identidade externa, capacidades, situação |
| `webhook_receipts` | Supabase | provedor, id externo do evento, assinatura válida, hash do corpo, situação |
| Meta Cloud API | Meta | verificação por token, assinatura `X-Hub-Signature-256`, janela de 24 h, modelos aprovados |
| Z-API | Z-API | instância, token e `Client-Token`; webhooks de recebimento, entrega e desconexão |
| Filas `pgmq` | Supabase | tempo de visibilidade, tentativas e fila de falha |

## Contrato técnico detalhado

Segue o `00-CONTRATO-COMUM-FASE-2.md`. Esta SPEC cria as filas da fase (seção 5 do contrato comum).

### Tabelas

**`channel_accounts`** — um número de WhatsApp de uma clínica

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid PK | |
| `organization_id`, `clinic_id` | uuid not null | FK composta para `clinics` |
| `provider` | text not null | `meta_cloud` ou `z_api` (`instagram` reservado para a P5-S08) |
| `phone_e164` | text not null | via `normalize_e164()` |
| `display_name` | text | nome exibido na tela |
| `external_account_id` | text not null | Meta: `phone_number_id`; Z-API: `instanceId` |
| `external_business_id` | text | Meta: id da conta comercial (WABA) |
| `integration_connection_id` | uuid not null | FK para `integration_connections` (credenciais via `secret_ref`) |
| `webhook_secret_ref` | text not null | referência no Vault do segredo do caminho do webhook (Z-API) ou do `verify_token` (Meta) |
| `capabilities` | jsonb not null | ex.: `{"templates": true, "janela_24h": true, "midia": true}` |
| `status` | text not null default `draft` | `draft`, `active`, `paused`, `disconnected`, `disabled` |
| `last_inbound_at`, `last_outbound_at`, `last_status_at` | timestamptz | |
| `last_error_code` | text | sem corpo de erro |

Únicas: `(provider, external_account_id)`; `phone_e164` único entre contas com `status in ('active','paused','disconnected')` (índice parcial) — um número ativo pertence a uma só clínica.

**`webhook_receipts`** — imutável

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid PK | |
| `provider` | text not null | `meta_cloud`, `z_api`, `clinica_experts` |
| `channel_account_id` | uuid null | nulo quando não mapeado |
| `organization_id`, `clinic_id` | uuid null | preenchidos quando mapeado |
| `external_event_id` | text not null | Meta mensagem: `wamid`; Meta situação: `wamid:status`; Z-API: `messageId` ou `ids[0]:status`; desconexão: `instanceId:momment` |
| `event_kind` | text not null | `message`, `status`, `connection`, `other` |
| `signature_valid` | boolean not null | |
| `payload_hash` | text not null | SHA-256 do corpo bruto |
| `payload_ref` | text null | caminho em bucket privado `webhook-payloads/<org>/<data>/<id>.json`, retenção de 7 dias; nunca em tabela |
| `status` | text not null | `accepted`, `duplicate`, `rejected_signature`, `rejected_unmapped`, `rejected_stale`, `rejected_rate`, `ignored` |
| `received_at` | timestamptz not null default now() | |
| `correlation_id` | uuid not null | |

Única `(provider, external_event_id)`. RLS: leitura `has_clinic_role(clinic_id, '{owner,clinic_admin}')`; escrita só servidor.

**`provider_message_status`** — imutável; liga a situação do provedor à mensagem (a tabela `messages` chega na P2-S04)

| Coluna | Tipo |
|---|---|
| `id` | uuid PK |
| `organization_id`, `clinic_id`, `channel_account_id` | uuid not null |
| `provider` | text not null |
| `provider_message_id` | text not null |
| `status` | text not null — `sent`, `delivered`, `read`, `failed` |
| `error_code` | text null |
| `occurred_at` | timestamptz not null |

Única `(provider, provider_message_id, status)`.

**`outbound_requests`** — pedido de envio (a P2-S04 liga a `messages`)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid PK | |
| `organization_id`, `clinic_id`, `channel_account_id` | uuid not null | a conta é sempre a de origem da conversa |
| `idempotency_key` | text not null unique | `hash(conversa ou destino + origem + texto + minuto)` |
| `to_phone_e164` | text not null | |
| `kind` | text not null | `text` ou `template` |
| `body_ref` | uuid null | referência ao conteúdo (`messages.id` a partir da P2-S04); em teste, texto sintético em `test_body` |
| `template_name`, `template_language` | text null | |
| `origin` | text not null | `human`, `auto_reply`, `followup`, `campaign`, `system_test` |
| `status` | text not null | `queued`, `sending`, `sent`, `failed`, `blocked` |
| `block_reason` | text null | ex.: `janela_fechada`, `conta_desconectada`, `recusa_do_contato` |
| `attempts` | int not null default 0 | |
| `provider_message_id` | text null | |
| `last_error_code` | text null | |

**`dead_letters`** — `id`, `source_queue`, `ref_id`, `error_code`, `attempts`, `first_failed_at`, `last_failed_at`, `resolved_at`, `resolved_by`, `resolution` (`reprocessado`, `descartado`). Leitura `owner`/`clinic_admin`.

### Webhook da Meta — `webhook-whatsapp-meta`

Rota pública: `/functions/v1/webhook-whatsapp-meta` (sem JWT).

| Pedido | Validação | Resposta |
|---|---|---|
| `GET` com `hub.mode=subscribe`, `hub.verify_token`, `hub.challenge` | `verify_token` igual ao do Vault de alguma conta Meta | 200 com o `hub.challenge` em texto; senão 403 |
| `POST` | `X-Hub-Signature-256 = sha256=HMAC_SHA256(app_secret, corpo_bruto)`, comparação em tempo constante | 200 sempre que a assinatura for válida (mesmo para duplicata); 401 se inválida |

Mapeamento do corpo (`object = whatsapp_business_account`; `entry[].changes[].value`):

| Caminho | Uso |
|---|---|
| `metadata.phone_number_id` | localiza `channel_accounts.external_account_id` |
| `contacts[0].wa_id`, `contacts[0].profile.name` | telefone do contato e nome exibido |
| `messages[].id` | `external_event_id` e `provider_message_id` |
| `messages[].from` | telefone do remetente (dígitos) → E.164 |
| `messages[].timestamp` | segundos Unix → `timestamptz`; mais velho que 24 h → `rejected_stale` |
| `messages[].type` | `text`, `image`, `audio`, `document`, `video`, `sticker`, `location`, `reaction`, outros → `unsupported` |
| `messages[].text.body` | texto (vai para o banco; nunca para log) |
| `messages[].<tipo>.id` | id da mídia (baixada na P2-S04) |
| `statuses[].id`, `.status`, `.timestamp`, `.errors[].code` | `provider_message_status` |

Um `POST` pode trazer várias mensagens e situações: cada item vira um recibo e um item de fila.

Envio (`send-whatsapp-message`, adaptador Meta): `POST https://graph.facebook.com/<versão>/<phone_number_id>/messages` com `Authorization: Bearer <token do Vault>`.

| Tipo | Corpo |
|---|---|
| Texto | `{"messaging_product":"whatsapp","to":"5581900000001","type":"text","text":{"body":"..."}}` |
| Modelo | `{"messaging_product":"whatsapp","to":"...","type":"template","template":{"name":"...","language":{"code":"pt_BR"},"components":[...]}}` |

Resposta: `messages[0].id` → `provider_message_id`. A versão da Graph API é configuração da conexão, não código.

Janela de 24 horas: texto livre só se a última mensagem **recebida** do contato naquela conta tiver menos de 24 h; fora disso, só modelo aprovado; sem modelo → `blocked` com `janela_fechada`.

### Webhook da Z-API — `webhook-whatsapp-zapi`

A Z-API não assina webhooks. Proteção adotada:

| Camada | Regra |
|---|---|
| Caminho com segredo | URL cadastrada no painel da Z-API: `/functions/v1/webhook-whatsapp-zapi?ca=<channel_account_id>&k=<segredo de 32+ bytes>`; o segredo fica no Vault (`webhook_secret_ref`); comparação em tempo constante |
| Instância | `instanceId` do corpo tem de ser igual a `external_account_id` da conta indicada em `ca` |
| Reenvio antigo | `momment` (milissegundos) mais velho que 24 h → `rejected_stale` |
| Limite | 120 pedidos por minuto por conta; acima → 429 e `rejected_rate` |

Mapeamento por `type`:

| `type` | Campos usados | Efeito |
|---|---|---|
| `ReceivedCallback` com `fromMe=false`, `isGroup=false` | `messageId`, `phone`, `momment`, `senderName`, `text.message`, ou o objeto de mídia | mensagem recebida |
| `ReceivedCallback` com `fromMe=true` | os mesmos | mensagem enviada pelo aparelho: registrada como saída `sender_type='device'` (sem duplicar se o `messageId` já veio do nosso envio) |
| `ReceivedCallback` com `isGroup=true` ou `isNewsletter=true` | — | `ignored` |
| `MessageStatusCallback` | `ids[]`, `status` (`SENT`→`sent`, `RECEIVED`→`delivered`, `READ`/`PLAYED`→`read`), `momment` | `provider_message_status` |
| `DisconnectedCallback` | `instanceId`, `momment` | conta → `disconnected`, pausa saída automática, alerta |
| `ConnectedCallback` | `instanceId` | conta volta a `active` só por ação do administrador |

Envio (adaptador Z-API): `POST https://api.z-api.io/instances/<instanceId>/token/<token>/send-text`, cabeçalho `Client-Token: <token de segurança da conta>`, corpo `{"phone":"5581900000001","message":"..."}`. Resposta: `messageId` → `provider_message_id` (guardar também `zaapId`). O token da instância vai no caminho: **nunca** registrar a URL em log.

### Funções internas

| Função | Entrada | Faz |
|---|---|---|
| `enqueue-outbound-message` (SQL `security definer` ou Edge) | `outbound_requests` novo | confere conta `active`, janela, recusa (P2-S04) e grava na fila `outbound_messages` |
| `send-whatsapp-message` | item da fila | escolhe o adaptador pelo `provider` da conta de origem; atualiza `outbound_requests`; erro → nova tentativa da fila |
| `process-inbound-event` | item da fila `inbound_events` | nesta SPEC só marca o recibo como processado; a P2-S04 completa |
| `admin-test-channel` | `channel_account_id` | Meta: `GET /<phone_number_id>`; Z-API: `GET /instances/<id>/token/<token>/status`; devolve situação sanitizada |

### Tela `/admin/canais`

| Elemento | Detalhe |
|---|---|
| Lista | número, clínica, provedor, situação, última entrada, última saída, último erro |
| Novo número (Meta) | clínica, número, `phone_number_id`, id da conta comercial, token de acesso, segredo do app, `verify_token` (gerado pelo sistema e mostrado uma única vez para colar no painel da Meta) |
| Novo número (Z-API) | clínica, número, `instanceId`, token da instância, `Client-Token`; o sistema gera a URL de webhook com segredo e mostra uma única vez |
| Ações | testar conexão, enviar mensagem de teste para um número informado (origem `system_test`), pausar, reativar, desativar |
| Regras | número já ativo em outra clínica → recusa; segredos nunca reaparecem |

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P2-S03-01 | Um número ativo pertence a exatamente uma clínica e um provedor. |
| RN-P2-S03-02 | O webhook responde em até 2 segundos: valida, grava o recibo, enfileira e não espera IA nem Clínica Experts. |
| RN-P2-S03-03 | Idempotência por provedor + id externo do evento; a repetição não gera novo item de fila. |
| RN-P2-S03-04 | Evento para número sem conta mapeada vai para a fila técnica e não cria conversa. |
| RN-P2-S03-05 | A resposta sai sempre pela conta de origem; trocar de número ou provedor só por ação humana auditada. |
| RN-P2-S03-06 | Meta fora da janela de 24 h exige modelo aprovado; sem modelo, o envio é bloqueado com motivo. |
| RN-P2-S03-07 | Z-API desconectada pausa a saída automática só daquela conta e alerta o administrador. |
| RN-P2-S03-08 | O webhook recusa evento com data fora da janela de tolerância (proteção contra reenvio) e limita requisições por origem. |

## Fluxo e regras

1. Administrador cadastra a conta do canal, grava as credenciais e testa a conexão.
2. O provedor chama o webhook; a função valida, grava o recibo e enfileira o evento normalizado.
3. O sistema enfileira uma mensagem de saída; o adaptador envia e grava o id devolvido pelo provedor.
4. Os eventos de situação atualizam enviado, entregue e lido.
5. Falha esgotada vai para a fila de falha e aparece no painel.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | número de teste Meta e número de teste Z-API em clínicas diferentes | entrada registrada e saída entregue em cada um, sem misturar identificadores | evidência por provedor |
| Limite | evento repetido, assinatura inválida, número não mapeado, Meta fora da janela | um só processamento; 401; fila técnica; bloqueio com motivo | nenhuma conversa criada indevidamente |
| Falha | provedor fora do ar ou Z-API desconectada | nova tentativa com espera crescente, depois fila de falha; conta marcada desconectada | alerta e atendimento por registro interno |

## Checklist de execução

- [ ] Mapa de números e provedores aprovado carregado.
- [ ] Webhooks configurados nos dois provedores.
- [ ] Matriz de contrato executada por provedor.
- [ ] Contingência da Z-API demonstrada.
- [ ] Owner validou envio e recebimento reais.

## Critérios de aceite

- [ ] **CA-P2-S03-01:** O administrador cria uma conta Meta e uma conta Z-API em clínicas diferentes pela interface; o segredo não reaparece e o teste de conexão devolve diagnóstico sanitizado.
- [ ] **CA-P2-S03-02:** O mesmo evento entregue duas vezes gera um recibo processado e um item de fila, em cada provedor.
- [ ] **CA-P2-S03-03:** Assinatura ou token inválido devolve 401, grava recibo como inválido e não enfileira nada.
- [ ] **CA-P2-S03-04:** Evento para número não mapeado vai para a fila técnica e não cria conversa.
- [ ] **CA-P2-S03-05:** O envio de texto por cada provedor grava o id da mensagem e evolui de enviado para entregue e lido, sem misturar identificadores entre provedores.
- [ ] **CA-P2-S03-06:** Com o provedor indisponível, há novas tentativas até o limite e depois fila de falha visível; Z-API desconectada pausa a saída automática só da conta afetada.
- [ ] **CA-P2-S03-07:** Meta fora da janela sem modelo aprovado é bloqueado com motivo e não troca de número nem de provedor.
- [ ] **CA-P2-S03-08:** Evento com data fora da janela de tolerância ou acima do limite de requisições por origem é recusado e registrado.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | webhook e envio inexistentes | enviar evento de exemplo de cada provedor e pedir um envio | nada registrado: CA-P2-S03-02 e CA-P2-S03-05 falham | saída versionada do runner ou roteiro, anexada à task |
| GREEN | adaptadores e webhooks no caminho feliz | evento válido e envio de texto por provedor | CA-P2-S03-01, CA-P2-S03-02 e CA-P2-S03-05 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | contrato completo | repetição, assinatura inválida, não mapeado, fora da janela, provedor fora do ar, desconexão, evento antigo reenviado e rajada acima do limite | CA-P2-S03-03, CA-P2-S03-04, CA-P2-S03-06, CA-P2-S03-07 e CA-P2-S03-08 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** corpos de exemplo de cada provedor (mensagem, situação, desconexão); números de teste; provedor simulado para falhas.  
**Caminhos de erro obrigatórios:** repetição, assinatura inválida, número não mapeado, janela expirada, 4xx/5xx do provedor, timeout, desconexão.  
**Evidência exigida:** relatório da matriz por provedor, recibos e capturas do envio real nos números de teste.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P2-S03-T01 | Criar contas de canal, recibos, filas e o cadastro com teste de conexão no `/admin`. | técnico de banco + frontend | CA-P2-S03-01 | cenário principal de cadastro | captura do cadastro e do teste sanitizado | P2-S01; mapa de números aprovado | 20/10/2026 | ☐ Liberada |
| P2-S03-T02 | Implementar adaptador e webhook da Meta Cloud API (entrada, saída, situação, janela e modelos). | técnico de integração | CA-P2-S03-02, CA-P2-S03-03, CA-P2-S03-05, CA-P2-S03-07 | GREEN do provedor Meta | relatório do runner Meta | T01; credenciais Meta no Vault | 21/10/2026 | ☐ Liberada |
| P2-S03-T03 | Implementar adaptador e webhook da Z-API (entrada, saída, situação e desconexão). | técnico de integração | CA-P2-S03-02, CA-P2-S03-03, CA-P2-S03-05, CA-P2-S03-06 | GREEN do provedor Z-API | relatório do runner Z-API | T01; credenciais Z-API no Vault | 21/10/2026 | ☐ Liberada |
| P2-S03-T04 | Executar a matriz de contrato dos dois provedores e demonstrar envio e recebimento reais. | QA + owner | CA-P2-S03-02, CA-P2-S03-03, CA-P2-S03-04, CA-P2-S03-05, CA-P2-S03-06, CA-P2-S03-07, CA-P2-S03-08 | REGRESSÃO completa | relatório e aceite do owner | T02 e T03 concluídas | 22/10/2026 | ☐ Liberada |

## Roteiro das tasks

### P2-S03-T01 — Tabelas, filas e cadastro do canal
1. Migration com as cinco tabelas, índices, RLS e as cinco filas `pgmq`.
2. Agendamento `pg_cron` a cada 10 s chamando os consumidores com `INTERNAL_JOB_SECRET`.
3. Tela `/admin/canais` com cadastro, teste e geração das URLs/segredos.
4. Runner: unicidade do número ativo, RLS por papel, segredo nunca devolvido.
**Pronto quando:** runner verde e capturas do cadastro.

### P2-S03-T02 — Adaptador e webhook da Meta
1. Implementar verificação `GET`, assinatura `POST`, mapeamento e recibo por item.
2. Implementar envio de texto e de modelo e a regra da janela.
3. `deno test` com corpos de exemplo da Meta: mensagem de texto, imagem, situação `sent/delivered/read/failed`, lote com 3 itens, assinatura inválida, evento repetido, mensagem com mais de 24 h.
4. Cadastrar o webhook no painel da Meta e trocar mensagem real com número de teste.
**Pronto quando:** testes verdes e troca real registrada.

### P2-S03-T03 — Adaptador e webhook da Z-API
1. Implementar validação por caminho com segredo + `instanceId`, limite por conta e mapeamento por `type`.
2. Implementar envio por `send-text` com `Client-Token`.
3. `deno test`: recebida, enviada pelo aparelho, grupo ignorado, situação, desconexão, segredo errado, `instanceId` trocado, repetição.
4. Configurar o webhook na instância de teste e trocar mensagem real.
**Pronto quando:** testes verdes e troca real registrada.

### P2-S03-T04 — Matriz de contrato e demonstração
1. Rodar a matriz completa nos dois provedores.
2. Simular provedor fora do ar: 5 tentativas em 30 min e fila de falha.
3. Desconectar a instância de teste da Z-API: conta muda para `disconnected` e a saída automática dela para.
4. Demonstrar ao owner e registrar o aceite.
**Pronto quando:** matriz completa anexada e "teste ok" do owner.

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| — | — | Nenhuma | SPEC inicial |
