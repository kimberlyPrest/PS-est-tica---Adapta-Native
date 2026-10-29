# Changelog — CRM Estética (handoff)

## 2026-10-29 (2) — fase 3 liberada

- Fase 3 liberada: 7 SPECs (P3-S01 a P3-S07) e 24 tasks em `04_fase-atual/fase.md`, com índice e escopo da fase atualizados.
- Valores que dependem da clínica deixaram de ser pré-condição das tasks: entram como rascunho e são confirmados no teste da SPEC.
- O contrato comum da fase 2 vale também para a fase 3, inclusive o teste do cliente na última task de cada SPEC.
- Os três testes do cliente que restam da fase 2 (P2-S02-T04, P2-S03-T04 e P2-S07-T04) não travam a fase 3.

## 2026-10-29 — teste do cliente por SPEC

- Contrato comum da fase 2 (seção 8): o aceite humano ("teste ok") passa a ser um por SPEC, na última task dela; capturas e gravações das outras tasks são do agente e não pedem nada ao cliente.
- `fase.md`: P2-S03-T01, P2-S04-T02 e P2-S04-T03 fechadas, cobertas pelos aceites das SPECs; P2-S02-T02 e P2-S02-T03 fecham junto com o teste da P2-S02-T04.
- Para fechar a fase 2 faltam o teste da P2-S02-T04, o roteiro final da P2-S07-T04 e a decisão sobre a P2-S03-T04 (ver `STATUS.md`).

## 2026-10-28 (3) — DESVIO registrado na SPEC: P2-S03-T04 depende de um segundo número

- O owner decidiu **registrar desvio formal** em vez de comprar um segundo número agora (28/10, 06:41).
- Motivo técnico, verificado na documentação da Meta: um número registrado no Cloud API **não pode** operar simultaneamente no aplicativo WhatsApp nem em API não oficial, e a exclusão do portfólio é caminho de ida — a ajuda do WhatsApp declara que número excluído não volta para outra conta da plataforma, além de apagar os dados do número. Não existe caminho técnico com um número só.
- Alternativa descartada e por quê: retirar `+55 81 98234-9927` da Meta para liberá-lo à Z-API. Destruiria o canal Meta recém-aceito na T02, apagaria o `phone_number_id` 707487385771432 (ao re-registrar vem outro), perderia o histórico do número e colocaria em risco não oficial o número de pós-procedimento da clínica.
- Documento criado: `06_notas/desvio-p2-s03-t04-segundo-numero.md` — com o problema em linguagem simples, o que já foi provado (CA-P2-S03-06 nas duas partes), o que falta, os três bugs corrigidos e **três opções** para a consultora decidir (aceitar prova por provedor; manter bloqueada; ou emendar a SPEC separando T04a/T04b).
- Recomendação técnica registrada: opção 1 ou 3. A opção 2 trava a fase 2 por item de infraestrutura de baixo custo e prazo incerto.
- **Nada foi alterado** em schema, SPEC, canal de produção ou número. Canal Meta segue `active`, Z-API segue `disabled`.
- Estado do handoff atualizado: `.adapta-cliente/estado-atual.md` → `etapa: desvio_registrado_aguardando_consultora`.

## 2026-10-28 (2) — P2-S03-T04 adiantada: dois bugs de fila corrigidos e as duas provas que não dependem da Z-API

- Decisão do owner: **caminho A** para a T04 — criar instância Z-API nova com número diferente em outra clínica (cumpre a SPEC literal). Bloqueio atual: a instância antiga está com trial vencido e o número migrou para o Cloud API.
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

- Matriz de 13 cenários no banco real (PS Recife) com fixture sintética: ticket na fila → oferta pelo cron → aceite → sugestão do copiloto em **7,86 s** (limite 10 s) → edição e envio pela atendente → resolução com próxima ação.
- Guardião: pedido de preço/desconto → `blocked / conteudo_proibido`, resposta nula e envio recusado (`sugestao_bloqueada`).
- IA indisponível: erro tratado, painel na lista manual e **envio manual mantém o ticket operável**.
- Indicador de uso por clínica: 9 geradas, 1 editada (11,1%), 1 bloqueada.
- Fixtures removidas (0 contatos/conversas remanescentes); presença do owner voltou a offline.
- **SPEC P2-S07 COMPLETA (4/4). Fase 2 em 21/28 (75%)** — restam P2-S02 (token Experts) e P2-S03-T02/T04 (credenciais Meta), bloqueadas por credenciais do dono.
- Achados da fixture: `contacts.primary_phone_e164` é obrigatório para envio (contato sem telefone quebra `send_human_message` na FK de `outbound_requests`); `conversations.status` exige `new/triaging/resolved/spam/opted_out` quando não há owner/team; `resolve_ticket` só aceita `atendido/agendamento_encaminhado/sem_resposta_cliente/spam/transferido_outra_clinica`.

## 2026-10-27 (3) — P2-S02 FECHADA: token Experts validado + bug `date_birth` corrigido

- Aceite do owner: "teste ok" (19:18). **SPEC P2-S02 COMPLETA (T01–T03)** — fase 2 em **24/28 (86%)**.
- Token do painel (Configurações → Integrações → aba Tokens) gravado pelo owner em Administração → Conexões → PS Recife → "Trocar token"; ref novo no Vault (`11b03308-…`, 48 chars ASCII).
- **Autenticação provada contra a API real**: `GET https://api.clinicaexperts.com.br/api/v1/patients?phone=5581989859531` → **200** com paciente real; idem etapa (b) por últimos 8 dígitos. Doc oficial: `https://clinicaexperts.readme.io` (Bearer).
- **Erro de diagnóstico (registrado para não repetir)**: eu testava via `pg_net` chamando `net.http_get(url, headers)` — a assinatura é `net.http_get(url, params, headers)`, então os cabeçalhos iam no lugar dos query params e o `Authorization` **nunca era enviado**. Toda chamada chegava sem token → 401 idêntico ao de token inventado, o que me levou a concluir erradamente que a chave era inválida. Regra: provar o eco dos headers com `httpbin.org/headers` antes de acusar o provedor.
- **BUG REAL corrigido**: `lerPacienteMinimo` lia `bruto.birth_date`, mas a API devolve **`date_birth`** (doc oficial + resposta real) → `birth_masked` saía `null` em todo candidato. Fix tolerante (`date_birth` primeiro, `birth_date` como fallback). Edge `search-expert-patient` **v10** publicada (v9 intermediária era placeholder — corrigida na mesma sessão).
- Prova ponta a ponta pelo caminho do app (login → Edge): `{"result_class":"um","candidates":[{"name":"Abel Luiz da Silva","birth_masked":"**/**/1965","active":false}]}`.
- Cache `expert_patients_cache`: entradas antigas com `birth_masked: null` marcadas `invalidated=true` para regenerar.
- Código versionado no handoff: `supabase/functions/_shared/providers/clinica-experts.ts`, `expert-search.ts` e `search-expert-patient/index.ts` (commit `defed98`).

## 2026-10-27 (2) — P2-S07-T03: ACEITA (+ correção do agent_key na tela)

