# Estado atual — Adapta Cliente

- task_id: P1-S01-T01
- champion: Felipe F3 Energy Drink (solicitante; designação de champion não consta no handoff)
- spec: 04_fase-atual/01-SPECS/SPEC-P1-S01-schema-tenancy.md
- etapa: aguardando_teste_humano
- autorizacao_implementacao: confirmada em 2026-09-29T11:42-03:00 — “implemente a task 1”, após atualização do escopo das SPECs pela consultora
- teste_humano: pendente
- verificacao_automatica: passou — PGlite 0.5.8: instalação limpa, exatamente quatro tabelas T01, campos, relações/FKs, vínculo cross-tenant inválido negado, terceira clínica inserida, RLS habilitada; upgrade com profiles sintética: OID, linha, fingerprint dos campos legados e três policies preservados; status adicionado; replay idempotente. Supabase: migration 20260929145212 aplicada; catálogo confirma quatro tabelas, relações/FKs, RLS; profiles permaneceu com 1 linha, OID 17605 e fingerprint 839b2b4ae3efc272420327f74ca32aeb; histórico preserva create_profiles_and_seed e noop_check_only.
- aprendizado: pendente
- ultima_acao: aplicada migration P1-S01-T01 `20260929145212_p1_s01_tenancy_core` (nome registrado: `p1_s01_t01_tenancy_core`) no Supabase autorizado uhozizrpmmpemvegtqaq. SQL versionado em artifacts/20260929145212_p1_s01_t01_tenancy_core.sql, SHA-256 f074c1677ccc68b88b567013cffa795ebc9e115ad64788d9d1a47319eaaa19fd. Nenhum arquivo ou mudança de produto aplicado no projeto Skip #62134.
- proxima_acao: Felipe executar teste humano de login/profile compatível no app Preview e confirmar se funcionou; não iniciar T02 nem concluir T01 antes da confirmação
- atualizado_em: 2026-09-29T11:56:40-03:00
