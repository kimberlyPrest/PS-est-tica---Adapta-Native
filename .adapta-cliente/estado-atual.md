# Estado atual — Adapta Cliente

- task_id: P2-S04-T02/T03 (reteste pelo owner)
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S04-conversas-e-caixa-de-entrada.md
- etapa: aguardando_teste_humano
- teste_humano: pendente — T01 ACEITE CONFIRMADO; T02/T03 aguardam reteste após fixes v0.0.28 (contexto), v0.0.30 (render de anexos) e mídia Z-API imageUrl (webhook v5 + consumidor v10, foto da Milena recuperada e renderizada na tela)
- verificacao_automatica: passou — pipeline de imagem provado ponta a ponta com payload REAL da Z-API (imageUrl+caption): mensagem image + legenda + anexo no bucket + render na tela Conversa; fumaça v10 com _shared reais (selo novo_lead real)
- aprendizado: payload real do provedor capturado via probe de leitura do bucket antes de escrever o parser; fromMe não gera ReceivedCallback por padrão (fix: update-notify-sent-by-me=true)
- ultima_acao: webhook v5 + consumidor v10 publicados; foto da Milena recuperada e provada na tela; changelog consolidado
- proxima_acao: reteste do owner (Ctrl+F5, PS Recife, foto de outro celular) → demonstração recepção (fecha T04) → SPEC P2-S05
- atualizado_em: 2026-10-26T17:25:00-03:00
