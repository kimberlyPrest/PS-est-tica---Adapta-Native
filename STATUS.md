# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPEC P1-S01 completa, SPEC P1-S02 completa, SPEC P1-S03 completa; P1-S04-T01 e P1-S04-T02 concluídas.
- Progresso da fase 1: 11/16 tasks concluídas (68,75%); P1-S04-T03 é a última da SPEC de segredos.
- P1-S01: CONCLUÍDA em 2026-10-03 (4 tasks). Banco real: 10 tabelas, 6 UNIQUEs, clínicas.
- P1-S02: CONCLUÍDA em 2026-10-06 (login, 23 policies RLS, matriz de role/revogação com trilha).
- P1-S03: COMPLETA em 2026-10-08 (T01 telas, T02 validação server-side, T03 demonstração/auditoria — aceite humano).
- P1-S04: T01 concluída (segredo no Vault + secret_ref opaco, "sim"). T02 concluída em 2026-10-08 (versionamento imutável + teste sanitizado + audit log): aceite inicial "aprovado" e confirmação por roteiro humano de 6 passos no harness artifacts/harness-segredos-v1-20261008.html ("teste ok") — salvar → rotacionar → testar → listar versões → rollback → auditoria, com verificação de vazamento em cada resposta. Revalidação pós-roteiro: 6 versões, 13 auditorias, ZERO vazamentos (trilha e versões), 2 policies novas, 5 RPCs ativas.
- Próxima ação: P1-S04-T03 (prova de não exposição, falhas 401/429/timeout e rollback) — mediante pedido de Felipe.
- Nenhuma credencial foi incluída (segredos de teste são sintéticos).
