# Estado atual — Adapta Cliente

- task_id: P2-S04-T02/T03 (reteste pelo owner)
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S04-conversas-e-caixa-de-entrada.md
- etapa: aguardando_teste_humano
- teste_humano: pendente — T01 ACEITE CONFIRMADO; T02 (conversas + resposta pelo app) e T03 (selo + foto como anexo) aguardam reteste após fixes v0.0.28 (contexto) e v0.0.30 (render de anexos)
- verificacao_automatica: passou — bug do contexto corrigido e provado no preview; pipeline de imagem provado com webhook sintético (recibo accepted → conversa → mensagem image); anexos renderizados na tela Conversa com URL assinada + aviso de antivírus pendente; policy de leitura do bucket aplicada
- aprendizado: hook de contexto lido FORA do provider devolve sempre o default; mensagens fromMe não geram ReceivedCallback por padrão na Z-API (fix: update-notify-sent-by-me=true, aplicado 26/10)
- ultima_acao: v0.0.30 publicado; notify-sent-by-me ativado na Z-API; changelog sincronizado
- proxima_acao: reteste do owner (Ctrl+F5 no preview, PS Recife, foto de OUTRO celular) → demonstração recepção (fecha T04) → SPEC P2-S05
- atualizado_em: 2026-10-26T16:45:00-03:00
