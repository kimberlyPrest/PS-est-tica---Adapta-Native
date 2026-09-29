# P1-S01 — Esquema multi-clínica e migrations

**Fase:** 1
**Status:** liberada para implementação
**Dono:** owner e técnico de banco
**Origem no escopo:** seções 6.1, 7.1–7.3 e 18/Fase 1
**Degrau da solução:** construção mínima sobre Supabase/Postgres; somente as tabelas-base abaixo, sem implementar políticas RLS nem telas administrativas.

## Contexto e decisões fechadas

- **Estado atual:** SPEC documental para implementação contra os arquivos e contratos do projeto. A SPEC não pressupõe inspeção nem alteração de ambiente remoto.
- **Estado desejado:** criar schema versionado para tenant, acesso inicial, configuração de clínica, equipes, contatos e metadados de conexão.
- **Decisões:** UUID e timestamps padrão; organização contém clínicas; memberships ligam usuário, organização, clínica e papel; migrations versionadas; segredos não são gravados no banco operacional. `profiles` é um contrato lógico da T01 vinculado a `auth.users.id`. O caminho de instalação/upgrade deve preservar dados e migrations já aplicadas, sem depender de um projeto remoto específico.
- **Aprovação:** decisões humanas confirmadas; registro em “Decisões e aprovações” no pacote do cliente.

## Resultado observável

As migrations instalam os dez contratos de tabela enumerados abaixo, incluindo campos comuns `id UUID`, `created_at` e `updated_at`, com relações válidas em banco vazio e atualizam o schema a partir do baseline existente no repositório, preservando os dados de `public.profiles` e o histórico já aplicado. Depois da instalação, uma terceira clínica pode ser criada por dados, sem alteração de código ou schema.

## Escopo e limites

- **Inclui:** migrations, tabelas, chaves estrangeiras, constraints referencial/tenant necessárias às relações declaradas, índices de busca e rollback compatível.
- **Não inclui:** policies RLS (P1-S02), telas/configuração (P1-S03/P1-S04), vínculo/cache de paciente de Clínica Experts (P1-S05), dados reais, nem segredo de integração.
- **Atores:** técnico de banco e owner para revisão; migrations executadas pelo pipeline autorizado.
- **Superfície:** Supabase Postgres/migrations versionadas. Não executar SQL manual em produção.
- **Rollback:** migration reversível quando compatível com dados; se downgrade puder perder dados, usar migration corretiva aditiva e preservar histórico.

## Contrato exato de tabelas por task

| Task | Tabelas cobertas | Campos/contrato da seção 7 |
|---|---|---|
| P1-S01-T01 | Contrato de exatamente quatro tabelas: `organizations`, `clinics`, `profiles`, `memberships` | `organizations`: `id` (PK), `name`, `status`, `timezone`; `clinics`: `id` (PK), `organization_id`, `name`, `code`, `timezone`, `status`; `profiles`: `id=auth.users.id` (PK/FK), `name`, `status`; `memberships`: `user_id`, `organization_id`, `clinic_id`, `role`, `active`; PK composta definida abaixo. `profiles` é criada em instalação limpa e compatibilizada sem recriação no baseline existente. |
| P1-S01-T02 | `clinic_settings`, `teams`, `team_members`, `contacts`, `contact_identities`, `integration_connections` — exatamente estas seis tabelas | `clinic_settings`: `id` (PK), `clinic_id`, `setting_key`, `value_json`, `inherits_org`, `version`, `status`; `teams`: `id` (PK), `clinic_id`, `name`, `queue_type`; `team_members`: `id` (PK), `team_id`, `user_id`, `capacity`, `active`; `contacts`: `id` (PK), `organization_id`, `name`, `primary_phone_e164`, `email`, `status`; `contact_identities`: `id` (PK), `contact_id`, `channel`, `external_id`, `normalized_value`, `verified_at`; `integration_connections`: `id` (PK), `organization_id`, `clinic_id` (nullable for organization-level connection), `provider`, `connection_key`, `secret_ref`, `config_sanitized`, `health_status`, `last_tested_at` (sem valor secreto em claro). |
| P1-S01-T04 | Constraints UNIQUE adicionais às PKs técnicas | Aplicar e provar exatamente as regras da seção “Chaves primárias e unicidade”; sem unicidade global de telefone/e-mail/identidade externa. |
| P1-S01-T03 | Verificação integrada dos dez objetos de P1-S01-T01/T02 | Upgrade, FKs, unicidades, escopo tenant/clínica e criação de terceira clínica por inserção/configuração. |

