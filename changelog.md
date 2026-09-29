# Changelog do pacote do cliente

- 2026-09-29: fase 1 organizada em cinco SPECs e 15 tasks.
- 2026-09-29: pacote ampliado com o escopo definitivo completo, decisões/aprovações, visão, constituição, arquitetura do console, processo observado/alvo e registro do kick-off.

- 2026-09-29: corrigida a SPEC de schema da fase 1; tasks T01/T02 agora nomeiam conjuntos exatos de quatro e seis tabelas, com critérios correspondentes.

- 2026-09-29: critérios P1-S01 agora usam os IDs CA-P1-S01-01/02/03 em SPEC, tasks e Jornada.

- 2026-09-29: detalhados os campos exatos das seis tabelas T02 e alinhados os responsáveis técnicos da SPEC e das tasks.

- 2026-09-29: dúvida registrada durante a revisão de P1-S01-T01 foi resolvida: T01 cobre organizations, clinics, profiles e memberships; T02 cobre clinic_settings, teams, team_members, contacts, contact_identities e integration_connections; T03 prova o conjunto integrado.

- 2026-09-29: SPEC P1-S01 alinhada ao baseline observado do Supabase `psestetica`: `profiles` existente é preservada e compatibilizada aditivamente; `noop_check_only` permanece intacta; guard de destino exclui o app Skip como alvo de migrations.
- 2026-09-29: T01/T03, tasks, Jornada e rastreabilidade agora cobrem instalação limpa, upgrade do baseline existente, preservação de IDs/linhas e validação de alvo.
- 2026-09-29: implementada P1-S01-T01 no Supabase `psestetica` pela migration `20260929145212_p1_s01_t01_tenancy_core`; criou `organizations`, `clinics`, `memberships` e alinhou `profiles.status` aditivamente. Testes PGlite de instalação limpa, upgrade, FKs, rejeição cross-tenant e replay passaram; baseline da linha/OID/fingerprint e policies de `profiles` preservados, `noop_check_only` mantida.
- 2026-09-29 · Felipe F3 Energy Drink · Task P1-S01-T01 concluída: quatro contratos T01 presentes; profiles e histórico preservados, testes automáticos aprovados e confirmação humana “Teste OK — confirmei as quatro tabelas e profiles”. Evidência: relatório P1-S01-T01 e migration `20260929145212_p1_s01_t01_tenancy_core`.
- 2026-09-29: DÚVIDA — P1-S01-T02 bloqueada antes da implementação. A SPEC enumera campos/FKs, mas não define claramente as chaves primárias e a unicidade de `clinic_settings`, `team_members` e `contact_identities`; a própria SPEC proíbe inventar unicidade de negócio. Consultora deve registrar a decisão aprovada para cada contrato antes da migration. Nenhuma tabela/dado foi alterado nesta análise.
