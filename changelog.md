# Changelog do pacote do cliente

- 2026-09-29: fase 1 organizada em cinco SPECs e 15 tasks.
- 2026-09-29: pacote ampliado com o escopo definitivo completo, decisões/aprovações, visão, constituição, arquitetura do console, processo observado/alvo e registro do kick-off.

- 2026-09-29: corrigida a SPEC de schema da fase 1; tasks T01/T02 agora nomeiam conjuntos exatos de quatro e seis tabelas, com critérios correspondentes.

- 2026-09-29: critérios P1-S01 agora usam os IDs CA-P1-S01-01/02/03 em SPEC, tasks e Jornada.

- 2026-09-29: detalhados os campos exatos das seis tabelas T02 e alinhados os responsáveis técnicos da SPEC e das tasks.

- 2026-09-29: dúvida registrada durante a revisão de P1-S01-T01 foi resolvida: T01 cobre organizations, clinics, profiles e memberships; T02 cobre clinic_settings, teams, team_members, contacts, contact_identities e integration_connections; T03 prova o conjunto integrado.

- 2026-09-29: SPEC P1-S01 alinhada ao baseline observado do Supabase `psestetica`: `profiles` existente é preservada e compatibilizada aditivamente; `noop_check_only` permanece intacta; guard de destino exclui o app Skip como alvo de migrations.
- 2026-09-29: T01/T03, tasks, Jornada e rastreabilidade agora cobrem instalação limpa, upgrade do baseline existente, preservação de IDs/linhas e validação de alvo.
- 2026-09-29: implementada P1-S01-T01 no Supabase `psestetica` pela migration `20260929145212_p1_s01_t01_tenancy_core`; criou `organizations`, `clinics`, `memberships` e alinhou `profiles.status` aditivamente. Testes PGlite de instalação limpa, upgrade, FKs, rejeição cross-tenant e replay passaram; baseline da linha/OID/fingerprint e policies de `profiles` preservados, `noop_check_only` mantida. Os arquivos brutos de relatório e SQL citados na anotação original não integram este handoff e não estão disponíveis na workspace local auditada; o pacote mantém o resumo, o migration ID e o aceite humano.
- 2026-09-29 · Felipe F3 Energy Drink · Task P1-S01-T01 concluída: quatro contratos T01 presentes; profiles e histórico preservados, testes automáticos aprovados e confirmação humana “Teste OK — confirmei as quatro tabelas e profiles”. Evidência resumida no registro da task: migration `20260929145212_p1_s01_t01_tenancy_core` e confirmação humana; os artefatos brutos não estão incluídos neste pacote.
- 2026-09-29: DÚVIDA — P1-S01-T02 bloqueada antes da implementação. A SPEC enumera campos/FKs, mas não define claramente as chaves primárias e a unicidade de `clinic_settings`, `team_members` e `contact_identities`; a própria SPEC proíbe inventar unicidade de negócio. Consultora deve registrar a decisão aprovada para cada contrato antes da migration. Nenhuma tabela/dado foi alterado nesta análise.

- 2026-09-29: resolvida lacuna de unicidade de P1-S01: removidas referências a inspeção/guarda de sistema externo; adicionada P1-S01-T04 e matriz explícita de constraints e duplicatas permitidas na SPEC; detalhes da inspeção remota anterior ficam supersedidos, pois esta definição usa o contrato local do projeto.

- 2026-09-29: resolvida a dúvida de unicidade do T02 a partir dos contratos e requisitos do projeto; criada P1-S01-T04. T01 permanece concluída; T02 e T04 ficam liberadas para implementação conforme dependências.

- 2026-09-29: reconciliação documental: declarada PK técnica UUID `id` também em `contact_identities` e nas tabelas sem id listado; PK é criada em T01/T02 e T04 cuida das constraints UNIQUE adicionais; mantida unicidade de negócio condicional independente. Ordem operacional padronizada em T01 → T02 → T04 → T03; T01 permanece concluída.
- 2026-09-29: reanálise das 17:03 reconciliada nesta revisão: os bloqueios documentais anotados foram resolvidos por PK técnica explícita para `contact_identities`, remoção dos marcadores/duplicatas e ordem T01 → T02 → T04 → T03. Nenhuma migration T02 foi executada nesta atualização.

- 2026-09-29: auditoria de consistência: README e manifesto atualizados para 16 tasks; incluídos os dois arquivos 06_notas no manifesto; alinhados os campos comuns UUID/timestamps com §7 do escopo; integração por organização/clínica alinhada à herança existente; removida indicação de aprovação pendente, conforme registro de aprovações.

- 2026-09-29: conferência integral do pacote encontrou e corrigiu ainda: contador 15→16 e arquivos de aprendizado ausentes no manifesto; timestamps comuns ausentes da SPEC; chave estável e escopo organization/clinic de integration_connections ausentes apesar da herança definida no escopo; gates marcados pendentes apesar do registro aprovado. P1-S04 alinhada ao novo contrato.

- 2026-09-29: a auditoria preservou a estrutura associativa de `memberships` da T01 já concluída: PK composta `(user_id, organization_id, clinic_id, role)`, sem coluna `id` substituta. As demais tabelas seguem PK UUID `id`; T04 não altera a PK T01.

- 2026-09-29: manifesto agora lista todos os arquivos visíveis do pacote; as referências aos artefatos brutos de T01 foram identificadas como externas/indisponíveis nesta workspace e substituídas por uma descrição explícita do resumo e ID mantidos.

- 2026-09-30: DÚVIDA — Felipe solicitou transformar o protótipo local de registro de ponto da PS em versão online com login e dados centralizados. O registro de ponto e seu modelo de jornada não constam nas cinco SPECs aprovadas da fase 1; a P1-S02 cobre Auth/RLS do CRM, mas não define acesso, retenção, auditoria, correções, jornadas, intervalos ou isolamento de dados de ponto. Consultora/responsável pelo escopo deve definir e aprovar SPEC e task(s) para essa capacidade antes de conectar banco, ampliar autenticação ou publicar. Nenhuma alteração no Supabase/CRM e nenhuma publicação foram feitas para este pedido.
- 2026-09-30: complemento de requisitos informado por Felipe: uso do ponto online em tablet compartilhado na recepção; marcações e fotos precisam ficar armazenadas para consulta futura; gestor terá acesso específico de conferência e os registros serão fechados mensalmente. Regras ainda por aprovar/definir: identificação individual no tablet, retenção e acesso às fotos, fluxo de solicitação de correção, efeito do fechamento mensal e permissões para reabertura/alteração posterior. A capacidade continua fora das cinco SPECs aprovadas; não houve alteração do app/CRM, Supabase ou publicação.
- 2026-09-30: respostas de Felipe para detalhar o Ponto PS: identificação por PIN individual no tablet; acesso às fotos somente por gestor e administradores autorizados; necessidade de arquivo mensal consultável por busca para conferência futura em caso de problema. Não foi definido prazo numérico de retenção. RECOMENDAÇÃO pendente de aprovação para fechamento: gestor confere e fecha cada mês; após o fechamento, colaborador não altera marcações; correções são solicitadas ao gestor e qualquer reabertura/ajuste exige justificativa, preserva a marcação original e registra autor/data/alteração em trilha de auditoria; gestor confere e fecha novamente. Proposta de manter registros/fotos sem exclusão automática até aprovar política de retenção, sujeita a validação da política da empresa. Nenhuma implementação, alteração no CRM/Supabase ou publicação; capacidade ainda precisa de SPEC/task aprovada.
