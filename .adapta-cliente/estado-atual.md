# Estado atual — Adapta Cliente

- task_id: P2-S01-T03
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S01-base-versionada-e-protegida.md
- etapa: IMPLEMENTADA (2026-10-18) — provas locais verdes; aguarda gravação no Skip + build + aceite humano
- entregue: types.ts gerado do catálogo real (14 tabelas + 17 RPCs + Papel); guards.tsx (RequireAuth/RequireRole com AAL2/EmptyState/ErrorState); clinic-selector.tsx; app-shell.tsx; pages Inicio.tsx (/inicio, estado vazio) e AdminProtegido.tsx (/admin owner/clinic_admin + AAL2); App.tsx (/signup removida; /dashboard→/inicio); testes de tela 7/7 (Vitest+Testing Library); 0 "as any" em chamada ao Supabase
- pendencias_da_task: gravar os 8 arquivos no Skip (ferramentas indisponíveis nesta sessão; prontos em work/p2s01/src/); migration 20261002185527 higienizada também pendente de sync no Skip; build npm run build no ambiente do app; capturas por papel (humano)
- pendencias_do_dono (painel Supabase, da T02): desligar "Allow new users to sign up"; ativar TOTP; decisão sobre histórico Git
- fase_2: 2/28 concluídas (T01, T02) + T03 implementada aguardando sync/aceite
- proxima_acao: sync no Skip quando ferramentas voltarem; depois P2-S01-T04 (suíte + CI)
- atualizado_em: 2026-10-18T18:20:00-03:00
