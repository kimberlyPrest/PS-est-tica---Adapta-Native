# Estado atual — Adapta Cliente

- task_id: P2-S03-T02 (concluída) — próxima liberável: P2-S03-T04
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S03-numeros-whatsapp-meta-zapi.md
- etapa: concluida
- autorizacao_implementacao: confirmada pelo owner em 27/10 22:37 ("corrigir primeiro")
- teste_humano: APROVADO em 28/10 — owner enviou "Teste novo" do celular (chegou no CRM com contato, conversa, mensagem e ticket) e confirmou o recebimento da resposta enviada pelo CRM
- verificacao_automatica: passou — runners `scripts/test_p2_s03_t02.mjs` 48/48 e `scripts/test_p2_s03_t03.mjs` 94/94; matriz de contrato revalidada no banco real (CA-02 idempotência aceitos:1/duplicados:1; CA-03 assinatura inválida 401 rejected_signature; CA-04 não mapeado rejected_unmapped sem conversa; CA-08 stale rejected_stale)
- prova_real: pipeline ponta a ponta — Meta → webhook (HMAC válido) → fila inbound_events → consumidor → contato/conversa/mensagem/ticket → RPC send_human_message → outbound_requests `sent` → provider_message_status `sent` → `delivered`
- bug_corrigido: webhook Meta v4 (commit `5c517cc`) gravava recibo SEM `payload_ref`, e o consumidor lê o payload só por esse campo — toda mensagem era descartada em silêncio com recibo `accepted`
- canais: Meta Cloud API `active` (número real +55 81 98234-9927, webhook registrado por API no app 1063262590063176 e inscrito no WABA 1068799338488708); Z-API `disabled` (trial vencido, responde 400 "subscribe again")
- ultima_acao: handoff sincronizado (fase.md 28.577 bytes, STATUS 25/28, changelog, este arquivo)
- proxima_acao: DECISÃO DO OWNER sobre a P2-S03-T04 — renovar/criar instância Z-API de teste para a matriz dos dois provedores, ou aceitar desvio documentado (matriz Z-API por provedor simulado + desconexão provada no banco)
- atualizado_em: 2026-10-28T00:30:00-03:00
