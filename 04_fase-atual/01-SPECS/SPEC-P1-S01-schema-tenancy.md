# P1-S01 — Esquema multi-clínica e migrations

**Fase:** 1
**Status:** liberada para implementação
**Dono:** owner e técnico de banco
**Origem no escopo:** seções 6.1, 7.1–7.3 e 18/Fase 1
**Degrau da solução:** construção mínima sobre Supabase/Postgres; somente as tabelas-base abaixo, sem implementar políticas RLS nem telas administrativas.

## Contexto e decisões fechadas

- **Estado atual:** tabelas descritas no escopo; migrations deste incremento ainda não demonstradas.
- **Estado desejado:** criar schema versionado para tenant, acesso inicial, configuração de clínica, equipes, contatos e metadados de conexão.
- **Decisões:** UUID e timestamps padrão; organização contém clínicas; memberships ligam usuário, organização, clínica e papel; migrations versionadas; segredos não são gravados no banco operacional.
- **Aprovação:** decisões humanas confirmadas e registradas em `03-Projeto/decisoes-do-projeto.md`.

## Resultado observável

Uma migration instala os dez objetos de tabela enumerados abaixo com relações válidas, pode ser aplicada em banco vazio e atualizada a partir da versão anterior, e permite criar uma terceira clínica por dados sem alterar código/schema.

## Escopo e limites

- **Inclui:** migrations, tabelas, chaves estrangeiras, constraints referencial/tenant necessárias às relações declaradas, índices de busca e rollback compatível.
- **Não inclui:** policies RLS (P1-S02), telas/configuração (P1-S03/P1-S04), vínculo/cache de paciente de Clínica Experts (P1-S05), dados reais, nem segredo de integração.
- **Atores:** técnico de banco e owner para revisão; migrations executadas pelo pipeline autorizado.
- **Superfície:** Supabase Postgres/migrations versionadas. Não executar SQL manual em produção.
- **Rollback:** migration reversível quando compatível com dados; se downgrade puder perder dados, usar migration corretiva aditiva e preservar histórico.

## Contrato exato de tabelas por task

| Task | Tabelas cobertas | Campos/contrato da seção 7 |
|---|---|---|
| P1-S01-T01 | `organizations`, `clinics`, `profiles`, `memberships` — exatamente estas quatro tabelas | `organizations`: `id`, `name`, `status`, `timezone`; `clinics`: `id`, `organization_id`, `name`, `code`, `timezone`, `status`; `profiles`: `id=auth.users.id`, `name`, `status`; `memberships`: `user_id`, `organization_id`, `clinic_id`, `role`, `active`. |
| P1-S01-T02 | `clinic_settings`, `teams`, `team_members`, `contacts`, `contact_identities`, `integration_connections` — exatamente estas seis tabelas | `clinic_settings`: `clinic_id`, `setting_key`, `value_json`, `inherits_org`, `version`, `status`; `teams`: `id`, `clinic_id`, `name`, `queue_type`; `team_members`: `team_id`, `user_id`, `capacity`, `active`; `contacts`: `id`, `organization_id`, `name`, `primary_phone_e164`, `email`, `status`; `contact_identities`: `contact_id`, `channel`, `external_id`, `normalized_value`, `verified_at`; `integration_connections`: `id`, `clinic_id`, `provider`, `secret_ref`, `config_sanitized`, `health_status`, `last_tested_at` (sem valor secreto em claro). |
| P1-S01-T03 | Verificação integrada dos dez objetos de P1-S01-T01/T02 | Upgrade, FKs, escopo tenant/clínica e criação de terceira clínica por inserção/configuração. |

Não adicionar colunas de negócio, regras de unicidade ou tabelas fora desses contratos sem emenda da SPEC. Dados comuns (`id`, `created_at`, `updated_at`, `created_by`, `organization_id`, `clinic_id`, `version`) aplicam-se somente onde a seção 7 disser “quando aplicável”.

## Dados e regras

- `clinics.organization_id` referencia `organizations.id`.
- `memberships.user_id` referencia `profiles.id`; organization/clinic devem ser coerentes segundo a organização da clínica.
- `clinic_settings.clinic_id` referencia `clinics.id`; configurações futuras respeitam herança organização → clínica.
- `teams.clinic_id` referencia `clinics.id`; `team_members.team_id` e `user_id` referenciam equipe e perfil.
- `contact_identities.contact_id` referencia `contacts.id`; conexões pertencem a uma clínica.
- `integration_connections` persiste apenas referência do segredo; o valor secreto fica em Supabase Secrets/Vault.
- As constraints necessárias impedem FKs órfãs e relações clínicas entre tenants incompatíveis, sem inventar unicidade de negócio não declarada.

