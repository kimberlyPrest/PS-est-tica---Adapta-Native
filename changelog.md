# Changelog — CRM Estética (handoff)

## 2026-10-28 (3) — DESVIO registrado na SPEC: P2-S03-T04 depende de um segundo número

- O owner decidiu **registrar desvio formal** em vez de comprar um segundo número agora (28/10, 06:41).
- Motivo técnico, verificado na documentação da Meta: um número registrado no Cloud API **não pode** operar simultaneamente no aplicativo WhatsApp nem em API não oficial, e a exclusão do portfólio é caminho de ida — a ajuda do WhatsApp declara que número excluído não volta para outra conta da plataforma, além de apagar os dados do número. Não existe caminho técnico com um número só.
- Alternativa descartada e por quê: retirar `+55 81 98234-9927` da Meta para liberá-lo à Z-API. Destruiria o canal Meta recém-aceito na T02, apagaria o `phone_number_id` 707487385771432 (ao re-registrar vem outro), perderia o histórico do número e colocaria em risco não oficial o número de pós-procedimento da clínica.
- Documento criado: `06_notas/desvio-p2-s03-t04-segundo-numero.md` — com o problema em linguagem simples, o que já foi provado (CA-P2-S03-06 nas duas partes), o que falta, os três bugs corrigidos e **três opções** para a consultora decidir (aceitar prova por provedor; manter bloqueada; ou emendar a SPEC separando T04a/T04b).
- Recomendação técnica registrada: opção 1 ou 3. A opção 2 trava a fase 2 por item de infraestrutura de baixo custo e prazo incerto.
- **Nada foi alterado** em schema, SPEC, canal de produção ou número. Canal Meta segue `active`, Z-API segue `disabled`.
- Estado do handoff atualizado: `.adapta-cliente/estado-atual.md` → `etapa: desvio_registrado_aguardando_consultora`.

## 2026-10-28 (2) — P2-S03-T04 adiantada: dois bugs de fila corrigidos e as duas provas que não dependem da Z-API

- Adiantadas as duas provas da T04 que **não** dependem de instância viva:
  - **Provedor fora do ar** → 5 tentativas até esgotar → `outbound_requests.status=failed` (attempts=5) + linha em `dead_letters` + mensagem arquivada.
  - **Conta não ativa** → bloqueio imediato com `conta_desconectada` (attempts=0) e dead letter; a outra conta não é afetada.
- **BUG 1 (grave, encontrado nesta prova):** `dead_letters.organization_id` é NOT NULL e o consumidor não o enviava; o erro era **engolido** porque o retorno de `.insert()` não era checado. Consequência: **12.106 itens presos** na fila `dead_letter` com a tabela `dead_letters` VAZIA — a "fila de falha visível" exigida pela SPEC era invisível.
- **BUG 2 (grave):** a mensagem consumida nunca era arquivada no pgmq. Sucesso, reenfileiramento e falha saíam do laço sem `fila_arquivar`, então o pgmq devolvia a mesma mensagem após a vt e ela era reprocessada indefinidamente (itens vistos com `read_ct` **657** e **1579**). O `process-inbound-event` já arquivava corretamente; o consumidor de saída não.
- **BUG 3:** `dead_letters.ref_id` gravava o `msg_id` da fila, não o id do pedido — a linha da fila de falha ficava sem rastro. Corrigido para o id de `outbound_requests`.
- Corretiva publicada: Edge **`send-whatsapp-message` v4** (versão 9 no projeto), autossuficiente com os adaptadores meta/zapi inlined (o deploy por MCP não resolve imports relativos para `_shared/providers`).
- Fixtures removidas: `dead_letters`=0, pedidos `system_test`=0, canais de prova=0, fila de saída=0. Canais reais preservados: Meta `active`, Z-API `disabled`.
- Resta para fechar a T04: instância Z-API nova (pré-requisito do dono) → matriz dos dois provedores + desconexão real.
- Evidências: `.adapta-cliente/estado-atual.md`, `supabase/functions/send-whatsapp-message/index.ts` (v4) neste commit.

