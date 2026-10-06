# Estado atual — Adapta Cliente

- task_id: P1-S03-T02
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P1-S03-admin-organizacao.md
- etapa: implementada (aguarda teste humano)
- autorizacao_implementacao: confirmada — 2026-10-06, "implementar a proxima task" (Felipe, owner)
- teste_humano: pendente — opção A: owner usa /admin normalmente e confirma; opção B: entrar como teste.clinicadmin@ps-teste.local (clinic_admin da PS Caruaru) em https://login-crm-estetica-e388e--preview.goskip.app/admin e verificar que só enxerga a PS Caruaru
- verificacao_automatica: passou — runner PGlite scripts/test_s03_t02.js 31/31; prova ao vivo no banco real: clinic_admin vê só PSC; PATCH em PSR sem efeito; POST clínica nova 403; PATCH organização sem efeito; convite 42501 "somente owner"; PATCH na própria PSC 204; constraints (3), trigger de aceitação, `effective_clinic_setting`, `is_org_owner` e 23 policies ativos; convite real nasceu invited e virou accepted na confirmação de e-mail
- ultima_acao: migration `p1_s03_t02_server_validation` aplicada (campos, herança, estados de convite, restrição de role); clinic_admin sintético criado via RPC (dados de apoio); relatório artifacts/RELATORIO_P1_S03_T02_20261006.md; SQL em artifacts/p1_s03_t02_server_validation.sql
- proxima_acao: aprovação do teste humano conclui a task; depois P1-S03-T03 (auditoria/demonstração da 3ª clínica)
- atualizado_em: 2026-10-06T15:40:00-03:00
