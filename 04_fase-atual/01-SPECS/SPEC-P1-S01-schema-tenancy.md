# P1-S01 — Esquema multi-clínica e migrations

**Fase:** 1
**Status:** liberada para implementação
**Dono:** owner e técnico de banco
**Origem no escopo:** seções 6.1, 7.1–7.3 e 18/Fase 1
**Degrau da solução:** construção mínima sobre Supabase/Postgres; somente as tabelas-base abaixo, sem implementar políticas RLS nem telas administrativas.

## Contexto e decisões fechadas

- **Estado atual verificado:** o destino desta SPEC é o projeto Supabase `psestetica` (ref `uhozizrpmmpemvegtqaq`). O app `CRM Estética` no Skip (projeto 62134) é uma superfície/projeto distinto e não é o destino das migrations Postgres desta SPEC. No Supabase já existe `public.profiles`; o histórico também contém a migration aplicada `noop_check_only`, sem operação de schema. Nenhum objeto de negócio foi alterado durante essa inspeção.
- **Estado desejado:** criar schema versionado para tenant, acesso inicial, configuração de clínica, equipes, contatos e metadados de conexão.
- **Decisões:** UUID e timestamps padrão; organização contém clínicas; memberships ligam usuário, organização, clínica e papel; migrations versionadas; segredos não são gravados no banco operacional. `profiles` é um contrato lógico da T01: em banco vazio a migration o cria; no Supabase existente a migration compatibiliza `public.profiles` de forma aditiva, preservando tabela e linhas. A migration `noop_check_only` permanece intacta no histórico.
- **Aprovação:** decisões humanas confirmadas; registro em “Decisões e aprovações” no pacote do cliente.

## Resultado observável

As migrations instalam os dez contratos de tabela enumerados abaixo com relações válidas em banco vazio e atualizam o Supabase `psestetica` a partir do baseline observado, preservando os dados de `public.profiles` e o histórico já aplicado. Depois da instalação, uma terceira clínica pode ser criada por dados, sem alteração de código ou schema.

## Escopo e limites

- **Inclui:** migrations, tabelas, chaves estrangeiras, constraints referencial/tenant necessárias às relações declaradas, índices de busca e rollback compatível.
- **Não inclui:** policies RLS (P1-S02), telas/configuração (P1-S03/P1-S04), vínculo/cache de paciente de Clínica Experts (P1-S05), dados reais, nem segredo de integração.
- **Atores:** técnico de banco e owner para revisão; migrations executadas pelo pipeline autorizado.
- **Superfície:** Supabase Postgres/migrations versionadas. Não executar SQL manual em produção.
- **Rollback:** migration reversível quando compatível com dados; se downgrade puder perder dados, usar migration corretiva aditiva e preservar histórico.

## Contrato exato de tabelas por task

| Task | Tabelas cobertas | Campos/contrato da seção 7 |
|---|---|---|
| P1-S01-T01 | Contrato de exatamente quatro tabelas: `organizations`, `clinics`, `profiles`, `memberships` | `organizations`: `id`, `name`, `status`, `timezone`; `clinics`: `id`, `organization_id`, `name`, `code`, `timezone`, `status`; `profiles`: `id=auth.users.id`, `name`, `status`; `memberships`: `user_id`, `organization_id`, `clinic_id`, `role`, `active`. `profiles` é criada em instalação limpa e compatibilizada sem recriação no baseline existente. |
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

1. Confirmar em execução que provider, nome/ref do destino são Supabase `psestetica`/`uhozizrpmmpemvegtqaq`; se o alvo não corresponder, encerrar sem aplicar migration. O projeto Skip `CRM Estética` não é alvo desta task.
2. Registrar baseline do catálogo e contagem de linhas de `public.profiles`, sem exportar dados pessoais; confirmar `noop_check_only` como migration histórica aplicada e não editá-la.
3. Aplicar T01: materializar os contratos das quatro tabelas ausentes; em instalação limpa criar as quatro, e no baseline existente alinhar `public.profiles` com alterações aditivas compatíveis, preservando todas as linhas e chaves existentes.
4. Aplicar T02: criar as seis tabelas de configuração/equipe/contato/metadados de conexão.
5. Aplicar T03: comprovar instalação vazia e upgrade do baseline observado; revisar constraints, índices, atomicidade e reversão segura. A nova migration deve seguir a convenção real do repositório e ser posterior à migration já aplicada.
6. Criar terceira clínica como registro de dados e demonstrar que não exige migration.

| Cenário | Entrada | Resultado esperado | Evidência |
|---|---|---|---|
| T01 limpo | migration em banco vazio | existem exatamente os quatro contratos T01, cada um com os campos listados e FKs válidas | catálogo Postgres e migration ID |
| T01 existente | baseline observado com `public.profiles` e `noop_check_only` aplicada | T01 materializa os contratos de tabela ausentes e alinha `profiles` sem apagar/recriar tabela, remover/alterar linhas ou reescrever histórico | catálogo antes/depois, contagem de linhas, migration ID |
| T02 | aplicar migration dependente de T01 | existem exatamente as seis tabelas T02 e `integration_connections` não contém credencial em claro | catálogo, inspeção de schema e fixture de segredo sintético |
| Upgrade | baseline `psestetica` observado, inclusive `public.profiles` e `noop_check_only` | migrations concluem sem perda de dados/IDs de `profiles`; `noop_check_only` continua registrada e intacta | saída do pipeline, catálogo e comparação de contagem/chaves |
| Alvo incorreto | conexão aponta para outro projeto, incluindo o app Skip | nenhuma migration é aplicada; execução termina com identificação do destino divergente | saída sanitizada do guard de destino |
| Terceira clínica | inserir clinic/org conforme fluxo | clínica fica cadastrável por dados usando schema existente | registro de teste e ausência de nova migration |
| Falha | migration inválida ou FK órfã | transação falha sem deixar schema parcialmente aplicado | código de saída e estado anterior preservado |