- Aceite do owner: "teste ok" (13:09). P2-S07-T03 fechada — fase 2 em 18/28 (64%).
- Correção: o set do prompt da T01 usa `prompt_sets.agent_key = 'AG-01'` (não `AG-14`, que é o código da SPEC). A tela consultava a chave errada e abria sem selo de origem e sem texto.
- Fix (Skip v0.0.59): constante `AGENTE_COPILOTO='AG-01'`; editor preenchido com o texto em uso; histórico com coluna Origem; aviso quando nenhum prompt publicado existe.
- Migration `p2_s07_t03b_list_versions_origem`: `admin_list_prompt_versions` devolve `origem` (propria/organizacao) por linha.
- Ciclo provado no banco real (PS Recife): publicar sem sandbox → 42501 `sandbox_reprovado`; sandbox 10/10; publicar v1 → efetivo `propria`; Caruaru segue `organizacao`; fixture removida.
- Lição: conferir `prompt_sets.agent_key` no banco antes de fixar a chave do agente na tela — o código da SPEC (AG-14) não é a chave usada no seed (AG-01).

## 2026-10-27 (1) — P2-S07-T03: console de prompts com sandbox, publicação e volta

- Migration `p2_s07_t03_console_prompts` aplicada no Supabase real: 7 RPCs (rascunho, sandbox 10 casos, publicação com trava de sandbox, volta de versão, histórico, efetivo com origem, stats de uso) + `_guardiao_sandbox` (espelho SQL do guardião da Edge). Runner PGlite 25/25.
- Telas (Skip v0.0.58): aba "Instruções do copiloto" em /admin/agentes (editor + sandbox + publicar + voltar + herança + histórico) e indicador de uso do copiloto em /filas (30 dias).
- Pendência: aceite do Felipe → T04 fecha a fase 2.

## 2026-10-26 (5) — P2-S04-T03: consumidor v10 com _shared reais (correção do deploy v9)

- RETESTE (owner): foto de OUTRO celular → recibo 'ignored' no banco. Payload real lido via probe-payload (Edge temporária de diagnóstico): a Z-API real manda **image.imageUrl** (não link/url/id) e a legenda em **image.caption** — o adaptador (zapi.ts) e o consumidor (extrairMidia/extrairTexto) só aceitavam id/link/url → unsupported → ignorada.
- FIX: zapi.ts v3 (midiaIdDe aceita id/imageUrl/link/url; texto = text.message OU caption da mídia), consumidor process-inbound-event v9 (extrairMidia lê imageUrl; extrairTexto lê caption), webhook-whatsapp-zapi v5 publicado com o adaptador corrigido.
- PROVA REAL: foto da Milena Araujo (3A894590...) reprocessada → mensagem content_type=image com a legenda "Esses que ela passou pra mim hj", anexo gravado no bucket (scan_status=pending) e renderizada na tela Conversa (screenshot no chat). Conversa real preservada.
- Limpeza: membership temporária do usuário de teste removida; probe-payload permanece (deletar junto com probe-egress-experts quando encerrar o diagnóstico).
- Lição: NUNCA presumir o formato do payload do provedor — validar com payload REAL capturado (probe de leitura do bucket) antes de escrever o parser.

## 2026-10-26 (4) — P2-S04-T03: BUG da mídia Z-API corrigido (imageUrl) — foto recuperada

- RETESTE (owner): foto de OUTRO celular → recibo 'ignored' no banco. Payload real lido via probe-payload (Edge temporária de diagnóstico): a Z-API real manda **image.imageUrl** (não link/url/id) e a legenda em **image.caption** — o adaptador (zapi.ts) e o consumidor (extrairMidia/extrairTexto) só aceitavam id/link/url → unsupported → ignorada.
- FIX: zapi.ts v3 (midiaIdDe aceita id/imageUrl/link/url; texto = text.message OU caption da mídia), consumidor process-inbound-event v9 (extrairMidia lê imageUrl; extrairTexto lê caption), webhook-whatsapp-zapi v5 publicado com o adaptador corrigido.
- PROVA REAL: foto da Milena Araujo (3A894590...) reprocessada → mensagem content_type=image com a legenda "Esses que ela passou pra mim hj", anexo gravado no bucket (scan_status=pending) e renderizada na tela Conversa (screenshot no chat). Conversa real preservada.
- Limpeza: membership temporária do usuário de teste removida; probe-payload permanece (deletar junto com probe-egress-experts quando encerrar o diagnóstico).
- Lição: NUNCA presumir o formato do payload do provedor — validar com payload REAL capturado (probe de leitura do bucket) antes de escrever o parser.

## 2026-10-26 (3) — P2-S04-T02/T03: anexo pendente diagnosticado + renderização de anexos

- SINTOMA (owner, print 16:20): foto mandada pelo WhatsApp não apareceu; "o anexo pending não está presente".
- DIAGNÓSTICO no banco: NENHUM recibo de webhook entre 19:18 e 19:27 UTC — a Z-API NÃO notificou a imagem (o pipeline não a recebeu). 134 mensagens do dia, todas text.
- PIPELINE DE IMAGEM PROVADO à parte: webhook sintético ReceivedCallback com image{id,link} → recibo accepted → conversa criada (selo ambiguo p/ número de teste com 2 identidades) → mensagem content_type=image. Fixtures limpas.
- MELHORIAS (v0.0.30, 1ab6b09, QA verde): tela Conversa agora renderiza anexos — imagem via URL assinada (1h), não-imagem como link "Abrir anexo", aviso "Antivírus: verificação pendente" quando scan_status=pending; migration p2_s04_t02b_storage_attachments_read (membros ativos da clínica leem o bucket attachments por foldername[3]=clinic_id).
- CAUSA PROVÁVEL da foto perdida: mensagem enviada pelo PRÓPRIO número conectado (fromMe) não gera ReceivedCallback por padrão (Z-API: opção "Notificar as enviadas por mim também" desligada) OU falha pontual da trial. Reteste: foto DE OUTRO celular PARA o número do canal.
- FIX APLICADO (26/10): update-notify-sent-by-me = true na instância Z-API (resposta {"value":true}) — mensagens enviadas pelo próprio número agora também geram ReceivedCallback.
- Doc Z-API: mídia fica 30 dias no storage deles; link vem no objeto image/audio/video/document do ReceivedCallback.

## 2026-10-24 (8) — P2-S04-T04: matriz técnica de isolamento e repetição APROVADA

- Isolamento B→A provado no Supabase real com usuário sintético da clínica B (teste.rls@ps-teste.local, sales só Caruaru): SELECT na conversa da A → 0 linhas; SELECT nas mensagens da A → 0 linhas; controle positivo (própria conversa) → 1 linha; Realtime (conversations/messages publicadas) herda as mesmas policies de SELECT — assinatura de B no canal da A não recebe nada.
- Repetição em lote: 10 INSERTs idênticos → 1 gravada, 9 recusadas (23505, UNIQUE provider_message_id); consumidor v4 trata duplicata arquivando sem erro (runner 63/63).
- Fixtures sintéticas criadas e LIMPAS ao final (banco: 0 conversas, 0 mensagens, fila vazia). Objeto t04/duplicata.json (só metadado) ficou no bucket — exclusão via SQL bloqueada pelo trigger do storage.
- Relatório: artifacts/RELATORIO_P2_S04_T04_20261024.md.
- T04 segue ABERTA: pendem aceites humanos T01/T02/T03 + demonstração com a recepção ("teste ok").

## 2026-10-24 (7) — P2-S04-T03 IMPLEMENTADA (identificação, recusa e anexos)

