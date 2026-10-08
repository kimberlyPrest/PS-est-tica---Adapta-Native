# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPEC P1-S01 completa, SPEC P1-S02 completa, SPEC P1-S03 completa; P1-S04-T01 implementada (aguarda teste humano).
- Progresso da fase 1: 10/16 tasks concluídas (62,5%); P1-S04-T01 implementada, pendente de teste humano.
- P1-S01: CONCLUÍDA em 2026-10-03 (4 tasks). Banco real: 10 tabelas, 6 UNIQUEs, clínicas.
- P1-S02: CONCLUÍDA em 2026-10-06 (login, 23 policies RLS, matriz de role/revogação com trilha).
- P1-S03: COMPLETA em 2026-10-08 (T01 telas, T02 validação server-side, T03 demonstração/auditoria — aceite humano).
- P1-S04: T01 implementada em 2026-10-08 — migration `p1_s04_t01_secret_server_side`: RPC `admin_save_integration_secret` grava o segredo exclusivamente no Supabase Vault e deixa na conexão só a referência opaca `vault:<uuid>`; resposta retorna apenas estado + sufixo mascarado (nunca o valor); rotação invalida o último teste; RPC `admin_get_connection_status` para consulta sem valor; EXECUTE concedido só a authenticated. Runner PGlite 22/22; prova ao vivo via API: owner salvou segredo sintético sem exposição (grep na resposta), rotação sem exposição, anon 401, sales 42501.
- Próxima ação: teste humano de P1-S04-T01; depois P1-S04-T02 (formulário de conexão, teste sanitizado, versionamento e audit log).
- Nenhuma credencial foi incluída (segredo de teste é sintético).
