# Status do pacote do cliente

- Projeto: PS Estética.
- Escopo definitivo integral incluído, versão 3.1 de 29/09/2026.
- Aprovações humanas: confirmadas pela responsável; registro disponível na pasta do escopo.
- Fase atual: fase 1, cinco SPECs e 16 tasks; SPEC P1-S01 completa, SPEC P1-S02 completa, SPEC P1-S03 completa, **SPEC P1-S04 COMPLETA**.
- Progresso da fase 1: 12/16 tasks concluídas (75%); resta a SPEC P1-S05 (3 tasks).
- P1-S01: CONCLUÍDA em 2026-10-03 (4 tasks). Banco real: 10 tabelas, 6 UNIQUEs, clínicas.
- P1-S02: CONCLUÍDA em 2026-10-06 (login, 23 policies RLS, matriz de role/revogação com trilha).
- P1-S03: COMPLETA em 2026-10-08 (T01 telas, T02 validação server-side, T03 demonstração/auditoria — aceite humano).
- P1-S04: COMPLETA em 2026-10-08. T01 (segredo no Vault + secret_ref opaco, "sim"). T02 (versionamento imutável + teste sanitizado + audit log; "aprovado" + roteiro 6/6 "teste ok"). T03 (prova de não exposição, falhas sanitizadas com correlation_id e rollback; roteiro 6/6 "teste ok"): admin_test_connection v2 com correlation_id, cofre indisponível → falha sanitizada sem falso sucesso, rollback restaura sem apagar auditoria. Revalidação final: 12 versões, 30 auditorias, ZERO vazamentos (trilha, versões e conexões), 5 RPCs ativas.
- Próxima ação: P1-S05-T01 (cliente server-side HTTP com timeout, rate limiter e telemetria sanitizada) — mediante pedido de Felipe.
- Nenhuma credencial foi incluída (segredos de teste são sintéticos).
