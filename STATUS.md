# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, decomposta em cinco SPECs e 15 tasks liberadas para implementação.
- Progresso da fase 1: 1/15 tasks concluídas (6,7%).
- P1-S01: instalação limpa e upgrade do Supabase `psestetica` (`uhozizrpmmpemvegtqaq`) especificados; a tabela existente `public.profiles` foi preservada e compatibilizada aditivamente; a migration histórica `noop_check_only` permanece intacta. O app CRM Estética no Skip não é destino das migrations Postgres desta SPEC.
- P1-S01-T01: concluída em 2026-09-29 após teste humano aprovado pelo Felipe. Migration `20260929145212_p1_s01_t01_tenancy_core`; PGlite passou em instalação limpa, upgrade, FKs, isolamento tenant e replay; Supabase conferido após aplicação. Relatório e SQL entregues em artifacts.
- P1-S01-T02: bloqueada antes de implementação por decisão pendente da SPEC sobre chaves primárias/compostas e unicidade em `clinic_settings`, `team_members` e `contact_identities`. DÚVIDA registrada no changelog; nenhuma migration T02 aplicada.
- App Skip #62134: sem alterações nesta task; nenhuma publicação feita.
- Próxima ação: consultora especificar as chaves/restrições pendentes de T02; depois reanalisar e obter autorização explícita antes de implementar.
- Nenhuma credencial foi incluída.
