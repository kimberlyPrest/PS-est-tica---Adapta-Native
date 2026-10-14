# P2-S05 — Tickets, filas, prazos e cadeia de transbordo

**Fase:** 2  
**Status:** liberada para implementação (em paralelo ao fechamento da fase 1)  
**Dono:** técnico de implementação; aceite do manager  
**Origem no escopo:** §7.1, §7.2, §8.5, fluxo 13.2, RT-06, RT-21, RT-22, GATE-02, GATE-14; console §7–8  
**Degrau da solução:** construção mínima — motor de distribuição determinístico sobre filas e agendador do Supabase.

## Contexto e decisões fechadas

- São cinco atendentes distribuídas entre as clínicas; cada clínica tem equipe, horário e plantonista próprios.
- `teams` e `team_members` existem desde a P1-S01; fila, expediente, presença e política de distribuição ainda não.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

Um pedido de atendimento humano vira ticket na fila da clínica, é oferecido a uma atendente presente, reofertado se ninguém aceitar, escalado ao gestor e, fora do expediente, fica aberto com mensagem de espera — nunca sem dono ou fila.

## Limites e dependências

- **Inclui:** tickets e eventos de ticket; expediente, escalas e presença; política de distribuição e cadeia de contingência; aceite, transferência, devolução, escalonamento e resolução; alertas de prazo; console de filas, horários e prazos; visão do gestor.
- **Fora de escopo:** decidir quando transbordar por intenção (P2-S06); sugestão de resposta (P2-S07); contingência entre clínicas sem regra aprovada.
- **Entradas e pré-condições:** filas, estratégia, prazos, expediente, feriados e plantonistas aprovados por clínica (GATE-14); mensagens de espera aprovadas (GATE-04).
- **Saídas/artefatos:** tabelas de ticket, função `process-ticket-routing`, funções `ticket-assign` e `ticket-escalate`, telas de ticket e de configuração.
- **Dependências e responsáveis:** P2-S04. Cliente entrega a configuração aprovada; manager valida.
- **Risco e plano B:** ticket ficar parado sem ninguém presente — permanece em fila ou escalado com alerta ao gestor; nunca recebe resposta de conteúdo para "encerrar" a fila.
- **Rollback ou reversão:** trocar a estratégia para distribuição manual por clínica; tickets abertos permanecem na fila.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `tickets`, `ticket_events`, `ticket_sla_events` | Supabase | campos do §7.2; estados do §8.5 |
| `business_hours`, `user_shifts`, `attendant_presence` | Supabase | expediente, feriados, escala e carga ativa |
| `routing_policies` | Supabase | estratégia, habilidades, tempo de aceite, máximo de reofertas, fila reserva, modo de contingência, versão |
| Agendador + fila `ticket_jobs` | Supabase | varredura de aceite e prazo a cada minuto |

## Contrato técnico detalhado

Segue o `00-CONTRATO-COMUM-FASE-2.md`. Usa `teams` e `team_members` da P1-S01. A tabela `handoffs` do escopo (§7.2) é substituída por `tickets.handoff_reason` + `ticket_events` (registrar como emenda; o histórico de transbordo fica completo nos eventos).

### Tabelas novas

**`ticket_queues`** — `id`, `organization_id`, `clinic_id`, `team_id` (FK `teams`), `name`, `purpose` (`comercial`, `recepcao`, `pos_venda`, `geral`), `priority_default` (1 alta, 2 normal, 3 baixa), `active`. Única `(clinic_id, name)`.

**`business_hours`** — `clinic_id`, `team_id` (nulo = clínica toda), `weekday` (0 domingo – 6 sábado), `opens_at` time, `closes_at` time, `timezone` (padrão `America/Recife`). **`business_closures`** — `clinic_id`, `date`, `reason` (feriado, evento). Uma faixa por dia e equipe na primeira versão.

