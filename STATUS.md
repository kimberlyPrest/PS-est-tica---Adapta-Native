# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPECs P1-S01, P1-S02 e P1-S03 completas; P1-S04-T01 e T02 concluídas; P1-S04-T03 implementada (aguarda teste humano).
- Progresso da fase 1: 11/16 tasks concluídas (68,75%); P1-S04-T03 implementada, pendente de teste humano.
- P1-S01: CONCLUÍDA em 2026-10-03 (4 tasks). Banco real: 10 tabelas, 6 UNIQUEs, clínicas.
- P1-S02: CONCLUÍDA em 2026-10-06 (login, 23 policies RLS, matriz de role/revogação com trilha).
- P1-S03: COMPLETA em 2026-10-08 (T01 telas, T02 validação server-side, T03 demonstração/auditoria — aceite humano).
- P1-S04: T01 concluída (segredo no Vault + secret_ref opaco, "sim"). T02 concluída (versionamento imutável + teste sanitizado + audit log; "aprovado" e "teste ok" no roteiro de 6 passos). T03 implementada em 2026-10-08 — migration p1_s04_t03_failure_proofs: admin_test_connection v2 com correlation_id (id da auditoria no diagnóstico), cofre indisponível capturado com EXCEPTION → falha sanitizada sem falso sucesso, referência inválida → falha clara; rollback da T02 reprovado na matriz (restaura secret_ref, reseta health, auditoria só cresce). Runner PGlite 24/24; prova ao vivo: rollback v1 restaurado, falha forçada com correlation_id 9d9d3aaa, recuperação rollback v2 → teste ok, sales 42501, varredura final 0 vazamentos (20 auditorias, 8 versões).
- Próxima ação: teste humano de P1-S04-T03; depois P1-S05-T01 (cliente server-side HTTP) — última SPEC da fase 1.
- Nenhuma credencial foi incluída (segredos de teste são sintéticos).
