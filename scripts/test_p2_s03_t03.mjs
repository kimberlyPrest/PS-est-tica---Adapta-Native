// scripts/test_p2_s03_t03.mjs — P2-S03-T03 (runner Z-API)
// Matriz da SPEC: mensagem recebida, enviada pelo aparelho (fromMe), grupo
// ignorado, situação (SENT/RECEIVED/READ), desconexão, reconexão (não reativa),
// segredo errado, instanceId trocado, repetição (idempotência), stale >24h,
// limite 120/min, envio send-text (stub) ok/erro, Client-Token ausente,
// sanitização (token/URL nunca em log). Provedor Z-API SIMULADO (fetch stub).
// Node ESM puro (lição do sandbox: sem servidor HTTP real + strip-types).
import { readFileSync, existsSync } from 'node:fs'

const ARQUIVO_ZAPI = 'work/p2s03/supabase/functions/_shared/providers/zapi.ts'
const ARQUIVO_WEBHOOK = 'work/p2s03/supabase/functions/webhook-whatsapp-zapi/index.ts'
const ARQUIVO_SEND = 'work/p2s03/supabase/functions/send-whatsapp-message/index.ts'
const ARQUIVO_TEST = 'work/p2s03/supabase/functions/admin-test-channel/index.ts'
const ARQUIVO_PROC = 'work/p2s03/supabase/functions/process-inbound-event/index.ts'

let passou = 0
let falhou = 0
const falhas = []
function check(nome, cond, detalhe = '') {
  if (cond) {
    passou++
    console.log(`  ✓ ${nome}`)
  } else {
    falhou++
    falhas.push(`${nome}${detalhe ? ` — ${detalhe}` : ''}`)
    console.log(`  × ${nome}${detalhe ? ` — ${detalhe}` : ''}`)
  }
}

const importaTs = async (caminho) => await import(`../${caminho}?t=${Date.now()}`)

console.log('=== P2-S03-T03 — adaptador e webhook da Z-API (matriz) ===')

// ---------- 1. arquivos existem ----------
console.log('\n[1] Artefatos presentes')
for (const f of [ARQUIVO_ZAPI, ARQUIVO_WEBHOOK, ARQUIVO_SEND, ARQUIVO_TEST, ARQUIVO_PROC]) {
  check(`existe ${f}`, existsSync(f))
}

// ---------- 2. módulo zapi.ts ----------
console.log('\n[2] Módulo _shared/providers/zapi.ts')
const zapi = await importaTs(ARQUIVO_ZAPI)

const conta = { id: 'ca-uuid-z1', organization_id: 'org-1', clinic_id: 'cli-1', external_account_id: 'INST-123' }
const agoraMs = Date.now()
const velhoMs = agoraMs - 25 * 60 * 60 * 1000 // 25h atrás

// 2.1 E.164
check('E.164: 5581999990001 → +5581999990001', zapi.paraE164Zapi('5581999990001') === '+5581999990001')
check('E.164: com @c.us → limpo', zapi.paraE164Zapi('5581999990001@c.us') === '+5581999990001')
check('E.164: inválido → null', zapi.paraE164Zapi('123') === null)
check('E.164: vazio → null', zapi.paraE164Zapi('') === null)

// 2.2 momment → ISO
const isoAgora = zapi.isoDeMomment(agoraMs)
check('momment ms → ISO válido', typeof isoAgora === 'string' && isoAgora.endsWith('Z'))
check('momment em segundos → convertido', zapi.isoDeMomment(Math.floor(agoraMs / 1000)) !== null)
check('momment ausente → null', zapi.isoDeMomment(undefined) === null)

// 2.3 status Z-API → interno
check('SENT → sent', zapi.statusZapiParaInterno('SENT') === 'sent')
check('RECEIVED → delivered', zapi.statusZapiParaInterno('RECEIVED') === 'delivered')
check('READ → read', zapi.statusZapiParaInterno('READ') === 'read')
check('PLAYED → read', zapi.statusZapiParaInterno('PLAYED') === 'read')
check('status desconhecido → null', zapi.statusZapiParaInterno('XPTO') === null)

