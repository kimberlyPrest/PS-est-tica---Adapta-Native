# Estado atual — Adapta Cliente

- task_id: P2-S07-T03 (console de agentes e prompts) — IMPLEMENTADA, aguardando aceite do owner
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S07-copiloto-da-atendente-e-prompts.md
- etapa: aguardando_aceite_humano
- teste_humano: P2-S07-T02 ACEITA ("teste ok", 26/10); T03 implementada em 27/10 madrugada
- verificacao_automatica: migration p2_s07_t03_console_prompts APLICADA no Supabase real (7 RPCs + guardião sandbox); runner PGlite 25/25 (scripts/work/p2s07-t03/test_t03.js); Skip v0.0.58 QA verde; CA-05 (publicar sem sandbox recusado, volta restaura), CA-06 (isolamento A≠B, 403 sem vínculo, origem do efetivo), CA-07 (stats por clínica) provados
- ultima_acao: T03 implementada (aba Instruções em /admin/agentes + indicador em /filas)
- proxima_acao: aceite do Felipe → T04 (matriz + demonstração ponta a ponta da fase 2)
- atualizado_em: 2026-10-27T00:30:00-03:00