**`user_shifts`** — `user_id`, `clinic_id`, `starts_at`, `ends_at`, `status` (`planned`, `absent`). Opcional: sem escala cadastrada, vale o expediente da equipe.

**`attendant_presence`** — `user_id`, `clinic_id`, `state` (`online`, `away`, `offline`), `active_load` int, `last_seen_at`. Única `(user_id, clinic_id)`. A tela envia batimento a cada 30 s; sem batimento por 2 min → `offline`.

**`routing_policies`** — versionada

| Coluna | Tipo | Padrão |
|---|---|---|
| `clinic_id`, `queue_id` | uuid not null | |
| `strategy` | text | `least_load` (`round_robin`, `least_load`, `skills_based`, `manual`) |
| `skills` | text[] | vazio |
| `accept_timeout_seconds` | int | 120 |
| `max_reoffers` | int | 2 |
| `first_response_sla_minutes` | int | 10 (dentro do expediente) |
| `backup_queue_id` | uuid null | |
| `escalation_role` | text | `manager` |
| `after_hours_template_id` | uuid null | modelo aprovado (P2-S06); até lá, texto aprovado em `config_json` |
| `fallback_mode` | text | `fila_aberta` (`fila_aberta`, `plantonista`) |
| `version`, `status` | int, text | `draft`, `published`, `archived` |

Só uma versão `published` por fila; publicar arquiva a anterior; voltar republica a anterior (auditoria em `config_audit_logs`).

**`team_members`**: acrescentar `skills text[]` e `max_concurrent int default 5` por migration aditiva (emenda à P1-S01, sem mexer em chaves).

**`tickets`**

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid PK | |
| `organization_id`, `clinic_id`, `conversation_id`, `queue_id` | uuid not null | |
| `status` | text not null | `new`, `queued`, `offered`, `assigned`, `in_service`, `waiting_customer`, `resolved`, `sla_breached`, `escalated`, `blocked`, `provider_failure`, `cancelled` |
| `priority` | int not null | 1–3 |
| `handoff_reason` | text not null | `pedido_humano`, `risco`, `baixa_confianca`, `falha_automacao`, `regra_negocio`, `manual` |
| `intent` | text null | preenchido pela P2-S06 |
| `assigned_to` | uuid null | |
| `offered_to` | uuid null | oferta atual |
| `offer_expires_at` | timestamptz null | |
| `reoffer_count` | int not null default 0 | |
| `sla_due_at` | timestamptz null | calculado em minutos úteis |
| `accepted_at`, `first_response_at`, `resolved_at` | timestamptz | |
| `resolution_code` | text null | `atendido`, `agendamento_encaminhado`, `sem_resposta_cliente`, `spam`, `transferido_outra_clinica` |
| `resolution_note` | text null | |
| `next_action_at` | timestamptz null | obrigatório ao resolver, salvo `spam` |
| `version` | int not null default 1 | concorrência otimista |

Única parcial: um ticket aberto (`status not in ('resolved','cancelled')`) por conversa. Check: `assigned_to is not null or status in ('new','queued','offered','escalated','blocked','provider_failure','cancelled','resolved')`.

**`ticket_events`** — imutável: `ticket_id`, `event_type` (`created`, `offered`, `offer_expired`, `accepted`, `transferred`, `returned`, `escalated`, `sla_breached`, `after_hours_notice`, `resolved`, `reopened`), `from_user_id`, `to_user_id`, `reason_code`, `metadata_sanitized`, `occurred_at`.

**`ticket_sla_events`** — `ticket_id`, `metric` (`accept`, `first_response`), `due_at`, `breached_at`, `acknowledged_at`.

### RLS