## 2026-10-28 — P2-S03-T02 FECHADA: canal Meta real funcionando ponta a ponta

- Aceite do owner: mensagem real "Teste novo" enviada do celular e recebida no CRM; resposta enviada pelo CRM chegou no celular. **SPEC P2-S03 agora só depende da T04**; fase 2 em **25/28 (89%)**.
- **Canal Meta Cloud API operacional**: webhook registrado **por API** (sem painel) com `POST /<APP_ID>/subscriptions` no app `CRM PS Estetica` (1063262590063176), verify token vindo do Vault, 7 campos inscritos; app **inscrito no WABA** 1068799338488708 via `POST /<WABA_ID>/subscribed_apps`. Antes só o app de terceiro "CRM Integrador" (926408486225074) estava inscrito.
- **BUG REAL corrigido (v4 do `webhook-whatsapp-meta`, commit `5c517cc`)**: o webhook gravava o recibo **sem `payload_ref`**. O consumidor `process-inbound-event` lê o payload exclusivamente por esse campo; com `null`, `extrairFromE164` devolvia `null` e **todo item era arquivado sem criar contato/conversa/mensagem** — e o recibo ficava `accepted`, escondendo a falha. A Z-API já fazia certo desde a emenda P2-S04. O `payload_hash` também passou a ser o SHA-256 do corpo real (antes era o hash do id do evento).
- **Prova end-to-end (dados reais, não simulados)**: mensagem do owner → `authored` recibo aceito com assinatura HMAC válida → fila `inbound_events` → consumidor criou contato *Felipe Moura* (+558183230311), conversa `novo_lead`, mensagem `Teste novo` e **ticket automático** pelo motor de roteamento; resposta pela RPC `send_human_message` (caminho da tela) → `outbound_requests` `sent` → `provider_message_status` **`sent` → `delivered`** voltando pelo webhook assinado.
- **Matriz de contrato revalidada do zero** (banco real): CA-02 idempotência (`aceitos:1 / duplicados:1` no mesmo evento), CA-03 assinatura inválida → **401** `assinatura_invalida` + recibo `rejected_signature` sem enfileirar, CA-04 phone_number_id desconhecido → **`rejected_unmapped`** e zero contatos/conversas criados, CA-07 janela 24 h, CA-08 evento >24 h → **`rejected_stale`**. Runners: **48/48** (Meta) e **94/94** (Z-API, regressão).
- **Correção de estado dos canais**: número real informado pela Graph API é **+55 81 98234-9927** (o CRM guardava `+5581983230311`, formato antigo sem o 9º dígito). Meta passou a `active` como dona do número; **Z-API para `disabled`** — instância `3FB216D8001501EE233C3249377B3B8D` responde `400 "To continue sending a message, you must subscribe to this instance again"`, trial venceu em 27/10 e o número migrou para o Cloud API (o índice único de número ativo impede os dois).
- **Instabilidade do editor de canais**: salvar o canal em `/admin/canais` **regenera o verify token** (comportamento da RPC), e reativar exige re-registrar o webhook na Meta. Se o canal for editado, o token novo precisa ser recolado (ou o registro refeito por API).
- **Limpeza**: fixtures de prova removidas (mensagens `prova ca02`, recibos e pedidos de saída de teste); ficou apenas o tráfego real do owner.
- evidências: `04_fase-atual/fase.md` (P2-S03-T02 ☑), runners `scripts/test_p2_s03_t02.mjs` e `scripts/test_p2_s03_t03.mjs`, commit `5c517cc` (webhook v4).

## 2026-10-27 (3) — P2-S07-T04: matriz do copiloto + demonstração ponta a ponta (fase 2 fechada)

