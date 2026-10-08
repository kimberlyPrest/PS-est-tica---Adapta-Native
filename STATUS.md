# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPEC P1-S01 completa, SPEC P1-S02 completa, SPEC P1-S03 COMPLETA (T01, T02 e T03).
- Progresso da fase 1: 10/16 tasks concluídas (62,5%).
- P1-S01: CONCLUÍDA em 2026-10-03 (4 tasks). Banco real: 10 tabelas, 6 UNIQUEs, clínicas.
- P1-S02: CONCLUÍDA em 2026-10-06 (login, 23 policies RLS, matriz de role/revogação com trilha).
- P1-S03: COMPLETA em 2026-10-08. T01 concluída (telas /admin, "teste ok"). T02 concluída (validação server-side, "teste ok" — teste B). T03 concluída: demonstração aprovada — cadastro da clínica PS Jaboatão (PSJ) executado INTEIRAMENTE pela interface (sem SQL/migration), ciclo revogar→reativar pela UI com trilha updated_at visível na tela, setting em draft sem efeito e ativado passando a valer (effective_clinic_setting), nenhuma ação oferece SQL livre. Confirmação humana: "Teste OK — aprovar P1-S03-T03 e fechar a SPEC P1-S03" (Felipe, owner, 2026-10-08). Revalidação pós-teste: 4 clínicas (PSC, PSJ, PSO, PSR), 8 memberships ativas, 23 policies, 3 constraints de status/role, 2 triggers (trilha + convite), app 200, owner lê as 4 clínicas via API, anon lê 0.
- Próxima ação: P1-S04-T01 (gravação server-side de segredos) — mediante pedido de Felipe.
- Nenhuma credencial foi incluída.

- 2026-09-29: P1-S01-T04 adicionada para implementar/testar unicidade; regras detalhadas na SPEC.

- 2026-09-29: decisão documental sobre unicidade registrada nesta revisão; supersede a dúvida de chaves do T02 anotada anteriormente. T01 permanece concluída.
