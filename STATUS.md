# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; P1-S01-T01, T02 e T04 concluídas.
- Progresso da fase 1: 3/16 tasks concluídas (18,75%).
- P1-S01: T01, T02 e T04 concluídas. Última task da SPEC: T03 (prova integrada), desbloqueada em 2026-10-02 pela decisão da consultora: `memberships` mantém a PK técnica `id` da migration T01 aplicada e a unicidade de vínculo passa a ser constraint UNIQUE (SPEC emendada nesta data). Ordem: T01 → T02 → T04 → T03. Manifesto e README informam 16 tasks.
- Próxima ação: aplicar a migration aditiva da UNIQUE de vínculo de `memberships` `(user_id, organization_id, clinic_id, role)` e então executar a T03 (prova integrada), desbloqueada pela decisão da consultora de 2026-10-02 (PK técnica `id` mantida; unicidade vira constraint UNIQUE).
- Nenhuma credencial foi incluída.

- 2026-09-29: P1-S01-T04 adicionada para implementar/testar unicidade; regras detalhadas na SPEC.

- 2026-09-29: decisão documental sobre unicidade registrada nesta revisão; supersede a dúvida de chaves do T02 anotada anteriormente. T01 permanece concluída.
