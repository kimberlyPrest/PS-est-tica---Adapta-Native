# Fase 1 — Jornada de execução

<!-- fase-format:2 -->

- [x] Materializar organizations, clinics, profiles e memberships sem perder o baseline existente. @técnico de banco #projeto — concluída em 2026-09-29 <!-- id:86eb4738-bb19-4b90-9746-36f037eeb983 -->
      > P1-S01-T01 — CA-P1-S01-01: quatro contratos T01 presentes; instalação limpa e upgrade aprovados; profiles e histórico preservados. | migration 20260929145212; testes PGlite e validação humana registrados no changelog.
- [ ] Criar clinic_settings, teams, team_members, contacts, contact_identities e integration_connections com PKs, timestamps e escopo organization/clinic. @técnico de banco #projeto   <!-- id:2072d8ea-9798-423d-9b53-02d7ad1baf7a -->
      > P1-S01-T02 — CA-P1-S01-02: seis contratos e FKs presentes; connections usam `organization_id`, `clinic_id` opcional e `connection_key`; tabelas têm PK técnica `id` e timestamps comuns. | CA e cenário TDD correspondente na SPEC.
- [ ] Aplicar e validar as constraints UNIQUE adicionais da SPEC P1-S01. @técnico de banco + QA #projeto   <!-- id:bd34f885-f8b2-41e9-9a14-d7dc6143fdc2 -->
      > P1-S01-T04 — CA-P1-S01-04: duplicatas das chaves declaradas são rejeitadas e coexistências permitidas são aceitas. | Matriz sintética de unicidades na SPEC.
- [ ] Validar instalação limpa, upgrade e integridade relacional após T01, T02 e T04. @QA + técnico de banco #projeto   <!-- id:3d1eb137-481f-40fd-ba4f-5739d6b10739 -->
      > P1-S01-T03 — CA-P1-S01-03: instalação limpa e upgrade passam; `profiles` e histórico aplicado são preservados; terceira clínica é cadastrada sem nova migration. | CA e cenário TDD correspondente na SPEC.
- [ ] Configurar Auth e fluxo de convite/login conforme decisão aprovada. @técnico de implementação #projeto   <!-- id:ee1ff632-b444-42a9-bb01-a4e2337cab92 -->
      > P1-S02-T01 — Usuário sem sessão não lê dados operacionais. | CA e cenário TDD correspondente na SPEC.
- [ ] Aplicar políticas RLS por organização/clínica às tabelas expostas e revisar views. @técnico de integração #projeto   <!-- id:31435da1-a1b6-4f22-816c-8bac3569d62b -->
      > P1-S02-T02 — Membro da clínica A não lê nem altera clínica B via API direta. | CA e cenário TDD correspondente na SPEC.
- [ ] Executar matriz positiva/negativa por role, membership e revogação. @QA + dono operacional #projeto   <!-- id:94e9b0b0-2dc4-4315-9442-38d737ce41fa -->
      > P1-S02-T03 — Revogar membership invalida acesso futuro e mantém histórico/auditoria. | CA e cenário TDD correspondente na SPEC.
- [ ] Construir telas responsivas de clínicas, usuários, memberships e equipes. @técnico de implementação #projeto   <!-- id:a1038748-e36a-4178-9abe-ecccad2ecc7b -->
      > P1-S03-T01 — Owner cria/edita clínica e convida usuário com papel/clínicas delimitados. | CA e cenário TDD correspondente na SPEC.
- [ ] Validar campos, herança, estados de convite e restrições de role no servidor. @técnico de integração #projeto   <!-- id:ed0c201b-0540-495c-a9d4-1b0644af232a -->
      > P1-S03-T02 — Clinic_admin administra apenas a própria clínica. | CA e cenário TDD correspondente na SPEC.
- [ ] Demonstrar cadastro da terceira clínica e auditoria das mudanças. @QA + dono operacional #projeto   <!-- id:6cbad606-5a39-42a6-97c0-80aa99107bd0 -->
      > P1-S03-T03 — Configuração incompleta permanece em rascunho; nenhuma ação oferece SQL livre. | CA e cenário TDD correspondente na SPEC.
- [ ] Implementar gravação server-side do segredo e referência opaca. @técnico de implementação #projeto   <!-- id:12ff97c9-efcd-48f8-a8a1-eebc2e9b145f -->
      > P1-S04-T01 — Salvar segredo retorna somente estado/sufixo mascarado seguro; inspeção de rede não revela valor. | CA e cenário TDD correspondente na SPEC.
- [ ] Implementar formulário de conexão, teste sanitizado, versionamento e audit log. @técnico de integração #projeto   <!-- id:2cd2eba8-d205-42de-9d20-160cf75c0a73 -->
      > P1-S04-T02 — Teste retorna diagnóstico sanitizado e registra status/horário. | CA e cenário TDD correspondente na SPEC.
- [ ] Provar não exposição de segredo, falhas 401/429/timeout e rollback. @QA + dono operacional #projeto   <!-- id:88e308ae-fc63-465c-9fc5-92917913e837 -->
      > P1-S04-T03 — Rollback restaura configuração anterior sem apagar auditoria. | CA e cenário TDD correspondente na SPEC.
- [ ] Implementar cliente server-side HTTP com timeout, rate limiter e telemetria sanitizada. @técnico de implementação #projeto   <!-- id:2f4e0848-e94d-40f9-80d6-314d205b2364 -->
      > P1-S05-T01 — Busca zero/um/múltiplos produz estados definidos sem escolher múltiplos automaticamente. | CA e cenário TDD correspondente na SPEC.
- [ ] Implementar busca, normalização, deduplicação, vínculo humano e cache mínimo com TTL. @técnico de integração #projeto   <!-- id:c883b0e2-d40e-4992-a291-845a4256eaa2 -->
      > P1-S05-T02 — 401/422/429/timeout têm erro operacional sanitizado e correlação; falha não bloqueia conversa local. | CA e cenário TDD correspondente na SPEC.
- [ ] Construir fluxo de busca demonstrável e executar matriz zero/um/múltiplos/falhas. @QA + dono operacional #projeto   <!-- id:2e94d2a3-5242-4885-a050-2a4c606ff697 -->
      > P1-S05-T03 — Token nunca chega ao cliente; cache mínimo expira e pode ser invalidado. | CA e cenário TDD correspondente na SPEC.
