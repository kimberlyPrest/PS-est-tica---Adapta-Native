# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPEC P1-S01 completa (T01, T02, T04, T03), P1-S02-T01 e P1-S02-T02 concluídas.
- Progresso da fase 1: 6/16 tasks concluídas (37,5%).
- P1-S01: CONCLUÍDA em 2026-10-03. As 4 tasks fechadas: T01 (tenancy core), T02 (6 tabelas), T04 (unicidades) e T03 (prova integrada com migration aditiva da UNIQUE de vínculo de `memberships`). Banco real: 10 tabelas, 6 UNIQUEs, 3 clínicas.
- P1-S02: T01 concluída (login e-mail/senha; convite via RPC `admin_invite_user`; auto-cadastro bloqueado). T02 concluída em 2026-10-06: 23 policies RLS (leitura por clínica/organização, escrita por owner/clinic_admin), correção da policy legada de profiles, funções auxiliares anti-recursão; runner PGlite 37/37; revalidação pós-teste com evidência fresca (RLS ativa 10/10, 23 policies, 0 policies legadas, anon 0, B isolado na Caruaru, owner vê as 3 clínicas, UPDATE alheio sem efeito). Confirmação humana: "teste ok". Depois: T03 (matriz por role/revogação).
- Próxima ação: P1-S02-T03 (matriz por role/revogação), mediante pedido do champion.
- Nenhuma credencial foi incluída.

- 2026-09-29: P1-S01-T04 adicionada para implementar/testar unicidade; regras detalhadas na SPEC.

- 2026-09-29: decisão documental sobre unicidade registrada nesta revisão; supersede a dúvida de chaves do T02 anotada anteriormente. T01 permanece concluída.