Não adicionar tabelas ou colunas fora desses contratos sem emenda da SPEC. Todas as dez tabelas têm PK UUID conforme a seção “Chaves primárias e unicidade” (PK simples `id`, exceto a PK composta de `memberships`), `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` e `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`; `profiles.id` referencia `auth.users(id)`. Os demais campos comuns (`created_by`, `organization_id`, `clinic_id`, `version`) aplicam-se onde a seção 7 ou a regra de escopo correspondente os exigir.

## Chaves primárias e unicidade

**Chaves primárias:** `organizations`, `clinics`, `clinic_settings`, `teams`, `team_members`, `contacts`, `contact_identities` e `integration_connections` têm `id UUID PRIMARY KEY` gerado no banco; `profiles.id` é UUID PK/FK para `auth.users(id)`. `memberships` é uma tabela de associação e usa PK composta `(user_id, organization_id, clinic_id, role)`, preservando o contrato T01 já concluído e sem adicionar coluna substituta. Todas também têm `created_at` e `updated_at` como `TIMESTAMPTZ NOT NULL DEFAULT now()`. As regras abaixo são constraints/indexes `UNIQUE` adicionais, distintas das PKs técnicas. Para `contact_identities`, portanto, cada linha tem identidade técnica estável (`id`) e a regra de negócio não transforma o trio em PK.

As constraints UNIQUE listadas consideram apenas registros persistidos; `active`/`status` não integra chave de identidade, portanto desativar e reativar reutiliza o mesmo registro.

| Tabela | Constraint UNIQUE adicional à PK | Regra e justificativa |
|---|---|---|
| `organizations` | Nenhuma | Nome não é único globalmente. |
| `clinics` | `(organization_id, code)`; `(id, organization_id)` como chave de suporte à FK tenant composta | Código identifica a clínica dentro da organização; a segunda chave garante integridade clinic/organization. Nomes podem se repetir. |
| `profiles` | Nenhuma | Um perfil por usuário Auth; nome não é único. |
| `memberships` | Nenhuma adicional; PK composta `(user_id, organization_id, clinic_id, role)` | A identidade da associação é usuário + organização + clínica + papel; permite múltiplos papéis/clínicas, e `active` fica fora para reativação sem duplicar vínculo. |
| `clinic_settings` | `(clinic_id, setting_key, version)` | Mantém histórico versionado da mesma chave; versões distintas coexistem. |
| `teams` | `(clinic_id, name)` | Nome de equipe é único dentro da clínica, não globalmente. |
| `team_members` | `(team_id, user_id)` | Um vínculo por pessoa/equipe; `capacity` e `active` são atributos desse vínculo. |
| `contacts` | Nenhuma | Telefone e e-mail não são únicos; contatos podem compartilhar dados ou estar ambíguos. |
| `contact_identities` | `(contact_id, channel, external_id)` quando `external_id` não for nulo | Evita repetir a mesma identidade no contato, mas permite a mesma identidade em contatos diferentes para suportar reconciliação de ambiguidade. `normalized_value` não é globalmente único. |
| `integration_connections` | `(organization_id, provider, connection_key)` quando `clinic_id IS NULL`; `(clinic_id, provider, connection_key)` quando `clinic_id IS NOT NULL` | Uma conexão por escopo, provedor e chave estável. Permite várias contas do mesmo provedor; `connection_key` não contém segredo e permanece estável durante rotação. |

Constraints compostas adicionais podem ser usadas como suporte referencial (por exemplo, garantir que clínica e organização de uma membership coincidam), mas não substituem nem ampliam as chaves de negócio acima. `memberships` usa a PK composta `(user_id, organization_id, clinic_id, role)` e `clinic_id` é obrigatório conforme seção 7.1; não há membership organizacional sem clínica nesta fase. `integration_connections.organization_id` e `connection_key` são obrigatórios; `clinic_id` nulo indica conexão da organização, preenchido indica override da clínica, sempre pertencente à mesma organização. As chaves de unicidade de conexão usam dois índices parciais para tratar `clinic_id` nulo; a resolução escolhe a chave da clínica antes da chave herdada da organização. A chave `(clinics.id, clinics.organization_id)` dá suporte à FK composta. Para `contact_identities` com `external_id` nulo, não aplicar unicidade de negócio além da PK técnica `id`.

## Dados e regras

