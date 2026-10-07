# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPEC P1-S01 completa, SPEC P1-S02 completa, P1-S03-T01 e P1-S03-T02 concluídas.
- Progresso da fase 1: 9/16 tasks concluídas (56,25%).
- P1-S01: CONCLUÍDA em 2026-10-03 (4 tasks). Banco real: 10 tabelas, 6 UNIQUEs, 3 clínicas.
- P1-S02: CONCLUÍDA em 2026-10-06 (login, 23 policies RLS, matriz de role/revogação com trilha).
- P1-S03: T01 concluída (telas /admin, confirmação "teste ok"). T02 concluída em 2026-10-07: migration `p1_s03_t02_server_validation` (CHECKs de status; `invite_status` com trigger de aceitação por e-mail; RPC v3 com estados de convite; `effective_clinic_setting` com origem; criar clínica/editar organização exclusivos do owner). Runner 31/31; prova ao vivo: clinic_admin vê só a própria clínica, não edita clínica alheia nem organização, não cria clínica (403), não convida (42501), edita a própria (204). Confirmação humana: "teste ok" (teste B — login como clinic_admin da PS Caruaru). Revalidação pós-teste: organização e clínicas intactas, 4 constraints + trigger + 23 policies ativos.
- Próxima ação: P1-S03-T03 (auditoria/demonstração da 3ª clínica), mediante pedido do champion.
- Nenhuma credencial foi incluída.

- 2026-09-29: P1-S01-T04 adicionada para implementar/testar unicidade; regras detalhadas na SPEC.

- 2026-09-29: decisão documental sobre unicidade registrada nesta revisão; supersede a dúvida de chaves do T02 anotada anteriormente. T01 permanece concluída.
