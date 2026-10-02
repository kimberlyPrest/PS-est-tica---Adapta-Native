# Estado atual — Adapta Cliente

- task_id: P1-S01-T04
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P1-S01-schema-tenancy.md
- etapa: aguardando_teste_humano
- autorizacao_implementacao: confirmada — 2026-10-02 14:22, "sim" (Felipe, owner, em resposta ao plano de T04)
- teste_humano: pendente
- verificacao_automatica: passou — runner PGlite 29/29 (matriz completa: duplicatas rejeitadas, coexistências permitidas, replay idempotente); migration `p1_s01_t04_uniques` aplicada no Supabase `psestetica`; catálogo real: 4 constraints UNIQUE novas + 3 índices parciais; memberships sem UNIQUE (conforme SPEC); profiles preservada (1 linha)
- aprendizado: pendente
- ultima_acao: migration T04 aplicada e verificada no Supabase; SQL em artifacts/p1_s01_t04_uniques.sql, runner em scripts/test_t04.js
- proxima_acao: teste humano de Felipe; após aprovação, concluir T04; T03 segue aguardando decisão da consultora sobre PK de memberships
- atualizado_em: 2026-10-02T14:45:00-03:00