## Fluxo de implementação

1. Conferir migration baseline, provider Supabase e migrations já aplicadas.
2. Aplicar T01: criar as quatro tabelas-base e relações.
3. Aplicar T02: criar as seis tabelas de configuração/equipe/contato/conexão metadata.
4. Aplicar T03: instalar em banco vazio e atualizar banco na versão anterior; revisar constraints, índices e rollback.
5. Criar terceira clínica como registro de dados e demonstrar que não exige migration.

| Cenário | Entrada | Resultado esperado | Evidência |
|---|---|---|---|
| T01 | migration em banco vazio | existem exatamente as quatro tabelas T01, cada uma com os campos listados e FKs válidas | catálogo Postgres e migration ID |
| T02 | aplicar migration dependente de T01 | existem exatamente as seis tabelas T02 e `integration_connections` não contém credencial em claro | catálogo, inspeção de schema e fixture de segredo sintético |
| Upgrade | banco na versão anterior | migrations concluem sem perda dos dados preexistentes | saída do pipeline e comparação de schema/dados |
| Terceira clínica | inserir clinic/org conforme fluxo | clínica fica cadastrável por dados usando schema existente | registro de teste e ausência de nova migration |
| Falha | migration inválida ou FK órfã | transação falha sem deixar schema parcialmente aplicado | código de saída e estado anterior preservado |

## Critérios de aceite

- [ ] **CA-P1-S01-01:** T01 cria `organizations`, `clinics`, `profiles`, `memberships` e apenas estas quatro tabelas desse recorte, com campos/FKs definidos acima.
- [ ] **CA-P1-S01-02:** T02 cria `clinic_settings`, `teams`, `team_members`, `contacts`, `contact_identities`, `integration_connections` e apenas estas seis tabelas desse recorte; conexão persiste somente `secret_ref`/config sanitizada.
- [ ] **CA-P1-S01-03:** migration completa instala os dez objetos, aplica limpa/upgrade, preserva dados existentes e permite cadastrar terceira clínica sem mudança de código/schema.

## TDD da SPEC

| Etapa | Prova | Ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | asserts de schema T01/T02 e upgrade | executar testes de migration contra banco vazio e fixture da versão anterior | falha nos objetos/constraints ausentes antes da implementação | log do runner e versão de schema |
| GREEN | sequência T01 → T02 | aplicar migrations e consultar `information_schema`/catálogo Postgres | CA-P1-S01-01/02 passam com conjuntos exatos; CA-P1-S01-03 passa | resultado automatizado e migration IDs |
| REFACTOR/REGRESSÃO | FK inválida, rollback, reapply e terceira clínica | executar os cenários da tabela acima | falha atômica, upgrade estável, nenhum segredo em claro e cadastro sem nova migration | relatório de regressão e revisão técnica |

**Fixtures:** dados sintéticos para duas clínicas e uma terceira; segredo dummy nunca parecido com credencial real.
**Evidência:** migration IDs, resultados de catálogo/constraints e execução do pipeline.

## Tasks vinculadas

| ID | Task | Dono | Critério binário | Recorte da prova | Evidência | Status |
|---|---|---|---|---|---|---|
| P1-S01-T01 | Criar organizations, clinics, profiles e memberships. | técnico de banco | CA-P1-S01-01: as quatro tabelas nomeadas e campos/FKs estão presentes; nenhum critério depende das tabelas T02. | verificar somente o conjunto T01 após migration | catálogo Postgres e migration ID | Liberada |
| P1-S01-T02 | Criar clinic_settings, teams, team_members, contacts, contact_identities e metadados de integration_connections. | técnico de banco | CA-P1-S01-02: as seis tabelas nomeadas e campos/FKs estão presentes; segredo não é armazenado em claro. | verificar somente o conjunto T02 e secret_ref | catálogo, schema e fixture sintética | Liberada |
| P1-S01-T03 | Validar instalação limpa, upgrade, integridade relacional e terceira clínica. | QA + técnico de banco | CA-P1-S01-03: banco vazio e upgrade passam; terceira clínica é criada sem nova migration. | cenários Upgrade/Terceira clínica/Falha | relatório do pipeline e evidência do registro de teste | Liberada |

## Emendas

| Data | Origem | Alteração | Motivo |
|---|---|---|---|
| 2026-09-29 | Revisão da task P1-S01-T01 | Separados conjuntos T01 (4 tabelas) e T02 (6 tabelas); critérios agora nomeiam conjuntos exatos | Remover divergência entre descrição, aceite e escopo dos cartões |
