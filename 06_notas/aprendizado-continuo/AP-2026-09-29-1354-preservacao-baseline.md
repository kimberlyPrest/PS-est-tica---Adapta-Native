# AP-2026-09-29-1354 — Preservar baseline em migrations aditivas

- Status: candidato
- Escopo: projeto do cliente PS Estética
- Task/SPEC: P1-S01-T01 / `04_fase-atual/01-SPECS/SPEC-P1-S01-schema-tenancy.md`
- Sinal: o upgrade de um schema existente precisa ser demonstrado separadamente de uma instalação limpa; a tabela `profiles` já continha colunas e policies fora do contrato lógico novo.
- Evidência: testes PGlite limpo e upgrade; no upgrade, OID, contagem, fingerprint dos campos legados e policies pré-existentes iguais antes/depois; relatório de execução `artifacts/RELATORIO_P1_S01_T01_20260929.md`.
- Regra reutilizável: antes de migration aditiva em tabela existente, capture contagem e fingerprint dos campos que já existem, identidade da relação e policies; depois compare os mesmos itens, verificando separadamente a coluna nova. Contagem isolada não prova preservação.
- Quando aplicar: upgrade de banco com tabela/linhas/policies preexistentes que precisam ser mantidas.
- Quando não aplicar: instalação realmente vazia, quando não há baseline legado a preservar; ainda assim, execute os testes de contrato e integridade.
- Confiança: alta — regra verificada em fixture sintética de upgrade e contra o catálogo pós-migration do Supabase.
- Privacidade: registro sanitizado, sem credenciais, dados pessoais ou conteúdo bruto.
