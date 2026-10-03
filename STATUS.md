# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPEC P1-S01 completa (T01, T02, T04, T03) e P1-S02-T01 concluída.
- Progresso da fase 1: 5/16 tasks concluídas (31,25%).
- P1-S01: CONCLUÍDA em 2026-10-03. As 4 tasks fechadas: T01 (tenancy core), T02 (6 tabelas), T04 (unicidades) e T03 (prova integrada com migration aditiva da UNIQUE de vínculo de `memberships` — decisão da consultora aplicada). Banco real: 10 tabelas, 6 UNIQUEs, terceira clínica (PS Olinda) cadastrada por dados pelo champion, sem nova migration.
- P1-S02: T01 concluída em 2026-10-03 (login e-mail/senha decidido por Felipe; convite pelo gestor via RPC `admin_invite_user` + Edge Function `admin-invite-user` v2; auto-cadastro público bloqueado; memberships owner criadas; CA-P1-S02-01 validado — anon não lê dados operacionais). Próximas: T02 (RLS por organização/clínica) e T03 (matriz por role/revogação).
- Próxima ação: implementar P1-S02-T02 (políticas RLS por organização/clínica às tabelas expostas).
- Nenhuma credencial foi incluída.

- 2026-09-29: P1-S01-T04 adicionada para implementar/testar unicidade; regras detalhadas na SPEC.

- 2026-09-29: decisão documental sobre unicidade registrada nesta revisão; supersede a dúvida de chaves do T02 anotada anteriormente. T01 permanece concluída.