- Matriz de 13 cenários no banco real (PS Recife) com fixture sintética: ticket na fila → oferta pelo cron → aceite → sugestão do copiloto em **7,86 s** → edição e envio → resolução. Guardião bloqueia preço; IA fora do ar → lista manual e envio manual funcionam.
- **ACEITE do owner (26/10, "teste ok")** — SPEC P2-S07 completa; fase 2 em **21/28 (75%)**.
- Correção registrada: `agent_key` real do copiloto é **AG-01** (`copiloto_padrao`), não AG-14.

## 2026-10-27 (3) — P2-S02 FECHADA: token Experts validado + bug `date_birth` corrigido

- Aceite do owner: "teste ok" (19:18). **SPEC P2-S02 COMPLETA (T01–T03)** — fase 2 em **24/28 (86%)**.
- Token Experts **sempre funcionou**: o erro era do teste (`net.http_get(url, headers)` do pg_net põe os headers no lugar dos *query params*, então o `Authorization` nunca era enviado — sintoma idêntico a token inválido).
- **Bug real corrigido (Edge v10)**: `lerPacienteMinimo` lia `birth_date`, mas a API devolve **`date_birth`** → `birth_masked` saía `null` em todo candidato.
- Cache `expert_patients_cache`: entradas antigas com `birth_masked: null` marcadas `invalidated=true`; regeneradas com `force_refresh: true`.

## 2026-10-27 (2) — P2-S07-T03: ACEITA (+ correção do agent_key na tela)

- Aceite do owner: "teste ok" (13:09). P2-S07-T03 fechada — fase 2 em **18/28 (64%)**.
- Correção: o set do prompt do copiloto está em `prompt_sets.agent_key = 'AG-01'` (`copiloto_padrao`), não `AG-14` como a SPEC nomeia — a tela consultava AG-14 e não achava nada, por isso o selo "Herdado da organização" não aparecia.
- Ciclo de prompt provado no banco real (PS Recife): publicar sem sandbox → **42501** `sandbox_reprovado`; sandbox 10/10 ok; publicar v1 → efetivo `propria`; Caruaru segue `organizacao`.

## 2026-10-27 (1) — P2-S07-T03: console de prompts com sandbox, publicação e volta

- Migration `p2_s07_t03_console_prompts` aplicada no Supabase real: 7 RPCs (rascunho, sandbox 10 casos, publicação, volta, listagem, efetivo, estatísticas) + tela `/admin/agentes`.

## 2026-10-26 (5) — P2-S04-T03: consumidor v10 com _shared reais (correção do deploy v9)

- O deploy v9 do `process-inbound-event` saiu com **STUB** do `expert-search` (a identificação voltaria `indisponivel` sempre). Corrigido no v10 com os módulos reais inlined.
- Lição de deploy: o bundle por MCP não resolve imports relativos para `_shared/` — gerar versão autossuficiente.

## 2026-10-26 (3) — P2-S04-T02/T03: anexo pendente diagnosticado + renderização de anexos

- **SINTOMA (owner, 16:20)**: foto mandada pelo WhatsApp não apareceu; o aviso "anexo pendente" ficou na tela.
- Diagnóstico: o payload real da Z-API traz `fromMe` e o anexo chega em campo diferente do mapeado; corrigido no webhook v5 (imageUrl + caption) e no consumidor v10.
- Renderização de anexos na conversa passou a usar o caminho do bucket privado com URL assinada.

## 2026-10-24 (8) — P2-S04-T04: matriz técnica de isolamento e repetição APROVADA

- Isolamento B→A provado no Supabase real com usuário sintético da clínica B (`teste.rls@ps-teste.local`, `sales`): conversa/mensagens da clínica A → **0 linhas**; controle positivo → 1 linha; Realtime herda as policies.
- Duplicatas: 10 entregas do mesmo evento → **1 gravada, 9 recusadas** (23505).
- Relatório: `artifacts/RELATORIO_P2_S04_T04_20261024.md`.

## 2026-10-24 (7) — P2-S04-T03 IMPLEMENTADA (identificação, recusa e anexos)