| Tabela | select | escrita |
|---|---|---|
| `tickets`, `ticket_events`, `ticket_sla_events` | `is_clinic_member(clinic_id)` | só pelos RPCs abaixo e pelo servidor |
| `ticket_queues`, `business_hours`, `business_closures`, `routing_policies` | `is_clinic_member` | `has_clinic_role(clinic_id, '{owner,clinic_admin}')` |
| `attendant_presence` | `is_clinic_member` | o próprio usuário (`user_id = auth.uid()`) e só em clínicas onde é membro |
| `user_shifts` | `is_clinic_member` | `owner`, `clinic_admin`, `manager` |

### RPCs (todos `security definer`, conferem vínculo e papel)

| RPC | Quem | Efeito |
|---|---|---|
| `open_ticket(conversation_id, reason, priority)` | servidor e membro da clínica | cria ou devolve o ticket aberto; pausa automação da conversa |
| `accept_ticket(ticket_id, version)` | atendente que recebeu a oferta, ou qualquer membro da fila no modo manual | `update ... where version = $2 and status in ('offered','queued')`; 0 linhas → 409 `conflito` |
| `transfer_ticket(ticket_id, to_user_id, reason)` | responsável ou `manager` | destino precisa ser membro da mesma clínica |
| `return_ticket(ticket_id, reason)` | responsável | volta para `queued` |
| `escalate_ticket(ticket_id, reason)` | responsável ou `manager` | `escalated` + alerta ao papel de escalonamento |
| `resolve_ticket(ticket_id, code, note, next_action_at)` | responsável ou `manager` | exige código e próxima ação |
| `return_to_automation(conversation_id)` | responsável ou `manager` | despausa automação; evento registrado |

### Motor `process-ticket-routing`

Disparado por `ticket_jobs` (ticket novo, oferta vencida, prazo vencido) e por varredura do `pg_cron` a cada 30 s.

1. Fora do expediente (`business_hours` + `business_closures` no fuso da clínica): enviar uma única vez o aviso aprovado, gravar `after_hours_notice`, manter `queued` e criar `next_action_at` = início do próximo período útil.
2. Elegíveis = membros ativos da equipe da fila, com `attendant_presence.state='online'`, `active_load < max_concurrent`, sem ausência na escala e, se `skills_based`, com as habilidades exigidas. Nunca de outra clínica.
3. Escolha: `least_load` (menor carga, depois mais tempo sem receber), `round_robin` (próximo após o último que recebeu), `manual` (não oferece; só fila).
4. Oferecer: `offered_to`, `offer_expires_at = now() + accept_timeout`, evento `offered`, aviso Realtime ao usuário.
5. Oferta vencida: `reoffer_count++`; se `< max_reoffers`, próxima elegível; senão fila reserva; depois `escalated` com alerta ao `escalation_role` da mesma clínica.
6. Ninguém elegível: `queued` (ou `escalated` se já passou da reserva) + alerta; nenhuma mensagem de conteúdo é enviada ao contato.
7. Prazo de primeira resposta vencido: `ticket_sla_events.breached_at`, `sla_breached`, alerta.

### Telas

**Painel lateral do ticket** (em `/atendimento/:conversationId`)

| Elemento | Detalhe |
|---|---|
| Cabeçalho | situação, fila, prioridade, motivo do transbordo, prazo com contagem regressiva |
| Oferta | quando oferecido a mim: botões "Assumir" e "Recusar" com contagem do tempo de aceite |
| Ações | transferir (lista só de membros da clínica), devolver à fila, escalar, resolver (código + observação + próxima ação), devolver à automação |
| Linha do tempo | `ticket_events` legíveis |

**Presença**: chave "Disponível / Pausa" no topo do app; o batimento sai só enquanto a aba estiver aberta.

**`/filas`** (gestor): tickets por situação e fila, vencidos em vermelho, tempo até aceite (mediana do dia), atendentes online e carga, ações "atribuir a" e "escalar".

