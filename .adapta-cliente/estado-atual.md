# Estado atual — Adapta Cliente

- task_id: P2-S01 — tela de segundo fator (extra, fora das 4 tasks da SPEC)
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S01-base-versionada-e-protegida.md
- etapa: T01–T04 concluídas; TELA DE SEGUNDO FATOR implementada (2026-10-18, v0.0.11 812ac41, QA verde) — aguarda aceite humano
- entregue_tela_mfa: src/pages/SegundoFator.tsx (enroll com QR + chave manual; challenge; verify; erros amigáveis; retorno automático ao /admin via ?next=); src/lib/auth-errors.ts (mensagens amigáveis extraídas de use-auth); guards.tsx com redirect automático (owner/clinic_admin sem AAL2 → /segundo-fator?next=/admin em vez de tela morta); rota /segundo-fator no App.tsx; vitest.config.ts com alias @; package.json com @testing-library/user-event; testes 12/12 (7 guarda + 5 tela MFA)
- como_usar: Felipe entra no preview → /admin → é levado a /segundo-fator → "Gerar código QR" → escaneia no Google Authenticator/1Password → digita o código de 6 dígitos → "Segundo fator ativado e verificado" → Continuar → /admin abre
- pendencias_da_task: aceite humano da tela MFA (Felipe parear o autenticador e entrar no /admin); capturas por papel da T03 (3.b vendas e 3.c /inicio sem dado)
- pendencias_do_dono (painel Supabase, da T02): desligar "Allow new users to sign up" (toggle no TOPO de Authentication→Providers); ativar TOTP na conta do painel; decisão sobre histórico Git
- fase_2: 2/28 concluídas + T03/T04 implementadas + tela MFA extra (aguardam aceites)
- proxima_acao: aceite da tela MFA; depois P2-S02-T01 (conexão real Clínica Experts) mediante token no Vault
- atualizado_em: 2026-10-18T20:20:00-03:00
