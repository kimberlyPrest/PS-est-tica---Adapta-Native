# Estado atual — Adapta Cliente

- task_id: P1-S02-T02
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P1-S02-auth-rls.md
- etapa: concluída (2026-10-06)
- autorizacao_implementacao: confirmada — 2026-10-03 13:59, "implementar a proxima task" (Felipe, owner)
- teste_humano: aprovado — 2026-10-06, "teste ok" (Felipe, owner), no harness artifacts/rls-final-v3-20261006.html (login como Usuário Teste RLS → viu somente PSC; login como owner → viu PSC/PSR/PSO; anon → 0 clínicas)
- verificacao_automatica: revalidada em 2026-10-06 com evidência fresca — RLS ativa nas 10 tabelas com 23 policies; 0 policies legadas (`authenticated_select_profiles` removida); 8 funções auxiliares SECURITY DEFINER ativas; anon lê 0 clínicas via API; B (só Caruaru) vê somente PSC; owner vê PSC/PSR/PSO; UPDATE de B em clínica alheia não altera dado (nomes das 3 clínicas intactos)
- ultima_acao: fechamento de P1-S02-T02 após aprovação do teste humano; quadro, STATUS, changelog e estado sincronizados
- proxima_acao: P1-S02-T03 (matriz por role/revogação), mediante pedido do champion
- atualizado_em: 2026-10-06T11:55:00-03:00