**`/admin/filas`**: filas, equipe, estratégia, tempos, reserva, expediente semanal, fechamentos, aviso fora do expediente; rascunho → publicar → voltar à versão anterior.

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P2-S05-01 | Um ticket aberto por conversa; pedido repetido atualiza o mesmo ticket. |
| RN-P2-S05-02 | O aceite usa controle de concorrência: de dois cliques simultâneos, só um vence. |
| RN-P2-S05-03 | Estratégias: rodízio, menor carga, por habilidade e manual; capacidade e presença não ampliam permissão. |
| RN-P2-S05-04 | A oferta nunca sai da clínica do número, salvo vínculo explícito e regra de contingência aprovada. |
| RN-P2-S05-05 | Cadeia padrão: atendente elegível → próxima da fila → equipe reserva → gestor ou plantonista → fila aberta para o próximo expediente, com alerta. |
| RN-P2-S05-06 | Fora do expediente: mensagem de espera aprovada uma única vez, ticket aberto e tarefa para o próximo período útil. |
| RN-P2-S05-07 | Depois do transbordo, a resposta automática da conversa fica pausada até devolução explícita ou resolução. |
| RN-P2-S05-08 | Resolver exige código de resultado e autoria humana. |

## Fluxo e regras

1. A conversa pede atendimento humano; o sistema cria ou atualiza o ticket com fila, prioridade, prazo e motivo.
2. O motor escolhe a atendente elegível conforme a política e oferece o ticket.
3. Sem aceite no tempo, reoferta, depois reserva e gestor, registrando cada passo.
4. A atendente aceita, atende, transfere, devolve ou escala.
5. A resolução grava resultado, observação e próxima ação.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | atendente presente e com capacidade | oferta, aceite e atendimento dentro do prazo | linha do tempo do ticket completa |
| Limite | ninguém aceita, fora do expediente ou ninguém presente | reoferta e escalonamento; mensagem de espera única; ticket em fila com alerta | gestor assume ou o caso abre no próximo expediente |
| Falha | falha do canal ou do agendador | ticket marca falha do provedor e segue operável por registro interno | nova tentativa de envio e alerta técnico |

## Checklist de execução

- [ ] Configuração aprovada de filas, prazos e expediente carregada por clínica.
- [ ] Cadeia de contingência simulada do início ao fim.
- [ ] Aceite simultâneo testado.
- [ ] Alteração de configuração com versão e volta à anterior demonstrada.
- [ ] Manager validou a visão de fila.

## Critérios de aceite