- Consumidor v4 (publicado como **v6** no Supabase real): passo 5 — identificação 1× por conversa nova com cache (TTL 1h) e mapeamento da P1-S05 (um→paciente, multiplos→ambiguo, provavel→provavel, zero→novo_lead); qualquer falha da API externa → `indisponivel` e a conversa SEGUE (RN-P2-S04-02); passo 6 — palavras de saída (sair/parar/cancelar inscrição/não quero receber, comparação exata trim+lowercase) → consents(promocional, revoked) + evento opt_out; passo 7 — mídia baixada do provedor, tipo real conferido por magic bytes (JPEG FFD8FF, PNG 89504E47, WebP RIFF+WEBP, PDF %PDF, OGG OggS, MP3 ID3/FF), executável disfarçado (MZ/ELF) e EICAR recusados com evento attachment_rejected; aprovado → bucket privado attachments + message_attachments com scan_status pending (emenda antivírus autorizada — varredura externa).
- enqueue-outbound-message v2 (publicado como **v3**): conferência de recusa para TODAS as origens (RN-P2-S04-06) — contato com promocional=revoked: origem human em conversa aberta pelo próprio contato passa (atendimento); auto_reply/followup/campaign/system_test bloqueados com `recusa_do_contato` + outbound_request blocked; origin validado (5 valores) com padrão human.
- Bucket privado `attachments` criado (migration p2_s04_t03_bucket_anexos: 6 mimes GATE-04, limite 16MB).
- Runner scripts/test_p2_s04_t03.mjs **63/63** — incluindo provas funcionais reais: magic bytes com bytes de verdade (JPEG/PNG/PDF/WebP/OGG/MP3 ok; MZ e ELF disfarçados de .pdf recusados; EICAR recusado), mapeamento do selo e palavras de saída (SAIR maiúsculo dispara, "quero sair hoje" NÃO dispara).
- Correção durante a implementação: conferência de recusa usava contatoId/toE164 antes de serem definidos — movida para depois da resolução do destino.

## 2026-10-24 (6) — P2-S04-T02: Edges publicadas + PROVA REAL do fluxo de conversa

- Migration p2_s04_t02_realtime_send APLICADA NO SUPABASE REAL: conversations e messages adicionadas à publicação supabase_realtime (canal privado autorizado pelas policies de SELECT da T01 — membro da clínica só vê o que é da clínica); RPC send_human_message(conversation_id, body) SECURITY DEFINER: checa is_clinic_member no banco, conversa aberta, janela de 24h SÓ para meta_cloud (Z-API passa direto), cria messages (outbound/user/queued) + outbound_requests (origin='human') com idempotência por conversa+conteúdo+minuto, registra evento na linha do tempo.
- App Skip v0.0.26 (02bd2f7) QA verde: telas /atendimento (lista com contato, selo de identificação, telefone mascarado, não lidas, situação, ordenada pela última mensagem) e /atendimento/:conversationId (histórico com situação ✓/✓✓/lido, eventos do sistema em cinza, caixa de resposta com Enter, aviso de erro da RPC); tempo real via canal clinic:<id> (nova mensagem recarrega a lista sem recarregar a página); item "Atendimento" no menu; clinic-selector exporta useClinicaAtiva (contexto); types.ts atualizado com consents/conversations/messages + send_human_message.
- Testes de tela (Vitest + Testing Library): Atendimento 4/4 (estado sem clínica, lista com selo/não lidas/telefone mascarado, estado vazio, erro sem quebrar) + Conversa 5/5 (histórico com situação, RPC com parâmetros certos, erro da RPC visível — falha não silenciosa, conversa sem acesso, botão desabilitado). Suíte completa 29/29 (regressão: Inicio 7, SegundoFator 5, IdentificarPaciente 8). Lições: jsdom sem localStorage/scrollIntoView (stub); projeto usa toBeTruthy (sem jest-dom); tela lê clínica do contexto (ClinicaProvider no teste).
- Pendência: aceite humano (gravação com duas clínicas lado a lado).

## 2026-10-24 (5) — P2-S04-T02 IMPLEMENTADA (caixa de entrada e conversa em tempo real)

- Migration p2_s04_t02_realtime_send APLICADA NO SUPABASE REAL: conversations e messages adicionadas à publicação supabase_realtime (canal privado autorizado pelas policies de SELECT da T01 — membro da clínica só vê o que é da clínica); RPC send_human_message(conversation_id, body) SECURITY DEFINER: checa is_clinic_member no banco, conversa aberta, janela de 24h SÓ para meta_cloud (Z-API passa direto), cria messages (outbound/user/queued) + outbound_requests (origin='human') com idempotência por conversa+conteúdo+minuto, registra evento na linha do tempo.
- App Skip v0.0.26 (02bd2f7) QA verde: telas /atendimento (lista com contato, selo de identificação, telefone mascarado, não lidas, situação, ordenada pela última mensagem) e /atendimento/:conversationId (histórico com situação ✓/✓✓/lido, eventos do sistema em cinza, caixa de resposta com Enter, aviso de erro da RPC); tempo real via canal clinic:<id> (nova mensagem recarrega a lista sem recarregar a página); item "Atendimento" no menu; clinic-selector exporta useClinicaAtiva (contexto); types.ts atualizado com consents/conversations/messages + send_human_message.
- Testes de tela (Vitest + Testing Library): Atendimento 4/4 (estado sem clínica, lista com selo/não lidas/telefone mascarado, estado vazio, erro sem quebrar) + Conversa 5/5 (histórico com situação, RPC com parâmetros certos, erro da RPC visível — falha não silenciosa, conversa sem acesso, botão desabilitado). Suíte completa 29/29 (regressão: Inicio 7, SegundoFator 5, IdentificarPaciente 8). Lições: jsdom sem localStorage/scrollIntoView (stub); projeto usa toBeTruthy (sem jest-dom); tela lê clínica do contexto (ClinicaProvider no teste).
- Pendência: aceite humano (gravação com duas clínicas lado a lado).

## 2026-10-24 (4) — P2-S04-T01 IMPLEMENTADA (tabelas de conversa + consumidor) + EMENDA P2-S03 (payload)

- Migration p2_s04_t01_conversas APLICADA NO SUPABASE REAL: conversations (estados §8.1, identificação, unicidade de conversa aberta por contato+canal, check RN-03), messages (idempotência por (provider, provider_message_id), direção/sender coerentes), message_attachments (GATE-04: 6 mimes, 16MB), conversation_events (linha do tempo imutável), consents (valor vigente = mais recente) + fila pgmq agent_jobs + RPC register_consent + RLS (leitura por membro da clínica; escrita só servidor).
- EMENDA P2-S03 (autorizada pelo owner): bucket privado webhook-payloads criado; webhooks Meta e Z-API gravam o corpo bruto (payload_ref) e o envelope da fila leva ref_id — destrava o conteúdo da mensagem para o consumidor (o envelope nunca carrega texto).
- Consumidor process-inbound-event v3: recibo+conta → contato por contact_identities (ambíguo usa o mais recente e registra evento, sem fundir) → cria contato se novo → abre/reaproveita conversa aberta → grava mensagem (duplicata 23505 tratada) → palavra de saída registra consent revogado → contadores + enfileira agent_jobs (P2-S06 consome).
- Runner scripts/test_p2_s04_t01.mjs 44/44 (PGlite: instalação limpa, constraints, RLS com grants, consent vigente, trigger de coerência org/clínica).
- Pendências: deploy das 3 Edges emendadas (webhook-whatsapp-meta, webhook-whatsapp-zapi, process-inbound-event v3) no Supabase real; aceite humano (conferência das tabelas no Table Editor).
- 2026-10-24 · [Felipe] · Task P2-S03-T03 concluída: troca real Z-API provada — mensagem recebida pelo sistema (3 recibos accepted), envio pelo sistema chega no celular (confirmado pelo owner), situação sent/read registradas; canal ativo e saudável. Correções em cadeia durante o aceite: T01f/T01g (Client-Token como segunda conexão no Vault), _edge_read_secret lendo vault.decrypted_secrets (a tabela devolve o cifrado!), emenda DeliveryCallback no adaptador. Runner 94/94 + regressões 48/48 e 18/18.

