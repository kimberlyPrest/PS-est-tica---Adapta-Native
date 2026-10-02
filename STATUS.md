# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; P1-S01-T01 e P1-S01-T02 concluídas.
- Progresso da fase 1: 2/16 tasks concluídas (12,5%).
- P1-S01: T01 e T02 concluídas; constraints UNIQUE ficam para T04. Dúvida aberta para a consultora: PK composta de `memberships` na SPEC emendada vs `PRIMARY KEY (id)` da migration T01 aplicada. Ordem: T01 → T02 → T04 → T03. Manifesto e README informam 16 tasks.
- Próxima ação: resolver a dúvida da PK de `memberships` com a consultora; depois implementar T04 e executar a prova integrada T03.
- Nenhuma credencial foi incluída.

- 2026-09-29: P1-S01-T04 adicionada para implementar/testar unicidade; regras detalhadas na SPEC.

- 2026-09-29: decisão documental sobre unicidade registrada nesta revisão; supersede a dúvida de chaves do T02 anotada anteriormente. T01 permanece concluída.