- [ ] **CA-P2-S05-01:** Um pedido de humano cria um único ticket com fila, prioridade, prazo e motivo; a repetição não duplica.
- [ ] **CA-P2-S05-02:** De dois aceites simultâneos só um vence; o outro recebe "já assumido".
- [ ] **CA-P2-S05-03:** Sem aceite no tempo configurado, o ticket é reofertado até o máximo, depois vai à equipe reserva e ao gestor; cada passo fica registrado.
- [ ] **CA-P2-S05-04:** Fora do expediente, a mensagem de espera aprovada é enviada uma única vez, o ticket permanece aberto e nasce uma tarefa para o próximo período útil.
- [ ] **CA-P2-S05-05:** Sem ninguém presente, o ticket fica em fila ou escalado com alerta ao gestor, e nenhuma resposta automática de conteúdo é enviada.
- [ ] **CA-P2-S05-06:** Uma atendente da clínica B nunca recebe oferta de ticket da clínica A.
- [ ] **CA-P2-S05-07:** O administrador altera fila, horário, prazo e cadeia pelo console, com versão e volta à anterior; a mudança vale só para aquela clínica.
- [ ] **CA-P2-S05-08:** A visão do gestor mostra tickets por estado, prazo vencido e tempo até o aceite.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | pedido de humano sem ticket | disparar o pedido em conversa de teste | nenhum ticket: CA-P2-S05-01 falha | saída versionada do runner ou roteiro, anexada à task |
| GREEN | oferta e aceite no caminho feliz | atendente presente aceita e resolve | CA-P2-S05-01, CA-P2-S05-02 e CA-P2-S05-08 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | cadeia de contingência e isolamento | sem aceite; fora do expediente; ninguém presente; atendente de outra clínica; mudança de configuração | CA-P2-S05-03 a CA-P2-S05-07 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** duas clínicas com três atendentes sintéticas, expedientes diferentes e relógio controlado para simular prazos.  
**Caminhos de erro obrigatórios:** aceite simultâneo, sem presença, fora do expediente, feriado, fila sem reserva configurada, falha do canal.  
**Evidência exigida:** linha do tempo dos tickets de teste, relatório do runner e aceite do manager.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P2-S05-T01 | Criar tickets, expediente, presença e política de distribuição, com o console de filas, horários e prazos. | técnico de banco + frontend | CA-P2-S05-01, CA-P2-S05-07 | RED do pedido de humano; mudança de configuração | capturas do console e versão publicada | P2-S04-T01; configuração aprovada por clínica | 27/10/2026 | ☐ Liberada |
| P2-S05-T02 | Implementar o motor de distribuição, reoferta, escalonamento e alertas de prazo. | técnico de integração | CA-P2-S05-01, CA-P2-S05-03, CA-P2-S05-04, CA-P2-S05-05, CA-P2-S05-06 | cadeia de contingência com relógio controlado | relatório do runner | T01 concluída | 27/10/2026 | ☐ Liberada |
| P2-S05-T03 | Construir a tela do ticket (aceitar, transferir, devolver, escalar, resolver), a presença e a visão do gestor. | técnico de frontend | CA-P2-S05-02, CA-P2-S05-08 | cenário principal e aceite simultâneo | gravação da tela | T02 concluída | 28/10/2026 | ☐ Liberada |
| P2-S05-T04 | Executar a matriz de contingência e isolamento e demonstrar com o gestor. | QA + manager | CA-P2-S05-03, CA-P2-S05-04, CA-P2-S05-05, CA-P2-S05-06, CA-P2-S05-07 | REGRESSÃO completa | matriz e aceite do manager | T03 concluída | 28/10/2026 | ☐ Liberada |

## Roteiro das tasks

### P2-S05-T01 — Tabelas e console de filas, horários e prazos
1. Migration com as tabelas, a emenda de `team_members`, RLS e RPCs de configuração.
2. Tela `/admin/filas` com rascunho, publicação e volta de versão.
3. Carregar a configuração aprovada das duas clínicas (GATE-14).
4. Runner: publicar e voltar versão; clinic_admin da clínica A não altera a B.
**Pronto quando:** runner verde e configuração das duas clínicas publicada.

### P2-S05-T02 — Motor de distribuição
1. RPCs de ticket e o motor `process-ticket-routing` com os sete passos.
2. Relógio controlado nos testes (`now()` injetável).
3. Runner: oferta, aceite, oferta vencida, reoferta, reserva, escalonamento, fora do expediente, feriado, ninguém online, prazo vencido, atendente de outra clínica nunca elegível.
**Pronto quando:** runner verde com todos os casos.

### P2-S05-T03 — Tela do ticket, presença e visão do gestor
1. Painel lateral do ticket, chave de presença e `/filas`.
2. Teste de concorrência: duas sessões clicam "Assumir" ao mesmo tempo — uma recebe 409 e a mensagem "Já assumido por outra pessoa".
3. Teste de tela para cada ação do ticket.
**Pronto quando:** gravação do fluxo completo e teste de concorrência verde.

### P2-S05-T04 — Matriz de contingência e demonstração
1. Executar com três contas de atendente reais de teste e o gestor: sem aceite → reoferta → reserva → gestor; fora do expediente; ninguém online.
2. Conferir que nenhuma oferta cruzou clínicas.
3. Registrar o aceite do gestor.
**Pronto quando:** matriz anexada e "teste ok" do gestor.

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| — | — | Nenhuma | SPEC inicial |
