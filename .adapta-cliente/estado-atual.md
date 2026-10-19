# Estado atual — Adapta Cliente

- task_id: P2-S02-T03
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S02-conexao-real-clinica-experts.md
- etapa: T03 IMPLEMENTADA (2026-10-19) — Skip v0.0.15 (881cfcf), QA verde; testes de tela 8/8, suíte completa 20/20, runner da emenda 12/12 (PGlite); AGUARDA aceite humano (capturas dos 4 estados + negativa 403)
- entregue_T03: src/pages/IdentificarPaciente.tsx (tela /pacientes/identificar: campo qualquer formato + E.164 exibido; resultados um/multiplos/provavel/zero conforme SPEC; erros por code com correlation_id copiável; Buscar de novo com force_refresh; Confirmar vínculo chama RPC, provavel grava manual_provavel); src/pages/AdminConexoes.tsx (cartão Clínica Experts em /admin/conexoes: situação/último teste/Testar conexão via admin_test_connection/Trocar token via admin_save_integration_secret — valor nunca volta à tela; rota com RequireRole owner/clinic_admin + AAL2); src/lib/experts-api.ts (cliente da função v2 + mensagens por code); src/App.tsx + app-shell.tsx (rotas e menu novos); migration 20261019190000_p2_s02_t03_link_emenda.sql APLICADA NO SUPABASE REAL (link_expert_patient aceita sales/reception/post_sales/manager para criar; unlink_expert_patient nova, só owner/clinic_admin; manual_provavel confidence 0.7; contato de outra org recusado; grants só authenticated); src/pages/IdentificarPaciente.test.tsx (8 testes); scripts/test_p2_s02_t03_emenda.mjs (12 testes)
- pendencias_da_task: aceite humano (capturas dos 4 estados + usuário de outra clínica 403) — pré-condição do token; T04 precisa dos 3 telefones de conferência + token no Vault
- pendencias_do_dono (arrastadas): toggles Auth (signup off no TOPO de Providers + TOTP); capturas 3.b/3.c da P2-S01-T03; decisão histórico Git
- fase_2: 4/28 concluídas + T01/T02/T03 implementadas (aguardam token + aceites)
- proxima_acao: P2-S02-T04 (matriz com telefones reais + varredura de dado sensível) quando o token chegar; atualizar linha da T03 no quadro fase.md
- atualizado_em: 2026-10-19T19:40:00-03:00
