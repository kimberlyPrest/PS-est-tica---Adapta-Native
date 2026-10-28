# Estado atual — Adapta Cliente

- task_id: P2-S03-T04 (liberada, aguardando instância Z-API de teste)
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S03-numeros-whatsapp-meta-zapi.md
- etapa: aguardando_pre_requisito_do_dono
- decisao_do_owner: **CAMINHO A** — criar instância Z-API nova com número DIFERENTE, em outra clínica (decidido em 28/10 00:30). Objetivo: cumprir a SPEC literal (dois provedores, dois números, duas clínicas).
- autorizacao_implementacao: confirmada — o owner autorizou a T04 pelo caminho A
- tarefa_anterior: P2-S03-T02 CONCLUÍDA em 28/10 (aceite humano; canal Meta provado ponta a ponta)
- pre_requisito_do_dono: criar a instância na Z-API (painel app.z-api.io) com um número que NÃO seja o +55 81 98234-9927 (que agora pertence ao Cloud API da Meta) e informar Instance ID + Token + Client-Token
- verificacao_automatica: pendente (depende da instância)
- ultima_acao: decisão do caminho A registrada; handoff sincronizado
- proxima_acao: com a instância nova em mãos, cadastrar o canal pela tela /admin/canais na clínica escolhida, configurar webhooks da Z-API e rodar a matriz T04 (dois provedores + 5 tentativas/dead letter + desconexão real)
- atualizado_em: 2026-10-28T00:35:00-03:00