// 2.4 ReceivedCallback — mensagem recebida (fromMe=false, isGroup=false)
const corpoRecebida = {
  type: 'ReceivedCallback',
  instanceId: 'INST-123',
  messageId: 'false-messageid-1',
  phone: '5581999990002',
  momment: agoraMs,
  senderName: 'Maria da Silva',
  fromMe: false,
  isGroup: false,
  text: { message: 'Olá, quero agendar' },
}
const itRecebida = zapi.mapearCorpoZapi(corpoRecebida, conta)[0]
check('recebida: kind=message', itRecebida.kind === 'message')
check('recebida: external_event_id=messageId', itRecebida.external_event_id === 'false-messageid-1')
check('recebida: E.164 do remetente', itRecebida.from_phone_e164 === '+5581999990002')
check('recebida: nome do contato', itRecebida.contact_name === 'Maria da Silva')
check('recebida: texto mapeado', itRecebida.text_body === 'Olá, quero agendar')
check('recebida: não stale (agora)', itRecebida.stale === false)
check('recebida: suportada', itRecebida.unsupported === false)
check('recebida: provider_message_id', itRecebida.provider_message_id === 'false-messageid-1')

// 2.5 ReceivedCallback fromMe=true — enviada pelo aparelho
const corpoFromMe = { ...corpoRecebida, messageId: 'me-messageid-2', fromMe: true, text: { message: 'Resposta do celular' } }
const itFromMe = zapi.mapearCorpoZapi(corpoFromMe, conta)[0]
check('fromMe: kind=message (sender_type device é decisão do chamador)', itFromMe.kind === 'message')
check('fromMe: external_event_id próprio', itFromMe.external_event_id === 'me-messageid-2')
check('fromMe: suportada', itFromMe.unsupported === false)

// 2.6 grupo/newsletter → ignored
const corpoGrupo = { ...corpoRecebida, messageId: 'grp-1', isGroup: true, text: { message: 'msg de grupo' } }
check('grupo: unsupported (ignored)', zapi.mapearCorpoZapi(corpoGrupo, conta)[0].unsupported === true)
const corpoNews = { ...corpoRecebida, messageId: 'news-1', isNewsletter: true, text: { message: 'boletim' } }
check('newsletter: unsupported (ignored)', zapi.mapearCorpoZapi(corpoNews, conta)[0].unsupported === true)

// 2.7 mídia
const corpoImagem = { ...corpoRecebida, messageId: 'img-1', text: undefined, image: { id: 'media-abc' } }
const itImagem = zapi.mapearCorpoZapi(corpoImagem, conta)[0]
check('mídia: message_type=image', itImagem.message_type === 'image')
check('mídia: media_id capturado', itImagem.media_id === 'media-abc')
check('mídia: sem texto', itImagem.text_body === null)

// 2.8 MessageStatusCallback
const corpoStatus = {
  type: 'MessageStatusCallback',
  instanceId: 'INST-123',
  ids: ['msg-abc-1', 'msg-abc-2'],
  status: 'RECEIVED',
  momment: agoraMs,
}
const itStatus = zapi.mapearCorpoZapi(corpoStatus, conta)[0]
check('status: kind=status', itStatus.kind === 'status')
check('status: external_event_id=ids[0]:status', itStatus.external_event_id === 'msg-abc-1:status')
check('status: RECEIVED → delivered', itStatus.status === 'delivered')
check('status: provider_message_id=ids[0]', itStatus.provider_message_id === 'msg-abc-1')
const corpoStatusRead = { ...corpoStatus, status: 'READ' }
check('status: READ → read', zapi.mapearCorpoZapi(corpoStatusRead, conta)[0].status === 'read')

// 2.9 DisconnectedCallback → desconectar (RN-07)
const corpoDesc = { type: 'DisconnectedCallback', instanceId: 'INST-123', momment: agoraMs, connected: false }
const itDesc = zapi.mapearCorpoZapi(corpoDesc, conta)[0]
check('desconexão: kind=connection', itDesc.kind === 'connection')
check('desconexão: external_event_id=instanceId:momment', itDesc.external_event_id === `INST-123:${agoraMs}`)
check('desconexão: flag desconectar=true', itDesc.desconectar === true)
check('desconexão: não reativa', itDesc.reconectar === false)

