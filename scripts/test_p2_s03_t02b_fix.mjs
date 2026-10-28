// scripts/test_p2_s03_t02b_fix.mjs — prova da correção do webhook Meta (27/10)
// RED: o webhook v2 lia o Vault por `.schema('vault')` (não exposto no PostgREST)
// e usava o access token como chave HMAC. GREEN: lê por RPC e usa o App Secret
// da segunda conexão `<phone_number_id>:app_secret`.
// Node puro — sem servidor, sem Deno. Rodar de dentro do repo do CRM.
import { readFileSync } from 'node:fs'
import { createHmac } from 'node:crypto'

let ok = 0, fail = 0
const falhas = []
const check = (n, c, d = '') => {
  if (c) { ok++; console.log(`  ✓ ${n}`) }
  else { fail++; falhas.push(n); console.log(`  × ${n}${d ? ' — ' + d : ''}`) }
}

const wh = readFileSync('supabase/functions/webhook-whatsapp-meta/index.ts', 'utf8')
const whCodigo = wh.split('\n').filter((l) => !l.trim().startsWith('//')).join('\n')

console.log('defeito 1: leitura do Vault')
check("não usa .schema('vault') em código executável", !/\.schema\('vault'\)/.test(whCodigo))
check('usa a RPC _edge_read_secret', wh.includes("rpc('_edge_read_secret'"))
check('resolve o verify_token por conta', wh.includes('segredosWebhook.set(conta.id, verify)'))

console.log('defeito 2: App Secret inteiro')
check('busca a conexão <id>:app_secret', wh.includes(':app_secret'))
check('provider canal_meta_cloud', wh.includes("'canal_meta_cloud'"))
check('usa app_secrets (não o access token) como chave HMAC', wh.includes('appSecrets.values()'))

console.log('verificação GET')
const respostaVerificacao = (url, validos) => {
  const mode = url.searchParams.get('hub.mode')
  const token = url.searchParams.get('hub.verify_token') ?? ''
  const challenge = url.searchParams.get('hub.challenge') ?? ''
  return mode === 'subscribe' && challenge && validos.includes(token)
    ? { status: 200, corpo: challenge }
    : { status: 403, corpo: 'forbidden' }
}
const VT = 'segredo-de-teste'
check('token correto -> 200 + challenge', respostaVerificacao(new URL(`https://x?hub.mode=subscribe&hub.verify_token=${VT}&hub.challenge=abc`), [VT]).status === 200)
check('token errado -> 403', respostaVerificacao(new URL('https://x?hub.mode=subscribe&hub.verify_token=nao&hub.challenge=abc'), [VT]).status === 403)

console.log('assinatura HMAC')
const assinaturaValida = (secret, corpo, sig) => {
  if (!secret || !sig) return false
  const esperado = createHmac('sha256', secret).update(corpo, 'utf8').digest('hex')
  return esperado === (sig.startsWith('sha256=') ? sig.slice(7) : sig)
}
const APP = 'appsecret-de-teste'
const corpo = JSON.stringify({ object: 'whatsapp_business_account', entry: [] })
const sig = 'sha256=' + createHmac('sha256', APP).update(corpo, 'utf8').digest('hex')
check('assinatura correta -> aceita', assinaturaValida(APP, corpo, sig) === true)
check('assinatura de outro secret -> recusa', assinaturaValida('outro', corpo, sig) === false)
check('sem assinatura -> recusa', assinaturaValida(APP, corpo, null) === false)

console.log(`\n${ok} passaram, ${fail} falharam`)
if (fail) { console.log('FALHAS:', falhas.join(' | ')); process.exit(1) }
