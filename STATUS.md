# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, decomposta em cinco SPECs e 15 tasks liberadas para implementação.
- Progresso da fase 1: 1/15 tasks concluídas (6,7%).
- P1-S01: instalação limpa e upgrade do Supabase `psestetica` (`uhozizrpmmpemvegtqaq`) especificados; a tabela existente `public.profiles` foi preservada e compatibilizada aditivamente; a migration histórica `noop_check_only` permanece intacta. O app CRM Estética no Skip não é destino das migrations Postgres desta SPEC.
- P1-S01-T01: concluída em 2026-09-29 após teste humano aprovado pelo Felipe. Migration `20260929145212_p1_s01_t01_tenancy_core`; PGlite passou em instalação limpa, upgrade, FKs, isolamento tenant e replay; Supabase conferido após aplicação. Relatório e SQL entregues em artifacts.
- App Skip #62134: sem alterações nesta task; nenhuma publicação feita.
- Próxima ação: aguardar novo pedido para iniciar outra task; T02 e demais tasks não foram iniciadas.
- Nenhuma credencial foi incluída.
