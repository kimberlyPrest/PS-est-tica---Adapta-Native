# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPEC P1-S01 completa (T01, T02, T04, T03) e SPEC P1-S02 completa (T01, T02, T03).
- Progresso da fase 1: 7/16 tasks concluídas (43,75%).
- P1-S01: CONCLUÍDA em 2026-10-03. As 4 tasks fechadas: T01 (tenancy core), T02 (6 tabelas), T04 (unicidades) e T03 (prova integrada com migration aditiva da UNIQUE de vínculo de `memberships`). Banco real: 10 tabelas, 6 UNIQUEs, 3 clínicas.
- P1-S02: CONCLUÍDA em 2026-10-06. T01 concluída (login e-mail/senha; convite via RPC `admin_invite_user`; auto-cadastro bloqueado). T02 concluída (23 policies RLS, leitura por clínica/organização, escrita owner/clinic_admin; policy legada de profiles removida; runner 37/37; confirmação "teste ok"). T03 concluída (matriz por role/revogação: CHECK dos 7 papéis da SPEC + trigger de trilha `updated_at`; revogação soft remove acesso e preserva histórico; runner 45/45; revogação/reativação provadas ao vivo via API; confirmação "aprovado"). Banco real: 10 tabelas com RLS, 23 policies, constraint de role e trigger de trilha ativos.
- Próxima ação: SPEC P1-S03 (admin/organização) — T01 (telas responsivas), mediante pedido do champion.
- Nenhuma credencial foi incluída.

- 2026-09-29: P1-S01-T04 adicionada para implementar/testar unicidade; regras detalhadas na SPEC.

- 2026-09-29: decisão documental sobre unicidade registrada nesta revisão; supersede a dúvida de chaves do T02 anotada anteriormente. T01 permanece concluída.
