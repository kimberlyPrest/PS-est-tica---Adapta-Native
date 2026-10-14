# Contrato comum da fase 2

Vale para todas as SPECs P2-S01 a P2-S07. Quando uma SPEC disser "conforme o contrato comum", é este arquivo.

## 1. Antes de qualquer task

1. Ler a SPEC inteira, este contrato e o mapa de dados do Clínica Experts (`mapa-de-dados-clinica-experts.md`) quando a SPEC tocar o Clínica Experts.
2. Conferir o **estado físico** do banco antes de criar ou alterar objetos: `pg_tables`, `pg_constraint`, `pg_policies`, `pg_proc`. Se um objeto citado aqui já existir com outro formato, **parar e registrar DÚVIDA** em `06_notas/` — nunca corrigir em silêncio (aprendizado AP-2026-10-02-1125).
3. Toda mudança de schema é migration nova, aditiva, versionada em `supabase/migrations/` (a partir da P2-S01). Nada de SQL manual em produção.
4. Nenhum dado real em teste, commit, evidência ou print. Telefones de teste começam com `+55 81 90000-`.

## 2. Convenções de banco

| Tema | Regra |
|---|---|
| Chave | `id uuid primary key default gen_random_uuid()` |
| Datas | `created_at timestamptz not null default now()`, `updated_at timestamptz not null default now()` com gatilho de atualização |
| Escopo | toda tabela operacional tem `organization_id uuid not null` e, quando ligada a uma unidade, `clinic_id uuid not null`, com FK composta `(clinic_id, organization_id) → clinics(id, organization_id)` |
| Estados | `text` com `check (... in (...))`; nunca enum do Postgres (facilita evolução por migration aditiva) |
| Imutáveis | tabelas de evento (`*_events`, `webhook_receipts`, `agent_steps`) não recebem `update` nem `delete` de usuário: só `insert` pelo servidor |
| Dinheiro | inteiro em centavos |
| Telefone | `text` em E.164 com `+` (ex.: `+5581900000001`), sempre gerado por `normalize_e164()` (P1-S05) |

## 3. Regras de acesso (RLS)

Toda tabela nova nasce com RLS ligada e com as quatro operações declaradas na SPEC. Usar as funções auxiliares criadas na P1-S02. Se os nomes forem diferentes dos abaixo, usar os existentes e registrar o nome real na SPEC (emenda).

| Função auxiliar esperada | Significado |
|---|---|
| `is_org_member(org uuid)` | usuário tem algum vínculo ativo na organização |
| `is_clinic_member(clinic uuid)` | usuário tem vínculo ativo na clínica |
| `has_clinic_role(clinic uuid, roles text[])` | usuário tem um dos papéis na clínica |

Padrões:

- **Leitura operacional** (conversa, mensagem, ticket): `is_clinic_member(clinic_id)`.
- **Configuração da clínica** (filas, horários, conhecimento, modelos, agentes): leitura `is_clinic_member`; escrita `has_clinic_role(clinic_id, '{owner,clinic_admin}')`.
- **Escrita feita pelo servidor** (recibos, eventos, execuções de agente): sem policy de `insert` para `authenticated`; só a `service_role` dentro das Edge Functions grava.
- `anon` nunca lê nada operacional.

## 4. Edge Functions

### 4.1 Organização do código

```
supabase/functions/
  _shared/            cliente Supabase, erros, correlação, logger sanitizado, validação (zod), clientes HTTP
  _shared/providers/  meta.ts, zapi.ts, clinica-experts.ts, ia.ts
  <nome-da-funcao>/index.ts
```

Funções de baixo volume podem compartilhar handler; a divisão física é decisão técnica, mas os **nomes de rota** desta fase são contrato.

### 4.2 Envelope de resposta

Sucesso: `{"data": {...}, "correlation_id": "uuid"}`
Erro: `{"error": {"code": "texto_curto", "message": "mensagem em português para a tela"}, "correlation_id": "uuid"}`

| HTTP | `code` | Quando |
|---|---|---|
| 400 | `entrada_invalida` | payload fora do schema |
| 401 | `nao_autenticado` | sem JWT válido |
| 403 | `sem_permissao` | sem vínculo ou papel |
| 404 | `nao_encontrado` | recurso inexistente no escopo do usuário |
| 409 | `conflito` | concorrência (ex.: ticket já assumido) |
| 422 | `regra_de_negocio` | regra impediu a ação (ex.: janela da Meta fechada) |
| 502 | `falha_externa` | provedor externo respondeu erro |
| 503 | `indisponivel` | integração desligada, não configurada ou em pausa |
| 504 | `tempo_esgotado` | tempo limite de chamada externa |

### 4.3 Correlação e logs