## Critérios de aceite

- [ ] **CA-P1-S01-01:** T01 materializa os contratos de `organizations`, `clinics`, `profiles`, `memberships` e apenas estas quatro tabelas desse recorte, com campos/FKs definidos acima. Em banco vazio cria as quatro; no baseline existente cria os contratos ausentes e compatibiliza `public.profiles` por mudanças aditivas, preservando tabela, IDs e linhas. Não executa `DROP`, rename/recriação, limpeza de dados ou edição de migration aplicada.
- [ ] **CA-P1-S01-02:** T02 cria `clinic_settings`, `teams`, `team_members`, `contacts`, `contact_identities`, `integration_connections` e apenas estas seis tabelas desse recorte; conexão persiste somente `secret_ref`/config sanitizada.
- [ ] **CA-P1-S01-03:** conjunto completo materializa os dez contratos em instalação limpa e em upgrade do baseline `psestetica`; preserva dados/IDs de `public.profiles`, mantém `noop_check_only` intacta e permite cadastrar terceira clínica sem mudança de código/schema. Se o guard detectar destino diferente do projeto/ref especificados, nenhuma migration é aplicada.

## TDD da SPEC

| Etapa | Prova | Ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | asserts de schema T01/T02, instalação limpa e fixture fiel ao baseline observado | executar testes de migration nos dois caminhos | falha nos contratos ausentes ou na preservação de `profiles` antes da implementação | log do runner, catálogo e versão de schema |
| GREEN | sequência T01 → T02 nos dois caminhos | aplicar migrations e consultar catálogo Postgres; comparar contagem/chaves preexistentes e migration history | CA-P1-S01-01/02/03 passam; os quatro contratos T01 e seis T02 são exatos e o histórico anterior permanece | resultado automatizado, migration IDs e comparação sanitizada |
| REFACTOR/REGRESSÃO | FK inválida, alvo incorreto, rollback/reapply e terceira clínica | executar os cenários da tabela acima | falha atômica; alvo incorreto não recebe escrita; upgrade preserva linhas e histórico; cadastro não cria nova migration | relatório de regressão e revisão técnica |

**Fixtures:** dados sintéticos para duas clínicas e uma terceira; segredo dummy nunca parecido com credencial real.
**Evidência:** migration IDs, resultados de catálogo/constraints e execução do pipeline.

## Tasks vinculadas

| ID | Task | Dono | Critério binário | Recorte da prova | Evidência | Status |
|---|---|---|---|---|---|---|
| P1-S01-T01 | Materializar organizations, clinics, profiles e memberships sem perder o baseline existente. | técnico de banco | CA-P1-S01-01: quatro contratos T01 presentes; em banco vazio, quatro tabelas criadas; no Supabase existente, contratos ausentes materializados e `profiles` alinhada aditivamente, preservando tabela/IDs/linhas e histórico. | verificar conjunto T01; comparar catálogo e contagem/chaves de `profiles` antes/depois | catálogo Postgres, migration ID e comparação sanitizada | Liberada |
| P1-S01-T02 | Criar clinic_settings, teams, team_members, contacts, contact_identities e metadados de integration_connections. | técnico de banco | CA-P1-S01-02: as seis tabelas nomeadas e campos/FKs estão presentes; segredo não é armazenado em claro. | verificar somente o conjunto T02 e secret_ref | catálogo, schema e fixture sintética | Liberada |
| P1-S01-T03 | Validar instalação limpa, upgrade do baseline observado, alvo e integridade relacional. | QA + técnico de banco | CA-P1-S01-03: banco vazio e Supabase `psestetica` passam; `profiles` e `noop_check_only` são preservados; alvo divergente não recebe escrita; terceira clínica é criada sem nova migration. | cenários T01 limpo/existente, Upgrade, Alvo incorreto, Terceira clínica e Falha | relatório do pipeline, comparação sanitizada e evidência do registro de teste | Liberada |

## Emendas

| Data | Origem | Alteração | Motivo |
|---|---|---|---|
| 2026-09-29 | Revisão da task P1-S01-T01 | Separados conjuntos T01 (4 tabelas) e T02 (6 tabelas); critérios agora nomeiam conjuntos exatos | Remover divergência entre descrição, aceite e escopo dos cartões |
| 2026-09-29 | Inspeção do baseline Supabase `psestetica` | SPEC passa a cobrir instalação limpa e upgrade real com `public.profiles` preexistente e `noop_check_only` aplicada; adiciona guard do projeto destino e preservação aditiva | Impedir aplicação no app Skip ou perda/recriação dos dados/histórico existentes |