// 2.10 ConnectedCallback — NUNCA reativa automaticamente
const corpoConn = { type: 'ConnectedCallback', instanceId: 'INST-123', momment: agoraMs, connected: true }
const itConn = zapi.mapearCorpoZapi(corpoConn, conta)[0]
check('reconexão: kind=connection', itConn.kind === 'connection')
check('reconexão: desconectar=false', itConn.desconectar === false)
check('reconexão: reconectar=false (só admin reativa)', itConn.reconectar === false)

// 2.11 stale >24h
const corpoVelha = { ...corpoRecebida, messageId: 'old-1', momment: velhoMs }
check('mensagem 25h → stale', zapi.mapearCorpoZapi(corpoVelha, conta)[0].stale === true)

// 2.12 tipo desconhecido
const corpoXpto = { type: 'XptoCallback', instanceId: 'INST-123', momment: agoraMs }
check('tipo desconhecido: unsupported', zapi.mapearCorpoZapi(corpoXpto, conta)[0].unsupported === true)

// 2.13 conta null (não mapeado)
const itSemConta = zapi.mapearCorpoZapi(corpoRecebida, null)[0]
check('sem conta: channel_account_id null', itSemConta.channel_account_id === null)

// 2.14 segredo em tempo constante
check('segredo válido aceito', zapi.segredoValido('SEGREDO-32-BYTES-XXXXXX', 'SEGREDO-32-BYTES-XXXXXX'))
check('segredo errado recusado', !zapi.segredoValido('SEGREDO-32-BYTES-XXXXXX', 'OUTRO-32-BYTES-XXXXXXX'))
check('segredo ausente recusado', !zapi.segredoValido('SEGREDO-32-BYTES-XXXXXX', null))
check('segredo tamanho diferente recusado', !zapi.segredoValido('SEGREDO-32-BYTES-XXXXXX', 'CURTO'))

// 2.15 envio com fetch stub (send-text)
let capturada = null
const fetchOriginal = globalThis.fetch
globalThis.fetch = async (url, init) => {
  capturada = { url: String(url), init }
  const corpo = JSON.parse(init?.body ?? '{}')
  if (corpo.message === 'CENARIO:ok') {
    return new Response(JSON.stringify({ messageId: 'zapi-msg-1', zaapId: 'zaap-9' }), { status: 200 })
  }
  if (corpo.message === 'CENARIO:erro') {
    return new Response(JSON.stringify({ error: 'INSTANCE_NOT_FOUND' }), { status: 404 })
  }
  return new Response('{}', { status: 200 })
}
const rOk = await zapi.enviarZapi('INST-123', 'TOKEN-INST', 'CLIENT-TOK', '+5581999990002', 'CENARIO:ok', 'corr-1')
check('envio ok: provider_message_id=messageId', rOk.ok === true && rOk.provider_message_id === 'zapi-msg-1')
check('envio ok: URL no formato /instances/<id>/token/<token>/send-text', capturada.url.includes('/instances/INST-123/token/TOKEN-INST/send-text'))
check('envio ok: Client-Token no header', capturada.init.headers['Client-Token'] === 'CLIENT-TOK')
const corpoEnviado = JSON.parse(capturada.init.body)
check('envio ok: phone sem +', corpoEnviado.phone === '5581999990002')
check('envio ok: message correto', corpoEnviado.message === 'CENARIO:ok')
const rErro = await zapi.enviarZapi('INST-123', 'TOKEN-INST', 'CLIENT-TOK', '+5581999990002', 'CENARIO:erro', 'corr-2')
check('envio erro: ok=false', rErro.ok === false)
check('envio erro: error_code sanitizado (sem corpo)', rErro.error_code === 'INSTANCE_NOT_FOUND' || rErro.error_code === 'http_404')
check('envio erro: sem provider_message_id', rErro.provider_message_id === null)
const rSemCred = await zapi.enviarZapi('', '', '', '+5581999990002', 'x', 'corr-3')
check('envio sem credenciais: credencial_ausente', rSemCred.error_code === 'credencial_ausente')
globalThis.fetch = fetchOriginal

// 2.16 sanitização — token/URL nunca em código de erro ou mensagem
check('erro não contém token da instância', !JSON.stringify(rErro).includes('TOKEN-INST'))
check('erro não contém Client-Token', !JSON.stringify(rErro).includes('CLIENT-TOK'))