- Todo pedido gera ou recebe `x-correlation-id`; ele segue para filas, chamadas externas, execuções de agente e eventos.
- O logger só aceita campos de uma lista permitida. Proibido registrar: token, `Authorization`, `Client-Token`, corpo de webhook, texto de mensagem, CPF, RG, endereço, e-mail e telefone completo (telefone aparece como `+55 81 9****-0000`).

### 4.4 Tempo limite e novas tentativas

| Chamada | Tempo limite | Novas tentativas |
|---|---|---|
| Clínica Experts (leitura) | 8 s | 2, com espera crescente e variação aleatória, só para 429, 5xx e tempo esgotado |
| Meta / Z-API (envio) | 10 s | feitas pela fila, nunca dentro do pedido; 5 tentativas em 30 min, depois fila de falha |
| IA | 15 s triagem / 25 s copiloto | 1 tentativa extra; depois caminho humano |

## 5. Filas e agendamentos

Filas `pgmq` criadas na P2-S03 e reutilizadas pelas demais:

| Fila | Produz | Consome | Tempo de visibilidade | Tentativas antes da fila de falha |
|---|---|---|---|---|
| `inbound_events` | webhooks | `process-inbound-event` | 60 s | 5 |
| `outbound_messages` | `enqueue-outbound-message` | `send-whatsapp-message` | 60 s | 5 |
| `agent_jobs` | `process-inbound-event` | `run-agent-job` | 90 s | 2 |
| `ticket_jobs` | tickets e agendador | `process-ticket-routing` | 60 s | 5 |
| `dead_letter` | todas | painel (P4-S03) e reprocessamento manual | — | — |

Envelope de mensagem de fila: `{"type": "...", "organization_id": "...", "clinic_id": "...", "ref_id": "...", "correlation_id": "...", "attempt": 1, "enqueued_at": "..."}` — nunca conteúdo de mensagem nem dado pessoal; o consumidor lê o conteúdo do banco pelo `ref_id`.

Consumidores são acionados pelo `pg_cron` a cada 10 segundos via `net.http_post` para a função consumidora, com segredo interno de job (`INTERNAL_JOB_SECRET`). O cron só dispara; não processa lote dentro do banco.

## 6. Interruptores (`feature_flags`)

Criada na P2-S02 (primeira SPEC que precisa) se não existir:

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid PK | |
| `organization_id` | uuid not null | |
| `clinic_id` | uuid null | nulo = padrão da organização |
| `flag_key` | text not null | ex.: `busca_paciente`, `canal_saida_automatica`, `auto_resposta`, `copiloto` |
| `enabled` | boolean not null default false | tudo nasce desligado |
| `config_json` | jsonb not null default '{}' | sem segredo |
| `version` | int not null default 1 | |
| `updated_by` | uuid | |

Única `(organization_id, coalesce(clinic_id, '00000000-0000-0000-0000-000000000000'), flag_key)`. Valor efetivo: clínica, senão organização, senão desligado. Escrita só `owner`/`clinic_admin` (da clínica) e auditada em `config_audit_logs`.

## 7. Telas

- Base visual: componentes shadcn/ui já instalados; nenhuma biblioteca nova sem justificativa na task.
- Rotas da fase 2 (criadas pela P2-S01 com o menu lateral e o seletor de clínica):

| Rota | Tela | SPEC |
|---|---|---|
| `/inicio` | painel inicial sem números fictícios | P2-S01 |
| `/pacientes/identificar` | busca de paciente | P2-S02 |
| `/atendimento` | caixa de entrada | P2-S04 |
| `/atendimento/:conversationId` | conversa + ticket + copiloto | P2-S04, S05, S07 |
| `/filas` | visão do gestor | P2-S05 |
| `/admin/conexoes` | Clínica Experts | P2-S02 |
| `/admin/canais` | números de WhatsApp | P2-S03 |
| `/admin/filas` | filas, horários, prazos | P2-S05 |
| `/admin/conhecimento` | respostas aprovadas e modelos | P2-S06 |
| `/admin/agentes` | agentes, prompts e versões | P2-S07 |

- Toda tela tem os quatro estados: carregando, vazio, erro (com `correlation_id` copiável) e conteúdo.
- O seletor de clínica mostra só clínicas do usuário; a clínica escolhida vai em toda chamada e nunca é confiada sem checagem no servidor.

## 8. Provas

| Camada | Ferramenta | Onde |
|---|---|---|
| Banco (schema, RLS, funções) | runners PGlite no padrão da fase 1 | `scripts/test_p2_sXX_*.js` |
| Edge Functions | `deno test` com provedores simulados | `supabase/functions/**/*.test.ts` |
| Telas | Vitest + Testing Library | `src/**/*.test.tsx` |
| Ponta a ponta | roteiro HTML de teste humano no padrão da fase 1 | `artifacts/roteiro-p2-sXX-*.html` |

Cada task termina com: runner verde, evidência sanitizada anexada, linha no `changelog.md`, `STATUS.md` atualizado e aceite humano ("teste ok") quando a task pedir demonstração.
