# AP-2026-10-02-1125 — Divergência SPEC vs migration aplicada

- Status: candidato
- Escopo: projeto do cliente
- Task/SPEC: P1-S01-T02 / SPEC-P1-S01-schema-tenancy.md
- Sinal: ao concluir T02, a checagem de regressão no banco real revelou que a SPEC emendada (2026-09-29) exige PK composta `(user_id, organization_id, clinic_id, role)` em `memberships`, mas a migration T01 já aplicada e aprovada criou `PRIMARY KEY (id)`. A SPEC pós-emenda diverge do estado físico aprovado.
- Evidência: consulta `pg_constraint` no Supabase `psestetica` (2026-10-02): `memberships_pkey = PRIMARY KEY (id)`; SPEC seção "Chaves primárias e unicidade"; changelog 2026-10-02 (DÚVIDA registrada).
- Regra reutilizável: antes de implementar uma task que depende de contratos de tasks anteriores, verificar a estrutura real do banco (`pg_constraint`, catálogo) e não apenas o texto da SPEC — emendas documentais podem divergir do estado físico já aprovado; divergência vira DÚVIDA para a consultora, nunca correção silenciosa.
- Quando aplicar: tasks de schema/DB que assumem contratos de tasks concluídas (ex.: T04 e T03 de P1-S01 dependem de T01/T02).
- Quando não aplicar: tasks puramente documentais ou sem dependência de estado físico anterior.
- Confiança: alta — divergência observada diretamente no banco e no texto da SPEC.
- Privacidade: sem segredo, dado pessoal ou conteúdo bruto.