- Consumidor v4 (publicado como **v6** no Supabase real): identificação 1× por conversa nova com cache de 1 h (um→paciente, multiplos→ambiguo, provavel→provavel, zero→novo_lead, erro→indisponivel e a conversa segue).
- Recusa ("SAIR"/"parar"/"cancelar inscrição"/"não quero receber", comparação exata) → consent revogado + `opt_out`; o enqueue bloqueia automática/promocional para quem recusou.
- Anexos por *magic bytes* (JPEG/PNG/WebP/PDF/OGG/MP3, 16 MB), `scan_status=pending` (emenda antivírus — ClamAV não existe no Edge Runtime). Runner **63/63**, inclusive executável disfarçado de .pdf e EICAR recusados.

## 2026-10-24 (6) — P2-S04-T02: Edges publicadas + PROVA REAL do fluxo de conversa

- Deploy no Supabase real: `process-inbound-event` **v5** e `webhook-whatsapp-zapi` **v4**.
- Prova real: mensagem recebida → contato, conversa, mensagem e ticket criados; resposta pela tela entregue.

## 2026-10-24 (4) — P2-S04-T01 IMPLEMENTADA (tabelas de conversa + consumidor) + EMENDA P2-S03 (payload)

- Migration `p2_s04_t01_conversas` aplicada: `conversations` (estados §8.1, identificação, unicidade), `messages`, `message_attachments`, `conversation_events`, `consents`; bucket privado `webhook-payloads`.
- **Emenda P2-S03**: o webhook passou a gravar `payload_ref` (caminho do objeto no bucket), porque o consumidor lê o payload exclusivamente por ele.
- RLS por papel em todas as tabelas novas; Realtime habilitado em `conversations`/`messages`.

## 2026-10-24 (2) — P2-S03-T03 IMPLEMENTADA (adaptador e webhook da Z-API)

- Adaptador `_shared/providers/zapi.ts`: mapeamento por `type` (`ReceivedCallback` com `fromMe`/grupo ignorado, `DeliveryCallback`, `MessageStatusCallback`, `DisconnectedCallback`), segredo do caminho + `instanceId` em tempo constante, limite por conta.
- Edge `webhook-whatsapp-zapi` + `admin-test-channel`; envio por `send-text` com `Client-Token`.
- Runner 94/94.

## 2026-10-24 — CORREÇÕES EM CADEIA (MFA, canais, conexão Experts) + ACEITE P2-S03-T01

- **MFA (tela de segundo fator), 4 correções no dia**: (v3) `GET /user` devolve `factor_type` (não `type`) — o filtro não achava o fator e a tela caía em enroll, que exige AAL2 → 403; (v4) após o verify, `setSession` com a sessão AAL2 nova (a guarda lia o JWT antigo e entrava em loop); (v5) "mesmo erro" ao gravar era **sessão morta** no navegador (`session_not_found`) — Sair e logar de novo; (v6) falso negativo "Conexão com erro" — a RPC devolve `ok` e a tela comparava com `healthy`.
- **Canais**: token Experts e credenciais Meta gravados pelo app; wrapper `gen_random_bytes` (pgcrypto em `extensions`), `vault.create_secret`/`update_secret` (INSERT direto negado 42501), `p_display_name`, Client-Token como 2ª conexão `<instanceId>:client_token`.
- **Aceite P2-S03-T01** confirmado pelo owner.

## 2026-10-20 — P2-S03-T02 IMPLEMENTADA (v0.0.20; aguarda credenciais Meta no Vault para a troca real)