- `clinics.organization_id` referencia `organizations.id`.
- `memberships.user_id` referencia `profiles.id`; organization/clinic devem ser coerentes segundo a organização da clínica.
- `clinic_settings.clinic_id` referencia `clinics.id`; configurações futuras respeitam herança organização → clínica.
- `teams.clinic_id` referencia `clinics.id`; `team_members.team_id` e `user_id` referenciam equipe e perfil.
- `contact_identities.contact_id` referencia `contacts.id`.
- `integration_connections.organization_id` referencia `organizations.id`; `(clinic_id, organization_id)` referencia `(clinics.id, organization_id)` quando `clinic_id` não é nulo, com `(clinics.id, organization_id)` único como suporte referencial. `clinic_id` nulo representa padrão organizacional; preenchido representa override da clínica. `connection_key` identifica de forma estável a conta/slot configurado, pode usar o ID externo não secreto e não muda com rotação do segredo. A resolução segue organização → clínica.
- `integration_connections` persiste apenas referência do segredo; o valor secreto fica em Supabase Secrets/Vault.
- As constraints de unicidade são exatamente as listadas na seção “Chaves primárias e unicidade”; FKs e chaves compostas impedem relações clínicas entre tenants incompatíveis.

## Fluxo de implementação

1. Revisar o schema e migrations existentes no repositório do projeto; preservar tabelas, IDs, linhas e histórico já aplicados.
2. Aplicar T01: materializar os contratos das quatro tabelas e a compatibilidade aditiva de `profiles`.
3. Aplicar T02: criar as seis tabelas de configuração/equipe/contato/metadados de conexão.
4. Aplicar T04 para as chaves de unicidade documentadas; manter constraints tenant-coerentes e migrações reversíveis quando seguro.
5. Aplicar T03: comprovar instalação vazia, upgrade, constraints, índices e rollback seguro.
6. Criar terceira clínica como registro de dados e demonstrar que não exige migration.

| Cenário | Entrada | Resultado esperado | Evidência |
|---|---|---|---|
| T01 limpo | migration em banco vazio | existem exatamente os quatro contratos T01, cada um com os campos listados e FKs válidas | catálogo Postgres e migration ID |
| T01 existente | baseline com `profiles` preexistente e migrations já aplicadas | T01 materializa os contratos de tabela ausentes e alinha `profiles` sem apagar/recriar tabela, remover/alterar linhas ou reescrever histórico | catálogo antes/depois, contagem de linhas, migration ID |
| T02 | aplicar migration dependente de T01 | existem exatamente as seis tabelas T02; `integration_connections` aceita padrão organization-level, override clinic-level e múltiplas chaves sem segredo em claro | catálogo, inspeção de schema e fixtures sintéticas |
| Upgrade | baseline do repositório, inclusive `profiles` e migrations já aplicadas | migrations concluem sem perda de dados/IDs de `profiles`; migrations anteriores permanecem registradas e intactas | saída do pipeline, catálogo e comparação de contagem/chaves |
| Unicidades | inserir duplicatas de cada chave definida e variantes que devem coexistir | duplicata da chave é rejeitada; papéis/clínicas diferentes, identidades em contatos diferentes, e-mail/telefone repetidos, versões distintas e chaves de conexão distintas para o mesmo provedor são aceitas | testes de constraints com fixtures sintéticas |
| Terceira clínica | inserir clinic/org conforme fluxo | clínica fica cadastrável por dados usando schema existente | registro de teste e ausência de nova migration |
| Falha | migration inválida ou FK órfã | transação falha sem deixar schema parcialmente aplicado | código de saída e estado anterior preservado |

## Critérios de aceite

- [ ] **CA-P1-S01-01:** T01 materializa os contratos de `organizations`, `clinics`, `profiles`, `memberships` e apenas estas quatro tabelas desse recorte, com campos/FKs definidos acima. Em banco vazio cria as quatro; em upgrade compatibiliza `profiles` por mudanças aditivas, preservando tabela, IDs, linhas e histórico aplicado. Não executa `DROP`, rename/recriação, limpeza de dados ou edição de migration aplicada.
- [ ] **CA-P1-S01-02:** T02 cria `clinic_settings`, `teams`, `team_members`, `contacts`, `contact_identities`, `integration_connections` e apenas estas seis tabelas desse recorte; conexão tem escopo organization/clinic e persiste somente `secret_ref`/config sanitizada.
- [ ] **CA-P1-S01-03:** conjunto completo materializa os dez contratos em instalação limpa e em upgrade; preserva dados/IDs de `profiles` e histórico aplicado e permite cadastrar terceira clínica sem mudança de código/schema.
- [ ] **CA-P1-S01-04:** T01/T02 criam as PKs descritas (inclusive a PK composta de `memberships`); T04 aplica e valida todas e somente as constraints/indexes `UNIQUE` adicionais da seção “Chaves primárias e unicidade”. Testes confirmam rejeição de duplicatas e coexistência dos casos explicitamente permitidos.

