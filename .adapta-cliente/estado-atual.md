# Estado atual — Adapta Cliente

- task_id: P1-S02-T02
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P1-S02-auth-rls.md
- etapa: implementada (aguarda teste humano)
- autorizacao_implementacao: confirmada — 2026-10-03 13:59, "implementar a proxima task" (Felipe, owner)
- teste_humano: pendente — harness artifacts/teste-rls-ps.html (login como Usuário Teste RLS → deve ver somente PSC; login como owner → deve ver PSC/PSR/PSO; anon → 0 clínicas)
- verificacao_automatica: passou — runner PGlite scripts/test_t02_rls.js 37/37; provas ao vivo no Supabase real (anon 0 via API; B via SET ROLE vê somente PSC e 2 memberships; owner vê PSC/PSR/PSO); migrations `p1_s02_t02_rls_policies` + `p1_s02_t02b_clinic_scope_tighten` aplicadas
- ultima_acao: 23 policies RLS aplicadas nas 10 tabelas; correção legada de profiles; usuário sintético B (teste.rls@ps-teste.local, sales na Caruaru) criado via RPC; membership owner do Felipe na PS Olinda; harness de teste criado; handoff sincronizado
- proxima_acao: aprovação do teste humano conclui a task; depois P1-S02-T03 (matriz por role/revogação)
- atualizado_em: 2026-10-03T17:20:00-03:00