- Adaptador Meta `_shared/providers/meta.ts`: assinatura `X-Hub-Signature-256` HMAC-SHA256 em tempo constante, verificação GET `hub.mode`/`hub.verify_token`/`hub.challenge`, mapeamento `entry[].changes[].value` (mensagem e situação), stale > 24 h, envio de texto e modelo com timeout de 10 s sem retry interno.
- Edge `webhook-whatsapp-meta`, `enqueue-outbound-message` (janela 24 h → `blocked` `janela_fechada`, idempotência hash+minuto), `send-whatsapp-message` (lote 10, token do Vault, 5 tentativas/30 min → dead letter), `process-inbound-event`; `pg_cron` a cada 10 s.
- Runner 48/48.

## 2026-10-19 — P2-S03-T01 IMPLEMENTADA (v0.0.16; ACEITE CONFIRMADO 2026-10-24)

- Migration `p2_s03_t01_canais` APLICADA NO SUPABASE REAL: `channel_accounts` (única `(provider, external_account_id)` e `phone_e164` único entre active/paused/disconnected — um número ativo pertence a uma só clínica; trigger de `organization_id` coerente com a clínica), `webhook_receipts` (imutável, única `(provider, external_event_id)`, escrita só servidor), `provider_message_status` (imutável), `outbound_requests` (`idempotency_key` única), `dead_letters`; RLS por papel em todas. Filas pgmq criadas no banco real (5: inbound_events, outbound_messages, dead_letter + 2 DLQ).
- Migration `p2_s03_t01b_rpcs` APLICADA: `admin_save_channel_account` (owner/clinic_admin; normaliza E.164; recusa número ativo em outra clínica e ID externo duplicado; token → Vault; segredo do webhook gerado pelo sistema e devolvido UMA única vez), `admin_set_channel_status`, `admin_test_channel` (diagnóstico sanitizado, sem token na resposta).
- Tela `/admin/canais` com lista, cadastro Meta e Z-API, teste de conexão, pausar/reativar/desativar e segredo mostrado uma vez; rota com RequireRole + AAL2.
- Runner 18/18 (PGlite): 5 tabelas; segredo devolvido uma vez; upsert sem duplicar; RN-01; unicidade global do ID externo; sales não cria (42501); RLS (sales 0, owner 1); status via RPC; `vault:<uuid>`; sem token no diagnóstico; org divergente recusada; replay idempotente.
- Lições: `FOREACH IN ARRAY` não existe no PGlite; template literal JS come `\+`; `public.vault.secrets` é cross-database (usar `vault.secrets`); PGlite sem pgcrypto → fallback `public.gen_random_bytes`; grants SELECT antes de `SET ROLE` no teste RLS.
- Skip v0.0.16 (`f2ef528`) QA verde.

## 2026-10-19 — P2-S02-T03 IMPLEMENTADA (v0.0.15; aceite pendente)

- Tela `/pacientes/identificar` (4 estados, E.164 exibido, erro por code com `correlation_id` copiável) + cartão Clínica Experts em `/admin/conexoes` (RequireRole + AAL2).
- Emenda `p2_s02_t03_link_emenda`: sales/reception/post_sales/manager criam vínculo; `unlink_expert_patient` só owner/clinic_admin; `manual_provavel` confidence 0.7; contato de outra org recusado.

## 2026-10-19 — P2-S02-T02 (v0.0.13) e T01 (v0.0.12) IMPLEMENTADAS

- `_shared/providers/clinica-experts.ts`: ExpertGet com User-Agent próprio (anti-Cloudflare-1010), `x-correlation-id`, Bearer só no header, classificação de 4 formatos de erro, orçamento de 90/min por `x-ratelimit-remaining`, retry 2× em transitórios. Matriz 23/23.
- `_shared/providers/expert-search.ts`: busca em duas etapas (E.164 exata `per_page=10`; últimos 8 dígitos `per_page=50` + filtro de DDD → provável). Contrato da Edge `search-expert-patient`: `result_class`, `candidates`, `linked_patient_uuid`, `cache_hit`. Matriz 18/18 com carga de 200 buscas.

## 2026-10-19 — P2-S02-T01 IMPLEMENTADA (v0.0.12; falta teste real com token)