## 2026-10-24 (3) — P2-S03-T03 CONCLUÍDA (aceite humano da troca real Z-API)

- 2026-10-24 · [Felipe] · Task P2-S03-T03 concluída: troca real Z-API provada — mensagem recebida pelo sistema (3 recibos accepted), envio pelo sistema chega no celular (confirmado pelo owner), situação sent/read registradas; canal Z-API ativo e saudável. Correções em cadeia durante o aceite: T01f/T01g (Client-Token como segunda conexão no Vault), _edge_read_secret lendo vault.decrypted_secrets (a tabela devolve o cifrado!), emenda DeliveryCallback no adaptador. Runner 94/94 + regressões 48/48 e 18/18.

## 2026-10-24 (2) — P2-S03-T03 IMPLEMENTADA (adaptador e webhook da Z-API)

- Adaptador `supabase/functions/_shared/providers/zapi.ts`: mapeamento por type (ReceivedCallback com fromMe/isGroup/isNewsletter, MessageStatusCallback com ids[]+status SENT/RECEIVED/READ/PLAYED, DisconnectedCallback, ConnectedCallback), external_event_id (messageId / ids[0]:status / instanceId:momment), stale por momment >24h, envio POST api.z-api.io/instances/<id>/token/<token>/send-text com Client-Token (token no caminho NUNCA em log), segredo do webhook em comparação em tempo constante.
- Edge `webhook-whatsapp-zapi` (rota pública sem JWT): proteção por caminho ?ca=<channel_account_id>&k=<segredo> contra o Vault via _edge_read_secret; instanceId do corpo == external_account_id da conta; limite 120 pedidos/min por conta → 429 rejected_rate; recibos idempotentes (provider, external_event_id); DisconnectedCallback → conta disconnected + last_error_code (RN-07); ConnectedCallback NUNCA reativa automaticamente (só admin via Reativar).
- `send-whatsapp-message` v2: escolhe o adaptador pelo provider da conta; branch Z-API (send-text); Client-Token lido da segunda conexão (connection_key <instanceId>:client_token); segredos via RPC _edge_read_secret; provider_message_status com provider da conta.
- `process-inbound-event` v2: recibo buscado pelo provider do envelope (meta_cloud | z_api).
- Edge `admin-test-channel` (nova): teste de conexão REAL de rede para os dois provedores (Meta GET /<phone_number_id>; Z-API GET /instances/<id>/token/<token>/status), diagnóstico sanitizado, atualiza last_status_at/last_error_code.
- Runner `scripts/test_p2_s03_t03.mjs` 94/94; regressão Meta 48/48 e T01 18/18 verdes; sintaxe TS dos 5 arquivos verificada (transpile).
- Publicado no Supabase real (webhook-whatsapp-zapi v1, admin-test-channel v1, send v3, process v3) com provas de fumaça: sem ca/k → 401; ca inexistente → 401; canal inexistente → 403. Skip v0.0.24 (ca2053a) + v0.0.25 (7b3594a, remove probe de diagnóstico) — QA verde.
- Pendências: credenciais Z-API no Vault (via /admin/canais) + URL do webhook no painel da Z-API + troca real de mensagem (passo 4). DÚVIDA do INTERNAL_JOB_SECRET no cron arrastada da T02 (06_notas) — afeta os dois provedores.

## 2026-10-24 — CORREÇÕES EM CADEIA (MFA, canais, conexão Experts) + ACEITE P2-S03-T01

- **MFA (tela de segundo fator), 4 correções no dia**: (v3) GET /user retorna `factor_type` (não `type`) — filtro aceita ambos, Skip v0.0.21 (0d14de2); (v4) verify devolve NOVA SESSÃO AAL2 e a tela não persistia — guarda de rota devolvia em loop; fix `setSession` após verify, v0.0.22 (a4bd85a); (v5) "mesmo erro" ao gravar = sessão morta no navegador (session_not_found 403) — Sair → login fresco resolve; (v6) "Conexão com erro" falso negativo — RPC devolve `health_status='ok'` e a tela comparava com 'healthy'; fix aceitar ok|healthy, v0.0.23 (99cdb63). Testes de tela 20/20.
- **P2-S03-T01 (cadastro de canal), 3 correções em cadeia**: (T01c) `gen_random_bytes` vive no schema `extensions` e a RPC chamava sem qualificar → wrapper `public.gen_random_bytes` (commit 1534b87); (T01d) gravação do segredo do webhook via INSERT direto em `vault.secrets` é negada ao postgres → `vault.create_secret/update_secret` com description '' (NOT NULL no real) (b26e992); (T01e) INSERT usava variável inexistente `v_display_name` → `p_display_name` direto (a50ee57).
- **ACEITE P2-S03-T01 CONFIRMADO (11:49)**: caminho completo pelo owner (cadastro dados de teste +5581900000001/TESTE-PID-0001 → segredo webhook único → teste conexão "Credencial gravada"). Banco: 1 canal draft, 1 conexão canal_meta_cloud, 1 segredo webhook. Nota: Pausar/Reativar só aparecem com status active/paused (draft não tem — comportamento correto da SPEC).
- **Item 4 do roteiro (token Experts) — gravado pelo app (16:00)**: conexão clinica_experts/api_token criada na PS Recife + auditoria save_secret v1. Conexão é POR CLÍNICA.
- **Busca real (Identificar paciente), 2 causas corrigidas**: (1) schema `vault` NÃO está exposto na API PostgREST — supabase-js com service key não lê `vault.secrets` → nova RPC `public._edge_read_secret(p_secret_ref)` SECURITY DEFINER, grants só service_role (migration T03b, a573596); (2) token colado com quebra de linha (`\n` na posição 77) → header HTTP inválido → TypeError → "falha de rede" — a RPC agora sanitiza TODO whitespace do segredo. Edge Function search-expert-patient **v8** publicada (leitura via RPC; deploy via MCP exige deno.json incluído no bundle). Probe de egress provou que o Edge Runtime alcança a API (401 em 216ms).
- **Estado da busca**: pipeline provado até a leitura do token (erro correto "credencial" 503 sem token). O segredo original foi corrompido (quebra colada + updates de diagnóstico) e deletado — **owner precisa RECOLAR o token** em /admin/conexoes → Gravar token (clínica PS Recife no seletor); a sanitização da RPC cobre pastes futuros. Depois: Testar conexão + busca (81) 90000-0002.
- **Lições**: nunca assumir formato do supabase-js vs GoTrue real (factor_type); sessão morta no navegador imita bug de app — provar GET /user com o JWT do localStorage; vault.secrets só via API da extensão; update_secret do real tem comportamento não determinístico para regravação — preferir create_secret novo + update da conexão (a RPC admin_save_integration_secret já faz isso); schema vault não exposto na API — Edge Functions leem segredos via RPC SECURITY DEFINER.

