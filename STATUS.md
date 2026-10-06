# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPEC P1-S01 completa (T01, T02, T04, T03), SPEC P1-S02 completa (T01, T02, T03) e P1-S03-T01 concluída.
- Progresso da fase 1: 8/16 tasks concluídas (50%).
- P1-S01: CONCLUÍDA em 2026-10-03. As 4 tasks fechadas: T01 (tenancy core), T02 (6 tabelas), T04 (unicidades) e T03 (prova integrada com migration aditiva da UNIQUE de vínculo de `memberships`). Banco real: 10 tabelas, 6 UNIQUEs, 3 clínicas.
- P1-S02: CONCLUÍDA em 2026-10-06. T01 (login e-mail/senha; convite via RPC `admin_invite_user`; auto-cadastro bloqueado), T02 (23 policies RLS; policy legada de profiles removida; confirmação "teste ok"), T03 (CHECK dos 7 papéis + trigger de trilha `updated_at`; runner 45/45; confirmação "aprovado").
- P1-S03: T01 concluída em 2026-10-06: telas responsivas /admin no app Skip "CRM Estética" (v0.0.2) — 4 abas (clínicas criar/editar; usuários/convites com papel por clínica via RPC; memberships revogar/reativar; equipes criar/ativar membros); atalho no Dashboard; proteção de rota (sem sessão → login; sem owner/clinic_admin → "Acesso restrito"). QA Skip 4/4; validação ao vivo com convite real (reception só PSO), equipe criada na PSR e sales bloqueado; confirmação humana "teste ok". Revalidação pós-teste: app no ar (HTTP 200), login owner 200, owner lê 3 clínicas/6 memberships/1 equipe via API, 23 policies e role_check intactos.
- Próxima ação: P1-S03-T02 (validação de campos/herança/estados de convite no servidor), mediante pedido do champion.
- Nenhuma credencial foi incluída.

- 2026-09-29: P1-S01-T04 adicionada para implementar/testar unicidade; regras detalhadas na SPEC.

- 2026-09-29: decisão documental sobre unicidade registrada nesta revisão; supersede a dúvida de chaves do T02 anotada anteriormente. T01 permanece concluída.
