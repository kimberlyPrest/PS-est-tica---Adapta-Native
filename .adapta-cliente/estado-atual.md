# Estado atual — Adapta Cliente

- task_id: P2-S01-T04
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S01-base-versionada-e-protegida.md
- etapa: T03 CONCLUÍDA no Skip (v0.0.8 f299cf2 + v0.0.9 b215a07, QA verde); T04 em implementação (suíte de testes + varredura de segredos no QA)
- entregue_T03: types.ts do catálogo real (14 tabelas + 17 RPCs + Papel); guards.tsx (RequireAuth/RequireRole com AAL2/EmptyState/ErrorState); clinic-selector.tsx; app-shell.tsx; Inicio.tsx (/inicio, estado vazio); AdminProtegido.tsx (/admin owner/clinic_admin + AAL2); App.tsx (/signup removida; /dashboard→/inicio); Index.tsx sem link de cadastro e sem dica de credenciais; Dashboard.tsx e SignUp.tsx removidos; migration de convite 20261002185527 higienizada (e-mail pessoal fora da árvore); testes de tela 7/7 (Vitest local); 0 "as any" em chamada ao Supabase
- pendencias_da_task_T03: capturas por papel (humano) — sales vê só "Início"; owner vê "Início"+"Administração"; sem vínculo vê "sem acesso"
- pendencias_do_dono (painel Supabase, da T02): desligar "Allow new users to sign up"; ativar TOTP; decisão sobre histórico Git
- fase_2: 2/28 concluídas + T03 implementada e sincronizada (aguarda aceite humano) + T04 em andamento
- proxima_acao: concluir T04 (suíte no QA do Skip); depois capturas por papel da T03
- atualizado_em: 2026-10-18T18:51:00-03:00