## 2026-10-20 — P2-S03-T02 IMPLEMENTADA (v0.0.20; aguarda credenciais Meta no Vault para a troca real)

- Adaptador Meta `supabase/functions/_shared/providers/meta.ts`: assinatura X-Hub-Signature-256 HMAC-SHA256 com comparação em tempo constante; verificação GET (hub.mode/hub.verify_token/hub.challenge → 200 challenge | 403); mapeamento de mensagens (wamid, E.164, nome do contato, texto, media_id, tipos suportados/não suportados) e situações (sent/delivered/read/failed + error_code, external_event_id `wamid:status`); lote com múltiplos itens; stale >24h; corpos de envio texto e modelo (Graph API, versão configurável); timeout 10s sem retry interno (a fila controla).
- Edge Function `webhook-whatsapp-meta` (rota pública sem JWT): GET verifica verify_token contra os segredos no Vault das contas Meta ativas; POST valida assinatura → 401 inválida (recibo rejected_signature) / 200 válida (mesmo duplicata — RN-P2-S03-02/03); recibos idempotentes por item (única (provider, external_event_id)); rejected_unmapped (número sem conta), rejected_stale (>24h), ignored (tipo não suportado); situações → provider_message_status (upsert); mensagens → fila inbound_events (envelope do contrato comum, sem conteúdo).
- Edge Function `enqueue-outbound-message` (JWT de usuário): conta ativa obrigatória (RN-P2-S03-07), destino normalizado E.164 server-side, janela 24h — texto livre só com entrada <24h, fora → outbound_request `blocked` com `janela_fechada` (RN-P2-S03-06, CA-P2-S03-07); idempotency_key = hash(canal+destino+kind+conteúdo+minuto); enfileira em outbound_messages.
- Edge Function `send-whatsapp-message` (consumidor, header x-internal-job): lote 10, lê outbound_request pelo ref_id, token do Vault, envia pelo adaptador, grava provider_message_id + status sent + provider_message_status; falha → reenfileira até 5 tentativas em 30min, depois dead_letters + fila dead_letter.
- Edge Function `process-inbound-event` (consumidor): confirma processamento do recibo accepted e arquiva da fila (P2-S04 completa a conversa).
- pg_cron ativo no Supabase real: jobs `p2-consumidor-outbound` e `p2-consumidor-inbound` a cada 10s via net.http_post. INTERNAL_JOB_SECRET configurado como Edge Function secret no Skip (DÚVIDA registrada no relatório: o contrato pede o segredo no header do cron, mas o Vault SQL não aceita INSERT do postgres — emenda candidata para a consultora definir o mecanismo).
- Runner `scripts/test_p2_s03_t02.mjs` 48/48 (Node + strip-types, fetch stub com gancho de cenário): assinatura (4 casos), verificação GET (3), mapeamento (texto/mídia/raro/4 situações/lote 3/stale/não mapeado), corpos de envio, envio ok/erro com sanitização, decisão de recibo, janela 24h, envelope de fila sem conteúdo, telemetria sem corpo/token.
- Skip v0.0.20 (831653d) QA verde. Relatório: `05_entregas/RELATORIO_P2_S03_T02_20261020.md`. Pendências para fechar: credenciais Meta no Vault (via /admin/canais), webhook no painel da Meta, troca real de mensagem.

## 2026-10-19 — P2-S02-T01 IMPLEMENTADA (v0.0.12; falta teste real com token)

- Cliente HTTP da conexão REAL: supabase/functions/_shared/providers/clinica-experts.ts — expertGet (User-Agent próprio PSEstetica-CRM/1.0 (+supabase-edge) exigido pela borda Cloudflare; x-correlation-id; Bearer só no header), classifyExpertError (4 formatos do contrato: {error:{code,title,fields}} / {error:"..."} / {success:false,message} / cloudflare_error → credencial_invalida, bloqueio_de_borda, modulo_desabilitado, paciente_nao_encontrado, entrada_recusada, limite_externo, falha_transitoria, tempo_esgotado), httpDeErro (mapa 404/400/503/504/502), rateBudget.take (90/min; x-ratelimit-remaining < 10 → espera virada), retry 2× transitórios, telemetria sanitizada (token NUNCA sai), lerPacienteMinimo (só uuid/name/phone/birth/active/created; descarta documents/address/email/annotation/occupation).
- Matriz 23/23 (scripts/test_p2_s02_t01.mjs): 9 classificação + 6 http-por-code + 3 rateBudget + 3 leitor mínimo + User-Agent + smoke expertGet. Skip v0.0.12 (447a9e0) QA verde.
- Lição de sandbox: runner com servidor HTTP real + strip-types prende o event-loop — matriz pura + smoke com guarda de 3s resolve; deno test oficial fica para a CI do Skip.
- Pendências para FECHAR a T01: EXPERT_API_BASE_URL (secret) + token no Vault via /admin → teste de conexão real a partir da função publicada com diagnóstico sanitizado. Próxima: P2-S02-T02 (busca em duas etapas + limitador).

## 2026-10-19 — P2-S02-T02 (v0.0.13) e T01 (v0.0.12) IMPLEMENTADAS

- Busca em duas etapas: supabase/functions/_shared/providers/expert-search.ts — etapa (a) GET /patients?phone=<E.164 sem +>&per_page=10; etapa (b) se zero E número tem 9º dígito: GET com os últimos 8 dígitos &per_page=50, filtrando localmente pelo mesmo DDD (números antigos sem o 9º). Classificação: um / multiplos (2+, NUNCA escolhidos) / provavel (etapa b, mesmo DDD) / zero. Candidatos mínimos com birth_masked (**/**/AAAA). 429 propagado como limite_externo. Budget local parametrizável (90/min) para carga.
- Edge Function search-expert-patient v2: contrato de saída da SPEC (data{result_class, phone_e164, candidates[{expert_patient_uuid,name,birth_masked,active}], linked_patient_uuid, cache_hit}, correlation_id); cache TTL 1h grava só candidatos mínimos; base URL com default EXPERT_BASE_URL_DEFAULT; mantém JWT obrigatório, acesso por organização (RLS), erros sanitizados com correlation_id, falha_nao_bloqueia.
- Matriz 18/18 (scripts/test_p2_s02_t02.mjs): E.164 único → um (1 chamada); DDD+número casa por trecho; número antigo sem 9º → um; inexistente → zero; 2 candidatos → multiplos; 4 candidatos; birth_masked; inativo active=false; etapa (b) → provavel com 2 chamadas; etapa (b) DDD diferente → zero; máscaras; 429 → limite_externo; CARGA 200 buscas: nenhuma 429 propagada e budget reteve além de 90/min.
- Correção: scripts/test_p2_s02_t01.mjs apontava para caminho inexistente no repo — corrigido e revalidado (23/23 nos caminhos do repositório).
- Lição: comentário JSDoc com **/**/ fecha comentário de bloco no strip-types do Node — usar espaços.
- Skip v0.0.13 (1ec8b97) QA verde. Próxima: P2-S02-T03 (tela Identificar paciente + cartão de saúde) — implementável agora; teste com dado real quando o token chegar.

## 2026-10-19 — P2-S02-T03 IMPLEMENTADA (v0.0.15; aceite pendente)