## TDD da SPEC

| Etapa | Prova | Ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | asserts de schema T01/T02, instalação limpa e fixture fiel ao baseline existente | executar testes de migration nos dois caminhos | falha nos contratos ausentes ou na preservação de `profiles` antes da implementação | log do runner, catálogo e versão de schema |
| GREEN | sequência T01 → T02 → T04 → T03 nos dois caminhos | aplicar migrations e consultar catálogo Postgres; comparar contagem/chaves preexistentes e migration history | CA-P1-S01-01/02/03/04 passam e o histórico anterior permanece | resultado automatizado, migration IDs e comparação sanitizada |
| REFACTOR/REGRESSÃO | FK inválida, duplicatas, rollback/reapply e terceira clínica | executar os cenários da tabela acima | duplicatas são rejeitadas conforme contrato; coexistências permitidas funcionam; upgrade preserva linhas/histórico; cadastro não cria nova migration | relatório de regressão e revisão técnica |

**Fixtures:** dados sintéticos para duas clínicas e uma terceira; segredo dummy nunca parecido com credencial real.
**Evidência:** migration IDs, resultados de catálogo/constraints e execução do pipeline.

## Tasks vinculadas

| ID | Task | Dono | Critério binário | Recorte da prova | Evidência | Status |
|---|---|---|---|---|---|---|
| P1-S01-T01 | Materializar organizations, clinics, profiles e memberships sem perder o baseline existente. | técnico de banco | CA-P1-S01-01: quatro contratos T01 presentes; em banco vazio, quatro tabelas criadas; em upgrade, contratos ausentes materializados e `profiles` alinhada aditivamente, preservando tabela/IDs/linhas e histórico. | verificar conjunto T01; comparar catálogo e contagem/chaves de `profiles` antes/depois | catálogo Postgres, migration ID e comparação sanitizada | Concluída — 2026-09-29 |
| P1-S01-T02 | Criar seis contratos T02, PKs, timestamps e conexões com escopo organization/clinic e connection_key. | técnico de banco | CA-P1-S01-02: os seis contratos e FKs estão presentes; connection_key é estável e segredo não é armazenado em claro. | verificar conjunto T02, escopos/herança e referência do segredo | catálogo, schema e fixtures sintéticas | Liberada |
| P1-S01-T04 | Aplicar e validar constraints UNIQUE adicionais às PKs técnicas. | técnico de banco + QA | CA-P1-S01-04: duplicatas violadoras são rejeitadas e coexistências permitidas pela seção “Chaves primárias e unicidade” são aceitas. | inserir duplicata e par permitido para cada chave, inclusive índices parciais de conexões | testes automatizados de constraints e catálogo do schema | Liberada |
| P1-S01-T03 | Validar instalação limpa, upgrade do baseline e integridade relacional. | QA + técnico de banco | CA-P1-S01-03: instalação limpa e upgrade passam; `profiles` e o histórico aplicado são preservados; terceira clínica é criada sem nova migration. | cenários T01 limpo/existente, Upgrade, Unicidades, Terceira clínica e Falha | relatório do pipeline, comparação sanitizada e evidência do registro de teste | Liberada |

## Emendas

| Data | Origem | Alteração | Motivo |
|---|---|---|---|
| 2026-09-29 | Revisão da task P1-S01-T01 | Separados conjuntos T01 (4 tabelas) e T02 (6 tabelas); critérios agora nomeiam conjuntos exatos | Remover divergência entre descrição, aceite e escopo dos cartões |
| 2026-09-29 | Inspeção anterior de ambiente externo | Registrava baseline remoto e guard de destino, informação removida nesta revisão documental por não ser necessária para definir o contrato local | Histórico da edição anterior; supersedido pela definição baseada nos arquivos do projeto |
| 2026-09-29 | Revisão dos contratos do escopo definitivo | Removida dependência de inspeção de sistema externo; formalizada T04 e unicidade por tabela, incluindo os casos que devem permanecer duplicáveis | Eliminar lacuna entre entidades do modelo e constraints implementáveis |
