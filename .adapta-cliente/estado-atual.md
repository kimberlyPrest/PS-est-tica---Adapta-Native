# Estado atual — Adapta Cliente

- task_id: P2-S07-T03 (console de agentes e prompts) — CORRIGIDA após o 1º teste do owner, aguardando novo aceite
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S07-copiloto-da-atendente-e-prompts.md
- etapa: aguardando_aceite_humano
- causa_da_correcao: o prompt criado na T01 está em `prompt_sets.agent_key = 'AG-01'` (não 'AG-14'); a tela consultava AG-14 e não encontrava nada → sem selo de origem e histórico inconsistente
- correcao: tela usa AG-01 (constante AGENTE_COPILOTOO = 'AG-01'); editor preenchido com o texto em uso (antes nascia vazio); histórico mostra a coluna Origem (Clínica × Organização); migration p2_s07_t03b devolve `origem` por linha
- verificacao_automatica: runner PGlite 25/25; ciclo provado no banco real (publicar sem sandbox = 42501 sandbox_reprovado; sandbox 10/10; publicar v1; efetivo vira 'propria'; Caruaru segue 'organizacao'); fixture limpa (só o set da organização permanece); Skip v0.0.59 QA verde
- proxima_acao: novo teste do Felipe na aba "Instruções do copiloto" (PS Recife) → T04 fecha a fase 2
- atualizado_em: 2026-10-27T13:15:00-03:00
