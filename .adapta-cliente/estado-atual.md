# Estado atual — Adapta Cliente

- task_id: P2-S04-T02 (reteste pelo owner)
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S04-conversas-e-caixa-de-entrada.md
- etapa: aguardando_teste_humano
- teste_humano: pendente — Felipe recarrega o preview (Ctrl+F5) e confere as conversas na PS Recife + resposta pelo app (T02) + selo/imagem (T03); T01 ACEITE CONFIRMADO
- verificacao_automatica: passou — bug do contexto corrigido (v0.0.28) e provado no preview; banco com 16 conversas/114 mensagens; saída provada (Z-API sent)
- aprendizado: hook de contexto lido FORA do provider devolve sempre o default — extrair o conteúdo para componente filho do provider
- ultima_acao: fix v0.0.28 publicado no preview; handoff sincronizado
- proxima_acao: aceite T02/T03 do owner → demonstração recepção (fecha T04) → SPEC P2-S05
- atualizado_em: 2026-10-26T16:05:00-03:00
