# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPEC P1-S01 completa, SPEC P1-S02 completa, P1-S03-T01 e P1-S03-T02 concluídas, P1-S03-T03 demonstrada (aguarda aceite humano).
- Progresso da fase 1: 9/16 tasks concluídas (56,25%); P1-S03-T03 demonstrada, pendente de aceite humano.
- P1-S01: CONCLUÍDA em 2026-10-03 (4 tasks). Banco real: 10 tabelas, 6 UNIQUEs, clínicas.
- P1-S02: CONCLUÍDA em 2026-10-06 (login, 23 policies RLS, matriz de role/revogação com trilha).
- P1-S03: T01 concluída (telas /admin, "teste ok"). T02 concluída (validação server-side, "teste ok" — teste B). T03 demonstrada em 2026-10-07: cadastro da clínica PS Jaboatão (PSJ) executado INTEIRAMENTE pela interface (sem SQL/migration), ciclo revogar→reativar pela UI com trilha updated_at visível na tela, setting em draft sem efeito e ativado passando a valer (effective_clinic_setting), nenhuma ação oferece SQL livre (página sem campo de SQL; escrita só por RLS/RPC). Estado: 4 clínicas (PSC, PSJ, PSO, PSR), 8 memberships, 23 policies.
- Próxima ação: aceite humano de P1-S03-T03; após aprovação, SPEC P1-S03 COMPLETA e próxima é P1-S04-T01 (gravação server-side de segredos).
- Nenhuma credencial foi incluída.

- 2026-09-29: P1-S01-T04 adicionada para implementar/testar unicidade; regras detalhadas na SPEC.

- 2026-09-29: decisão documental sobre unicidade registrada nesta revisão; supersede a dúvida de chaves do T02 anotada anteriormente. T01 permanece concluída.
