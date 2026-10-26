# Changelog

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
