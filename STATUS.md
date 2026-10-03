# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; P1-S01-T01, T02, T04 e P1-S02-T01 concluídas.
- Progresso da fase 1: 4/16 tasks concluídas (25%).
- P1-S01: T01, T02 e T04 concluídas. Última task da SPEC: T03 (prova integrada), desbloqueada em 2026-10-02 pela decisão da consultora: `memberships` mantém a PK técnica `id` da migration T01 aplicada e a unicidade de vínculo passa a ser constraint UNIQUE (SPEC emendada nesta data). Ordem: T01 → T02 → T04 → T03. Manifesto e README informam 16 tasks.
- P1-S02: T01 concluída em 2026-10-03 (login e-mail/senha decidido por Felipe; convite pelo gestor via RPC `admin_invite_user` + Edge Function `admin-invite-user` v2; auto-cadastro público bloqueado; memberships owner criadas; CA-P1-S02-01 validado — anon não lê dados operacionais). Próximas: T02 (RLS por organização/clínica) e T03 (matriz por role/revogação).
- Próxima ação: implementar P1-S02-T02 (políticas RLS por organização/clínica); T03 de P1-S01 segue aguardando a migration aditiva da UNIQUE de vínculo de `memberships`.
- Nenhuma credencial foi incluída.

- 2026-09-29: P1-S01-T04 adicionada para implementar/testar unicidade; regras detalhadas na SPEC.

- 2026-09-29: decisão documental sobre unicidade registrada nesta revisão; supersede a dúvida de chaves do T02 anotada anteriormente. T01 permanece concluída.
