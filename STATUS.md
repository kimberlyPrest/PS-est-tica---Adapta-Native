# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, decomposta em cinco SPECs e 15 tasks liberadas para implementação.
- P1-S01: instalação limpa e upgrade do Supabase `psestetica` (`uhozizrpmmpemvegtqaq`) especificados; a tabela existente `public.profiles` deve ser preservada e compatibilizada aditivamente; a migration histórica `noop_check_only` permanece intacta. O app CRM Estética no Skip não é destino de migration Postgres.
- P1-S01-T01: migration `20260929145212_p1_s01_t01_tenancy_core` aplicada no Supabase autorizado; testes automáticos de instalação limpa e upgrade passaram; aguarda teste humano antes da conclusão. Evidências em `artifacts/RELATORIO_P1_S01_T01_20260929.md` e SQL em `artifacts/20260929145212_p1_s01_t01_tenancy_core.sql` no ambiente de execução.
- Roadmap: cinco fases descritas no escopo integral; materiais executáveis detalhados neste pacote apenas para fase 1.
- Implementação de produto: iniciada em P1-S01-T01; demais tasks inalteradas.
- Nenhuma credencial foi incluída.
