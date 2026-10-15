# Estado atual — Adapta Cliente

- task_id: P2-S01-T02
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S01-base-versionada-e-protegida.md
- etapa: CONCLUÍDA (2026-10-14) — sem aceite humano ainda (task de segurança; roteiro de conferência no relatório)
- entregue: migrations p2_s01_hardening (20261015015416) + p2_s01_hardening_role_nullable (20261015015903) aplicadas no Supabase e versionadas no repo (commit c2cfd79); handle_new_user nunca concede papel; profiles.role deprecada e nullable; policy legada USING(true) eliminada; runner scripts/test_p2_s01_t02_hardening.mjs 18/18 (reset cria 0 usuários; sem vínculo lê 0 em 13 tabelas; org A não lê perfis da org B; colega visível); cadastro público bloqueado AO VIVO (42501); senha do semeado trocada em 03/10; varredura de segredos na árvore: 0 ocorrências (e-mail pessoal removido da cópia local da migration de convite)
- pendencias_do_dono (ações no painel Supabase, não-SQL): desligar "Allow new users to sign up"; ativar TOTP p/ owner/clinic_admin; decisão sobre histórico Git (senha antiga no commit inicial, já trocada no banco)
- pendencia_tecnica: sincronizar no Skip a migration 20261002185527 higienizada (sem e-mail pessoal) — cópia local em work/p2s01/supabase/migrations/
- fase_2: 2/28 concluídas (T01 aceite ok; T02 aguarda aceite)
- proxima_acao: aceite do Felipe na T02; depois P2-S01-T03 (tipos/guardas/telas)
- atualizado_em: 2026-10-14T23:59:00-03:00
