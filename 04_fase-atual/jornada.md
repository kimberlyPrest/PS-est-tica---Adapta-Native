# Fase 1 — Jornada de execução

<!-- fase-format:2 -->

- [ ] Implementar migrations e constraints para organização/clínica/profile/membership. @técnico de implementação #projeto   <!-- id:c6462c17-68fa-486e-9449-f0c6d0c53a86 -->
      > P1-S01-T01 — Esquema multi-clínica e migrations; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S01-schema-tenancy.md.
- [ ] Adicionar tabelas mínimas de contato e conexão mais índices por tenant/clínica. @técnico de integração #projeto   <!-- id:0a0ce946-ba93-4215-8e3b-646acfc81ca4 -->
      > P1-S01-T02 — Esquema multi-clínica e migrations; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S01-schema-tenancy.md.
- [ ] Validar instalação limpa, upgrade, integridade referencial e criação de terceira clínica. @QA + dono operacional #projeto   <!-- id:79cd2f26-0dd8-4153-ac27-315d7fb431b8 -->
      > P1-S01-T03 — Esquema multi-clínica e migrations; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S01-schema-tenancy.md.
- [ ] Configurar Auth e fluxo de convite/login conforme decisão aprovada. @técnico de implementação #projeto   <!-- id:1ed9efff-4f17-4832-8ab7-587350d26dc4 -->
      > P1-S02-T01 — Autenticação, papéis e isolamento RLS; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S02-auth-rls.md.
- [ ] Aplicar políticas RLS por organização/clínica às tabelas expostas e revisar views. @técnico de integração #projeto   <!-- id:be2db61a-75fd-4d19-8860-742328552273 -->
      > P1-S02-T02 — Autenticação, papéis e isolamento RLS; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S02-auth-rls.md.
- [ ] Executar matriz positiva/negativa por role, membership e revogação. @QA + dono operacional #projeto   <!-- id:91b41424-1ff0-45da-afe7-49bfc5cd929e -->
      > P1-S02-T03 — Autenticação, papéis e isolamento RLS; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S02-auth-rls.md.
- [ ] Construir telas responsivas de clínicas, usuários, memberships e equipes. @técnico de implementação #projeto   <!-- id:8a55c963-689a-4039-a14b-17e20550c336 -->
      > P1-S03-T01 — Console inicial de organizações, clínicas e usuários; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S03-admin-organizacao.md.
- [ ] Validar campos, herança, estados de convite e restrições de role no servidor. @técnico de integração #projeto   <!-- id:93fcfd1e-e339-4b73-a865-4102c86ae5cb -->
      > P1-S03-T02 — Console inicial de organizações, clínicas e usuários; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S03-admin-organizacao.md.
- [ ] Demonstrar cadastro da terceira clínica e auditoria das mudanças. @QA + dono operacional #projeto   <!-- id:f6b91d1b-241e-4ad5-874d-5116c2729e99 -->
      > P1-S03-T03 — Console inicial de organizações, clínicas e usuários; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S03-admin-organizacao.md.
- [ ] Implementar gravação server-side do segredo e referência opaca. @técnico de implementação #projeto   <!-- id:20b98595-d7d2-427f-b5e7-ccf5425f573f -->
      > P1-S04-T01 — Conexões, secrets e configuração versionada; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S04-admin-secrets-config.md.
- [ ] Implementar formulário de conexão, teste sanitizado, versionamento e audit log. @técnico de integração #projeto   <!-- id:d58ea138-77d6-42f3-bb0e-0ba7d3b364e7 -->
      > P1-S04-T02 — Conexões, secrets e configuração versionada; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S04-admin-secrets-config.md.
- [ ] Provar não exposição de segredo, falhas 401/429/timeout e rollback. @QA + dono operacional #projeto   <!-- id:fa982ec4-a334-4f3c-97e4-b448454035e8 -->
      > P1-S04-T03 — Conexões, secrets e configuração versionada; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S04-admin-secrets-config.md.
- [ ] Implementar cliente server-side HTTP com timeout, rate limiter e telemetria sanitizada. @técnico de implementação #projeto   <!-- id:d2e5782f-d3b8-47c4-9a1a-6c176267d2a2 -->
      > P1-S05-T01 — Cliente Clínica Experts e busca/identificação de paciente; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S05-clinica-experts-paciente.md.
- [ ] Implementar busca, normalização, deduplicação, vínculo humano e cache mínimo com TTL. @técnico de integração #projeto   <!-- id:05ad45fc-38de-4c25-82bd-2f0dee87e20e -->
      > P1-S05-T02 — Cliente Clínica Experts e busca/identificação de paciente; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S05-clinica-experts-paciente.md.
- [ ] Construir fluxo de busca demonstrável e executar matriz zero/um/múltiplos/falhas. @QA + dono operacional #projeto   <!-- id:9fdfdb76-c787-4474-9509-661b4336489b -->
      > P1-S05-T03 — Cliente Clínica Experts e busca/identificação de paciente; SPEC: 01.Fase_1/01-SPECs/SPEC-P1-S05-clinica-experts-paciente.md.
