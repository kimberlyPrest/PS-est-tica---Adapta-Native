# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPEC P1-S01 completa, SPEC P1-S02 completa, P1-S03-T01 concluída e P1-S03-T02 implementada (aguarda teste humano).
- Progresso da fase 1: 8/16 tasks concluídas (50%); P1-S03-T02 implementada, pendente de aceite humano.
- P1-S01: CONCLUÍDA em 2026-10-03 (4 tasks). Banco real: 10 tabelas, 6 UNIQUEs, 3 clínicas.
- P1-S02: CONCLUÍDA em 2026-10-06 (login, 23 policies RLS, matriz de role/revogação com trilha).
- P1-S03: T01 concluída em 2026-10-06 (telas /admin no app Skip, QA 4/4, confirmação "teste ok"). T02 implementada em 2026-10-06: migration `p1_s03_t02_server_validation` — CHECKs de status (clinics active/inactive; clinic_settings draft/active), coluna `invite_status` (invited/accepted) com trigger de aceitação por confirmação de e-mail, RPC `admin_invite_user` v3 (convite nasce invited; reenvio não regride aceito), função `effective_clinic_setting` (valor efetivo + origem; draft sem efeito) e restrição de role central: criar clínica e editar organização exclusivos do owner (policies refinadas). Runner PGlite 31/31; prova ao vivo: clinic_admin sintético vê só a própria clínica, não edita clínica alheia nem organização, não cria clínica (403), não convida (42501), edita a própria (204); trigger de convite provado ao vivo. Aguardando teste humano.
- Próxima ação: teste humano de P1-S03-T02; após aprovação, P1-S03-T03 (auditoria/demonstração).
- Nenhuma credencial foi incluída.

- 2026-09-29: P1-S01-T04 adicionada para implementar/testar unicidade; regras detalhadas na SPEC.

- 2026-09-29: decisão documental sobre unicidade registrada nesta revisão; supersede a dúvida de chaves do T02 anotada anteriormente. T01 permanece concluída.
