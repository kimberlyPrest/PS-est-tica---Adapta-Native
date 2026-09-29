# Índice de SPECs — Fase 1

Todas as SPECs estão liberadas para implementação. Dependências listadas abaixo são ordem técnica de entrega, sem aprovação pendente.

| ID | Capacidade | SPEC | Tasks | Dependência técnica |
|---|---|---|---|---|
| P1-S01 | Esquema multi-clínica e migrations | [SPEC-P1-S01-schema-tenancy.md](./SPEC-P1-S01-schema-tenancy.md) | P1-S01-T01, P1-S01-T02, P1-S01-T04, P1-S01-T03 | — |
| P1-S02 | Autenticação, papéis e isolamento RLS | [SPEC-P1-S02-auth-rls.md](./SPEC-P1-S02-auth-rls.md) | P1-S02-T01, P1-S02-T02, P1-S02-T03 | P1-S01 schema |
| P1-S03 | Console inicial de organizações, clínicas e usuários | [SPEC-P1-S03-admin-organizacao.md](./SPEC-P1-S03-admin-organizacao.md) | P1-S03-T01, P1-S03-T02, P1-S03-T03 | P1-S01 + P1-S02 |
| P1-S04 | Conexões, secrets e configuração versionada | [SPEC-P1-S04-admin-secrets-config.md](./SPEC-P1-S04-admin-secrets-config.md) | P1-S04-T01, P1-S04-T02, P1-S04-T03 | P1-S01 + P1-S02 |
| P1-S05 | Cliente Clínica Experts e busca/identificação de paciente | [SPEC-P1-S05-clinica-experts-paciente.md](./SPEC-P1-S05-clinica-experts-paciente.md) | P1-S05-T01, P1-S05-T02, P1-S05-T03 | P1-S01 + P1-S02 + P1-S04 |
