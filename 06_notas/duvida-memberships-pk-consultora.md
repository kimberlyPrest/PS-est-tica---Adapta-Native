# DÚVIDA para a consultora — PK de `memberships` (bloqueia P1-S01-T04)

- Data: 2026-10-02 · Originada na task: P1-S01-T02 (concluída) · Status: **aberta, aguardando decisão**

## O problema em linguagem simples

A SPEC atualizada (emenda de 2026-09-29) diz que a tabela `memberships` deveria ter uma chave composta pelos quatro campos que identificam um vínculo (usuário + organização + clínica + papel), **sem** uma coluna `id` própria.

Mas a migration da T01 — já aplicada no banco e aprovada em teste humano — criou `memberships` **com** `id` como chave primária.

Verificado no banco real (Supabase `psestetica`, 2026-10-02): `memberships_pkey = PRIMARY KEY (id)`.

## Impacto

- A T04 (constraints UNIQUE) precisa saber qual é a chave real de `memberships` antes de aplicar as regras de unicidade da SPEC.
- A T03 (prova integrada) valida a estrutura completa e também depende dessa definição.
- Não foi alterado nada em `memberships`: a T02 não tocou nessa tabela.

## Decisão necessária (uma das duas)

1. **Manter o banco como está** (`id` como PK): emendar a SPEC de volta, declarando que a unicidade de vínculo fica como constraint UNIQUE adicional em T04.
2. **Corrigir para PK composta**: criar migration corretiva que troca a PK de `memberships` — exige decisão sobre dados existentes e revisão da T01 concluída.

## Referências

- SPEC: seção "Chaves primárias e unicidade" (SPEC-P1-S01-schema-tenancy.md)
- Migration aplicada: `20260929145212_p1_s01_t01_tenancy_core`
- Verificação no banco: `pg_constraint` → `memberships_pkey = PRIMARY KEY (id)` (2026-10-02)
- Registro no changelog: 2026-10-02, entrada "DÚVIDA — divergência entre SPEC emendada e migration T01 aplicada"