- Tela /pacientes/identificar (IdentificarPaciente.tsx): campo aceita qualquer formato e mostra o E.164 normalizado (RPC normalize_e164) antes de buscar; os 4 resultados da SPEC — um (cartão nome/nascimento mascarado/selo Ativo-Inativo + Confirmar vínculo), multiplos (candidatos lado a lado com aviso "Mais de um cadastro usa este telefone", nenhum pré-selecionado), provavel (selo "Provável — confirmar" + motivo "número cadastrado sem o 9º dígito"), zero ("tratar como novo contato"); erros por code com correlation_id copiável; "Buscar de novo (ignorar cache)" com force_refresh; vínculo é SEMPRE decisão humana (RPC link_expert_patient; provavel grava manual_provavel).
- Cartão Clínica Experts em /admin/conexoes (AdminConexoes.tsx): situação Saudável/Com erro/Não configurada, último teste, Testar conexão (RPC admin_test_connection — leitura GET /rooms?per_page=1) com limite restante no diagnóstico, Trocar token (RPC admin_save_integration_secret — vai ao Vault e nunca volta a ser exibido). Rota com RequireRole owner/clinic_admin + AAL2.
- Emenda do vínculo humano APLICADA NO SUPABASE REAL (migration p2_s02_t03_link_emenda): link_expert_patient aceita owner/clinic_admin/manager/sales/reception/post_sales da clínica para CRIAR vínculo; unlink_expert_patient nova (só owner/clinic_admin desfaz); match_method manual (confidence 1.0) e manual_provavel (0.7); contato de outra organização recusado; grants só authenticated; checagem de papel direto em memberships (has_clinic_role não existe no banco real).
- Rotas e menu: /pacientes/identificar (todos os papéis com vínculo ativo) e /admin/conexoes (owner/clinic_admin) no menu lateral.
- Testes: tela 8/8 (4 resultados + E.164 + erro com correlation_id + 2 negativos de vínculo: contato inexistente e RPC recusa papel); suíte completa 20/20; runner da emenda 12/12 (PGlite: owner/sales/reception criam, viewer não, unlink só owner, confidence 0.7, contato de outra org, grants, replay idempotente).
- Lições: (1) has_clinic_role não existe no banco real — emendas devem checar papel direto em memberships; (2) QA do Skip roda oxlint — fechar it() com }) e não }; (3) PGlite: criar schema auth + auth.uid() e papéis anon/authenticated antes das migrations.
- Skip v0.0.15 (881cfcf) QA verde. Próxima: P2-S02-T04 (matriz com telefones reais + varredura de dado sensível) — precisa do token no Vault.

## 2026-10-19 — P2-S03-T01 IMPLEMENTADA (v0.0.16; ACEITE CONFIRMADO 2026-10-24)

- Migration p2_s03_t01_canais APLICADA NO SUPABASE REAL: channel_accounts (únicas (provider, external_account_id) e phone_e164 único entre active/paused/disconnected — um número ativo pertence a uma só clínica; trigger organization_id coerente com a clínica), webhook_receipts (imutável, única (provider, external_event_id), escrita só servidor — sem policy de INSERT para authenticated), provider_message_status (imutável), outbound_requests (idempotency_key única), dead_letters; RLS por papel em todas (recibos/mortas só owner/clinic_admin). Filas pgmq criadas no banco real (5: inbound_events, outbound_messages, dead_letter + 2 DLQ) — confirmadas em pgmq.pg_tables.
- Migration p2_s03_t01b_rpcs APLICADA NO SUPABASE REAL: admin_save_channel_account (owner/clinic_admin; normaliza E.164; recusa número ativo em outra clínica e ID externo global duplicado; token → Vault via admin_save_integration_secret; segredo do webhook gerado pelo sistema, guardado no Vault e devolvido UMA única vez), admin_set_channel_status (pausar/reativar/desativar), admin_test_channel (diagnóstico sanitizado LOCAL sem token na resposta; teste de rede real fica na Edge Function da T02/T03). Grants só authenticated.
- Tela /admin/canais (AdminCanais.tsx): lista com situação/última entrada/última saída/erro; cadastro Meta (phone_number_id, WABA, token, app secret) e Z-API (instanceId, token, Client-Token); teste de conexão; pausar/reativar/desativar; segredo do webhook mostrado UMA única vez com aviso de cópia. Rota com RequireRole owner/clinic_admin + AAL2; item "Canais WhatsApp" no menu.
- Runner 18/18 (scripts/test_p2_s03_t01.mjs, PGlite): 5 tabelas; segredo devolvido uma vez e nunca mais; upsert sem duplicar; RN-01; unicidade global do ID externo; sales não cria (42501); RLS (sales 0, owner 1); status via RPC; vault:<uuid>; sem token no diagnóstico; org divergente recusada; replay idempotente.
- Lições: FOREACH IN ARRAY não existe no PGlite (usar FOR x IN SELECT y FROM unnest(...) AS y); template literal JS come \+ (regex SQL com [+]); public.vault.secrets = cross-database (usar vault.secrets); PGlite sem pgcrypto → fallback public.gen_random_bytes; grants SELECT antes de SET ROLE no teste RLS.
- Skip v0.0.16 (f2ef528) QA verde. Próxima: P2-S03-T02 (webhook Meta + pg_cron + teste de rede real).

## 2026-10-18 — P2-S01-T03 SINCRONIZADA no Skip (v0.0.8 + v0.0.9, QA verde)

- Tipos `src/lib/supabase/types.ts` gerados do catálogo REAL do Supabase psestetica (pg_class/pg_attribute/pg_proc, 2026-10-18): 14 tabelas com Row/Insert/Update + 17 funções RPC tipadas + tipo `Papel` (7 papéis da SPEC).
- Componentes novos: `guards.tsx` (RequireAuth; RequireRole com exigência AAL2 para owner/clinic_admin; EmptyState; ErrorState com correlation_id copiável), `clinic-selector.tsx` (só clínicas com vínculo ativo via RLS; escolha em localStorage por conveniência, servidor sempre valida), `app-shell.tsx` (menu lateral por papel + topo com seletor e e-mail).
- Rotas: `/inicio` (painel sem números fixos; sem dado → estado vazio), `/admin` protegida (owner/clinic_admin + segundo fator), `/dashboard`→`/inicio`, `/signup` REMOVIDA (acesso só por convite).
- Testes de tela (Vitest + Testing Library): **7/7 verdes** — sem sessão→login; sem vínculo→"sem acesso"; com vínculo→conteúdo; papel insuficiente→"Acesso restrito"; owner sem AAL2→pede segundo fator; owner com AAL2→libera; EmptyState sem número fixo (RN-P2-S01-03).
- **0 `as any` em chamada ao Supabase** (verificado por varredura; único restante é comentário).
- Pendências: gravar os 8 arquivos no Skip (ferramentas indisponíveis nesta sessão — arquivos prontos em work/p2s01/src/); build `npm run build` no ambiente do app; capturas por papel (humano).
- Próxima: P2-S01-T04 (suíte de testes + CI) após sync no Skip.

## 2026-10-18 — TELA DE SEGUNDO FATOR implementada (v0.0.11, extra fora da SPEC)