- Base da conexão Clínica Experts: leitura de segredo pelo Vault via RPC, cache de pacientes com TTL.

## 2026-10-18 — TELA DE SEGUNDO FATOR (v0.0.11) · P2-S01-T03/T04 (v0.0.8–v0.0.10) — SPEC P2-S01 COMPLETA

- Tela de segundo fator (extra fora da SPEC, pedido do owner): enroll QR + chave manual → verify; challenge → verify; unenroll de pendente; retorno `?next=` para `/admin`.
- `guards.tsx` (RequireAuth/RequireRole com AAL2 para owner/clinic_admin), app-shell, Inicio, AdminProtegido; `/signup` removida.
- `types.ts` do catálogo real; testes 12/12.

## 2026-10-18 — TELA DE SEGUNDO FATOR implementada (v0.0.11, extra fora da SPEC)

- Enroll (QR + chave manual), verify, challenge, unenroll de pendente e retorno `?next=`.

## 2026-10-18 — P2-S01-T04 implementada (v0.0.10)

- Prova de RLS e políticas de acesso por papel; testes integrados da fase 1.

## 2026-10-18 — P2-S01-T03 SINCRONIZADA no Skip (v0.0.8 + v0.0.9, QA verde)

- Guards de rota, app-shell e telas base sincronizadas no Skip; `/signup` removida.

## 2026-10-14 — FASE 2 LIBERADA (em paralelo ao fechamento da fase 1)

- 7 SPECs (P2-S01 a P2-S07) e 28 tasks liberadas, com prazos S01 14–18/10.

## 2026-10-14 — P2-S01-T01/T02 CONCLUÍDAS · FASE 2 LIBERADA (7 SPECs, 28 tasks)

- **T01 — base versionada** no repo do CRM: 19 migrations em `supabase/migrations/` com os timestamps EXATOS do histórico real (fonte `supabase_migrations.schema_migrations.statements` — SQL literal do banco, nunca reconstruído de memória); seed `20260929135430` NEUTRALIZADA.
- **T02 — hardening**: `handle_new_user` nunca concede papel; `profiles.role` deprecada e nullable (sem o `DROP NOT NULL` o trigger corrigido quebraria o próximo usuário); policy legada `USING(true)` eliminada. Runner 18/18. Cadastro público bloqueado ao vivo (42501).
- Fase 2 liberada com 7 SPECs e 28 tasks.

## 2026-10-14 — P2-S01-T02 CONCLUÍDA (primeira task da fase 2)

- Hardening de auth aplicado e provado: cadastro público bloqueado, trigger corrigido, policy legada eliminada.

## 2026-10-09 — P1-S05-T03 CONCLUÍDA · FASE 1 COMPLETA (16/16)

- Busca Experts com `normalize_e164` server-side (inválido 22023), cache TTL 1 h e unicidade `(clinic_id, phone_e164)`.
- Relatório executivo da fase 1: `artifacts/RELATORIO_EXECUTIVO_FASE1_CRM_20261009.pdf`.

## 2026-10-09 — P1-S05-T02 CONCLUÍDA

- Cache de pacientes Experts com TTL e invalidação; prova de tempo de resposta e de unicidade por clínica.

## 2026-10-09 — P1-S05-T01 CONCLUÍDA

- Contrato da busca de pacientes e normalização E.164 no servidor.

## 2026-10-09 — FASE 1 COMPLETA (16/16) · P1-S05 T02/T03

- Fase 1 fechada com as 5 SPECs e 16 tasks concluídas.

## 2026-10-09 — FASE 1 COMPLETA (16/16): P1-S01 tenancy · P1-S02 auth/RLS · P1-S03 admin · P1-S04 segredos/Vault · P1-S05 busca Experts

- 14 tabelas com RLS, 29 policies, 23 funções, 4 clínicas (PSC, PSJ, PSO, PSR) e 8 memberships ativas no fechamento.

## 2026-10-09 — FASE 1 COMPLETA (16/16)