// ---------- 3. webhook-whatsapp-zapi ----------
console.log('\n[3] Edge Function webhook-whatsapp-zapi')
const fonteWebhook = readFileSync(ARQUIVO_WEBHOOK, 'utf8')
check('valida ca + k do caminho', fonteWebhook.includes("searchParams.get('ca')") && fonteWebhook.includes("searchParams.get('k')"))
check('compara segredo em tempo constante (segredoValido)', fonteWebhook.includes('segredoValido'))
check('lê segredo via _edge_read_secret (vault não exposto na API)', fonteWebhook.includes('_edge_read_secret'))
check('recusa segredo errado → 401', fonteWebhook.includes("'segredo_invalido'"))
check('valida instanceId contra external_account_id', fonteWebhook.includes('external_account_id'))
check('instanceId trocado → recibo rejeitado', fonteWebhook.includes("'instance_invalido'"))
check('limite 120/min → 429 rejected_rate', fonteWebhook.includes('rejected_rate') && fonteWebhook.includes('120'))
check('idempotência por (provider, external_event_id)', fonteWebhook.includes("eq('external_event_id'"))
check('desconexão muda conta para disconnected', fonteWebhook.includes("'disconnected'"))
check('ConnectedCallback NÃO reativa automaticamente', !fonteWebhook.includes("status: 'active'"))
check('mensagem recebida → fila inbound_events', fonteWebhook.includes("'inbound_events'"))
check('situação → provider_message_status', fonteWebhook.includes('provider_message_status'))
check('stale → rejected_stale', fonteWebhook.includes('rejected_stale'))
check('grupo → ignored', fonteWebhook.includes("'ignored'"))
check('responde 200 com resumo (aceitos/duplicados/rejeitados)', fonteWebhook.includes('aceitos'))
check('não loga corpo bruto', !fonteWebhook.includes('console.log(corpoBruto'))
check('não loga token', !fonteWebhook.includes('console.log') || !fonteWebhook.includes('console.log(token'))

// ---------- 4. send-whatsapp-message (branch Z-API) ----------
console.log('\n[4] Consumidor de saída com branch Z-API')
const fonteSend = readFileSync(ARQUIVO_SEND, 'utf8')
check('importa enviarZapi', fonteSend.includes('enviarZapi'))
check('escolhe adaptador pelo provider da conta', fonteSend.includes("conta.provider === 'z_api'"))
check('lê Client-Token da segunda conexão (:client_token)', fonteSend.includes(':client_token'))
check('lê segredos via _edge_read_secret', fonteSend.includes('_edge_read_secret'))
check('provider_message_status usa provider da conta', fonteSend.includes('provider: conta.provider'))
check('mantém retry 5/30min → dead_letter', fonteSend.includes('MAX_TENTATIVAS') && fonteSend.includes('dead_letters'))

// ---------- 5. admin-test-channel (rede real) ----------
console.log('\n[5] Edge admin-test-channel (teste de rede real)')
const fonteTest = readFileSync(ARQUIVO_TEST, 'utf8')
check('existe Edge admin-test-channel', fonteTest.length > 1000)
check('Z-API: GET /instances/<id>/token/<token>/status', fonteTest.includes('/status'))
check('Z-API: Client-Token no header', fonteTest.includes("'Client-Token'"))
check('Meta: GET graph.facebook.com/<id>', fonteTest.includes('graph.facebook.com'))
check('devolve diagnóstico sanitizado (sem URL completa)', !fonteTest.includes('url: ') || fonteTest.includes('sanitiz'))
check('exige JWT de usuário', fonteTest.includes('auth.getUser'))
check('atualiza last_status_at/last_error_code', fonteTest.includes('last_status_at'))

// ---------- 6. process-inbound-event (provider do envelope) ----------
console.log('\n[6] Consumidor de entrada com provider do envelope')
const fonteProc = readFileSync(ARQUIVO_PROC, 'utf8')
check('usa provider do envelope (não fixo meta_cloud)', fonteProc.includes('msg.provider'))

// ---------- resultado ----------
console.log(`\n=== RESULTADO: ${passou} ✓ / ${falhou} × ===`)
if (falhas.length) {
  console.log('\nFalhas:')
  for (const f of falhas) console.log(`  - ${f}`)
  process.exit(1)
}