- Contexto: no teste humano da T03, o owner era bloqueado em /admin com a tela estática "Segundo fator necessário" — não havia como ATIVAR o fator dentro do app (só pelo painel Supabase). Tela implementada a pedido do Felipe.
- Entrega (Skip 62134, v0.0.11 812ac41, QA verde: setup/static/build/integrations):
  - src/pages/SegundoFator.tsx: fluxo TOTP completo via supabase-js v2 — enroll (QR + chave manual + friendly_name), challenge, verify; unenroll automático de fator pendente anterior (não acumula); erros amigáveis (código inválido, rate limit, fator não encontrado); retorno automático ao destino original (?next=, default /admin).
  - guards.tsx: owner/clinic_admin sem AAL2 agora são REDIRECIONADOS a /segundo-fator?next=/admin (antes: tela estática).
  - src/lib/auth-errors.ts: mensagens amigáveis extraídas de use-auth (sem duplicar).
  - App.tsx: rota /segundo-fator. vitest.config.ts: alias @ (o app usa @/lib/...). package.json: @testing-library/user-event.
  - Testes: 12/12 (7 da guarda — incluindo owner sem AAL2 → /segundo-fator — e 5 da tela MFA: enroll, QR+chave, sucesso, código inválido, challenge direto).
- Lições de teste: mockar pelo MESMO caminho que o componente importa (@/lib/supabase/client); a chain mockada do from() precisa ser THENABLE (await em qualquer ponto resolve) — o erro real era "...eq(...).limit is not a function"; não usar vi.clearAllMocks() quando o mock é configurado no beforeEach.
- Como usar: /admin → redireciona a /segundo-fator → Gerar código QR → escanear no autenticador → código de 6 dígitos → verificado → Continuar → /admin abre.
- Próxima: aceite humano; depois P2-S02-T01 (token Clínica Experts no Vault).

## 2026-10-18 — P2-S01-T04 implementada (v0.0.10)

- package.json npm test → vitest run (antes era echo "no tests" — por isso qa.test.ran=false no Skip); vitest.config.ts (jsdom/globals); Inicio.test.tsx (7 testes); scripts/scan-secrets.mjs (5 padrões, exit 1 em achado; provas: 0 na árvore, JWT teste → exit 1). Prova da suíte: exit 0 verde / exit 1 com teste falho. Skip v0.0.10 (4f8b442) QA verde (test.ran=false é limitação do runner da plataforma). SPEC P2-S01 COMPLETA (T01–T04). Próxima: P2-S02-T01 (conexão real Clínica Experts) — pré-condição: token entregue pelo /admin no Vault. Pendências do dono seguem: toggles Auth (signup off + TOTP) e decisão sobre histórico Git.

## 2026-10-18 — TELA DE SEGUNDO FATOR (v0.0.11) · P2-S01-T03/T04 (v0.0.8–v0.0.10) — SPEC P2-S01 COMPLETA

- T03: 7 arquivos gravados no Skip (types do catálogo real, guards AAL2, clinic-selector, app-shell, /inicio, AdminProtegido, App sem /signup) + Index.tsx limpo (sem link de cadastro/credenciais expostas) + Dashboard/SignUp removidos → v0.0.8 (f299cf2); migration de convite higienizada → v0.0.9 (b215a07). QA verde.
- T04: npm test → vitest run (antes echo "no tests"); vitest.config.ts; Inicio.test.tsx (7); scripts/scan-secrets.mjs (5 padrões; provas 0 na árvore / JWT teste → exit 1). Prova da suíte: exit 0 verde / exit 1 com teste falho. v0.0.10 (4f8b442) QA verde.
- Diagnóstico "Administração não aparece": cache do navegador do Felipe — provado por login no preview via browser (screenshot artifacts/c3079d66). Captura do bloqueio "Segundo fator necessário" = aceite do passo 3.a.

## 2026-10-14 — FASE 2 LIBERADA (em paralelo ao fechamento da fase 1)

- Incluídas as SPECs P2-S01 a P2-S07 em `04_fase-atual/01-SPECS/`, com contrato técnico detalhado (tabelas coluna a coluna, regras de acesso, funções, filas, telas), TDD, critérios de aceite (53) e roteiro passo a passo das 28 tasks.
- Incluído `00-CONTRATO-COMUM-FASE-2.md`: convenções de banco, RLS, envelope de erro das funções, filas, interruptores, rotas de tela e provas.
- Incluído `03-Produto-e-Arquitetura/mapa-de-dados-clinica-experts.md` (API verificada ao vivo em 13/10/2026, somente leitura).
- `fase.md`, `jornada.md`, `escopo-da-fase.md`, índice, STATUS, estado atual, README, visão geral e manifesto atualizados.
- Nenhuma credencial incluída.

## 2026-10-14 — P2-S01-T01/T02 CONCLUÍDAS · FASE 2 LIBERADA (7 SPECs, 28 tasks)

- Aceite humano: "teste ok" (Felipe, 2026-10-14 22:43, canal web) após conferência no Skip: 3 pastas em supabase/functions/, 19 migrations em supabase/migrations/, versão 0.0.7 com QA 5/5, seed sem senha/e-mail.
- Entrega: repositório do CRM (Skip 62134) passa a conter a base da fase 1 — 19 migrations com os timestamps EXATOS do histórico real (fonte: supabase_migrations.schema_migrations do projeto psestetica; SQL literal, não reconstruído) + Edge Functions search-expert-patient (importa _shared/), _shared/clinic_experts_client (módulo T01 aceito) e admin-invite-user (recuperada da produção v2). Seed 20260929135430 neutralizada; corretiva de rename ganhou guarda para instalação limpa.
- Pendências operacionais registradas (não bloqueiam): diff formal vazio e replay dos runners exigem Supabase CLI (fora do sandbox); decisão do owner sobre histórico Git (senha antiga no commit inicial, já trocada no banco).
- Artefato: artifacts/RELATORIO_P2_S01_T01_20261014.md. Quadro atualizado (commit 2c736e0).
- Próxima: P2-S01-T02 (hardening) mediante pedido do dono. Prazos da fase 2: S01 16/10 · S02 20/10 · S03 22/10 · S04 26/10 · S05 28/10 · S06 30/10 · S07 04/11.

## 2026-10-14 — P2-S01-T02 CONCLUÍDA (primeira task da fase 2)

- Aceite humano: "teste ok" (Felipe, 2026-10-14 22:43, canal web) após conferência no Skip: 3 pastas em supabase/functions/, 19 migrations em supabase/migrations/, versão 0.0.7 com QA 5/5, seed sem senha/e-mail.
- Entrega: repositório do CRM (Skip 62134) passa a conter a base da fase 1 — 19 migrations com os timestamps EXATOS do histórico real (fonte: supabase_migrations.schema_migrations do projeto psestetica; SQL literal, não reconstruído) + Edge Functions search-expert-patient (importa _shared/), _shared/clinic_experts_client (módulo T01 aceito) e admin-invite-user (recuperada da produção v2). Seed 20260929135430 neutralizada; corretiva de rename ganhou guarda para instalação limpa.
- Pendências operacionais registradas (não bloqueiam): diff formal vazio e replay dos runners exigem Supabase CLI (fora do sandbox); decisão do owner sobre histórico Git (senha antiga no commit inicial, já trocada no banco).
- Artefato: artifacts/RELATORIO_P2_S01_T01_20261014.md. Quadro atualizado (commit 2c736e0).
- Próxima: P2-S01-T02 (hardening) mediante pedido do dono. Prazos da fase 2: S01 16/10 · S02 20/10 · S03 22/10 · S04 26/10 · S05 28/10 · S06 30/10 · S07 04/11.

## 2026-10-09 — P1-S05-T01 CONCLUÍDA

