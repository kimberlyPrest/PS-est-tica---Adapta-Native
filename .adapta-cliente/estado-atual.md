# Estado atual — Adapta Cliente

- task_id: P1-S01-T02
- spec: 04_fase-atual/01-SPECS/SPEC-P1-S01-schema-tenancy.md
- etapa: auditoria documental concluída; T02 segue liberada após T01 concluída
- autorizacao_implementacao: a autorização de implementação está registrada no projeto; esta revisão corrigiu documentação e não executou migration T02
- verificacao_automatica: conferidos os arquivos operacionais, removidos marcadores de conflito e validada a consistência de PK/unicidade, campos comuns, gates aprovados, contagem de tasks e ordem das tasks; `git diff --check` aprovado
- aprendizado: `contact_identities` tem PK técnica UUID `id`; `(contact_id, channel, external_id)` é UNIQUE condicional independente. Ordem única: T01 → T02 → T04 → T03
- ultima_acao: a reanálise de 17:03 identificou gaps agora corrigidos: PK técnica explícita no contrato, Jornada sem duplicatas nem marcadores, STATUS/changelog sem conflito e ordem executável alinhada nos arquivos de controle
- proxima_acao: implementar T02; depois validar as constraints UNIQUE em T04 e rodar a prova integrada T03
- atualizado_em: 2026-09-29
