# Estado atual — Adapta Cliente

- task_id: P2-S01-T04
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S01-base-versionada-e-protegida.md
- etapa: T03 e T04 IMPLEMENTADAS e sincronizadas no Skip (v0.0.8 f299cf2 · v0.0.9 b215a07 · v0.0.10 4f8b442 — QA verde nas três); T04 aguarda aceite humano
- entregue_T04: package.json com npm test → vitest run (antes era echo "no tests"); vitest.config.ts (jsdom, globals); src/pages/Inicio.test.tsx (7 testes de tela); scripts/scan-secrets.mjs (varredura de segredos, 5 padrões, exit 1 em achado); prova da suíte: exit 0 verde / exit 1 com teste falho de propósito; prova da varredura: 0 achados na árvore, JWT de teste → exit 1
- pendencias_da_task: plataforma Skip não executa a suíte do projeto (qa.test.ran=false — limitação do runner); clone→reset→diff formal exige Supabase CLI (fora do sandbox); capturas por papel da T03 (humano)
- pendencias_do_dono (painel Supabase, da T02): desligar "Allow new users to sign up"; ativar TOTP; decisão sobre histórico Git
- fase_2: 2/28 concluídas + T03 implementada + T04 implementada (aguardam aceite)
- proxima_acao: aceite humano das capturas por papel (T03); depois P2-S02-T01 (conexão real Clínica Experts) mediante token no Vault
- atualizado_em: 2026-10-18T19:05:00-03:00