- Aceite humano: "teste ok" (Felipe, 2026-10-09, canal web) após roteiro roteiro-t01-cliente-v1-20261009.html (11 passos, módulo real embutido, API simulada local) validado 11/11 ✔ no navegador antes da entrega.
- Revalidação de fechamento com evidência fresca: runner scripts/test_s05_t01.mjs 21/21 (API simulada local); sha256 do módulo clinic_experts_client.mjs = 4b12c95a… (inalterado desde a implementação).
- Recortes provados: timeout por tentativa (AbortController) sem travar; rate limiter janela deslizante 120 req/min com 121ª chamada RETIDA (não rejeitada; espera não consome tentativa); retry/backoff máx. 3 para 5xx/timeout/rede; 429 respeita retry-after (persistente → rate_limit_externo); erros tipados ErroOperacional com correlation_id; telemetria sanitizada — varredura: 0 ocorrências do token em 127 telemetrias + 3 erros; 404 = zero resultados; múltiplos devolvidos por completo (classificação é da T02).
- Sem migration (módulo puro de rede). Edge Function search-expert-patient (T02) consumirá este módulo; token virá do Vault (SPEC P1-S04).
- Artefatos: artifacts/RELATORIO_P1_S05_T01_20261008.md · artifacts/roteiro-t01-cliente-v1-20261009.html · scripts/clinic_experts_client.mjs · scripts/test_s05_t01.mjs
- Fase 1: 13/16 (81,25%). Próxima: P1-S05-T02 (busca + normalização E.164 + deduplicação + vínculo humano + cache TTL), mediante pedido.

## 2026-10-09 — P1-S05-T02 CONCLUÍDA

- Migration p1_s05_t02_search_cache aplicada no Supabase (uhozizrpmmpemvegtqaq): função normalize_e164 (E.164 server-side; formatado BR/sem DDI/idempotente; 8 dígitos ganha 9º; inválido 22023); tabela external_patient_links (vínculo CONFIRMADO por humano — CHECK match_method IN ('manual'); dedup: UNIQUE (clinic_id, contact_id, expert_patient_uuid) + UNIQUE (clinic_id, expert_patient_uuid) com rebind sem duplicar; RLS leitura org / escrita writer); tabela expert_patients_cache (payload, result_class zero/um/multiplos/erro, expires_at TTL, invalidated, correlation_id; UNIQUE (clinic_id, phone_e164); RLS leitura org / escrita membro — dado derivado da busca); RPCs invalidate_expert_cache (normaliza telefone; idempotente) e link_expert_patient (só owner/clinic_admin; contato da mesma org; rebind sem duplicar); EXECUTE só authenticated.
- Edge Function search-expert-patient v1 deployada (verify_jwt): autentica JWT → normaliza via RPC → valida membro da org via RLS → consulta cache com TTL → chama API Clínica Experts pelo módulo T01 (timeout/rate limiter/retry; token lido do Vault via service role, NUNCA exposto) → classifica zero/um/múltiplos (múltiplos NUNCA escolhidos automaticamente) → grava cache TTL 1h. Erros sanitizados com correlation_id; falha não bloqueia conversa local (falha_nao_bloqueia).
- Verificação: runner scripts/test_s05_t02.js 22/22 (PGlite instalação limpa T01→T02; roles anon/authenticated; auth.uid via request.jwt.claims). Prova ao vivo: login owner OK; função autenticada → 503 api_nao_configurada + correlation_id (EXPERT_API_BASE_URL ainda não configurada — sem falso sucesso); sem JWT → 401.
- Correções no caminho: regex \d inválida no Postgres (usar [0-9]); DDI 55 com 13 dígitos; UUIDs de teste com 9 chars no 1º grupo; createClient exigia URL+key; import ESM no topo.
- Artefatos: artifacts/p1_s05_t02_search_cache.sql · artifacts/p1_s05_t02_edge_search_expert_patient.ts · artifacts/RELATORIO_P1_S05_T02_20261009.md
- Pendências: EXPERT_API_BASE_URL (env) + token real (via /admin→Vault) quando Felipe fornecer.
- Fase 1: 13/16 concluídas (81,25%); T02 aguarda teste humano. Próxima: P1-S05-T03 (fluxo demonstrável + matriz zero/um/múltiplos/falhas) — última da fase 1.

## 2026-10-09 — P1-S05-T03 CONCLUÍDA · FASE 1 COMPLETA (16/16)

- Aceite humano: "teste ok" (Felipe, 2026-10-09, canal web) após roteiro roteiro-t03-matriz-v1-20261009.html (17 passos) validado 17/17 ✔ no navegador antes da entrega.
- Parte A (Supabase real, sessão do owner): fixtures sintéticas de cache criadas pelo roteiro (0901–0904) e REMOVIDAS ao final (0 restantes, confirmado na revalidação); busca "um" via cache (HTTP 200), "zero" → novo lead, "múltiplos" → 2 resultados devolvidos SEM escolher (CA-P1-S05-01); cache expirado ignorado (TTL); invalidação explícita → cache não mais usado; busca sem cache → 503 api_nao_configurada com correlation_id, sem falso sucesso (CA-P1-S05-02); negativa de outra clínica: vendedor PSC→PSR → 403, controle na própria → 503; sem sessão → 401.
- Parte B (módulo T01 real embutido vs API simulada): 401→credencial, 422→entrada, 429→recupera no 3º esforço respeitando retry-after, timeout sem travar; varredura final: 0 ocorrências do token (CA-P1-S05-03).
- Revalidação de fechamento com evidência fresca: banco real (2 tabelas, 4 policies, 3 funções, 0 fixtures) + Edge Function ao vivo (owner 503 sanitizado correlation_id 52b4bf41; anon 401).
- **FASE 1 COMPLETA: 16/16 tasks (100%)** — SPECs P1-S01 (tenancy) · P1-S02 (auth/RLS) · P1-S03 (admin/organização) · P1-S04 (segredos/Vault) · P1-S05 (busca Clínica Experts) todas concluídas com aceite humano.
- Artefato: artifacts/roteiro-t03-matriz-v1-20261009.html (gerador scripts/gerar_roteiro_t03.mjs + template).
- Pendências operacionais: EXPERT_API_BASE_URL + token real da API Clínica Experts (via /admin→Vault) quando Felipe fornecer; até lá a função responde 503 sanitizado.
- Próxima: planejamento da fase 2 com o Felipe.

## 2026-10-09 — FASE 1 COMPLETA (16/16) · P1-S05 T02/T03

- P1-S05-T03 (aceite "teste ok", roteiro 17/17): matriz zero/um/múltiplos/falhas; fixtures removidas; token nunca exposto. FASE 1 COMPLETA: P1-S01 tenancy · P1-S02 auth/RLS · P1-S03 admin · P1-S04 segredos/Vault · P1-S05 busca.
- P1-S05-T02 (aceite "teste ok", roteiro 8/8): normalize_e164, external_patient_links (vínculo manual), expert_patients_cache (TTL), Edge Function search-expert-patient v1 (503 sanitizado sem token configurado; 401 anon).
- Pendências operacionais: EXPERT_API_BASE_URL + token real (suporte Clínica Experts; docs.nicochat.com confirma endpoint e Bearer).

## 2026-10-09 — FASE 1 COMPLETA (16/16): P1-S01 tenancy · P1-S02 auth/RLS · P1-S03 admin · P1-S04 segredos/Vault · P1-S05 busca

## 2026-10-09 — FASE 1 COMPLETA (16/16)
