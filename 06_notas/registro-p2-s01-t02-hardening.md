# Registro — P2-S01-T02 (hardening)

- Data: 2026-10-14 · Task: P2-S01-T02 · Status: concluída, aguarda aceite do dono
- Migration 20260929135430 (seed) foi ALTERADA APÓS APLICADA (cópia do repo, em P2-S01-T01): bloco de seed substituído por comentário; o banco não muda (migration já constava como aplicada). Registro exigido pela SPEC.
- Senha do usuário semeado: TROCADA em 2026-10-03 (fluxo P1-S02; valor nunca registrado).
- Cadastro público: bloqueado pelo trigger block_public_signup (prova ao vivo 2026-10-14: INSERT direto em auth.users → 42501 "cadastro público desativado"). O toggle "Allow new users to sign up" no dashboard Auth é ação do dono (camada de defesa extra).
- TOTP: requer ativação no dashboard Auth (ação do dono); exigência de aal2 no app entra na P2-S01-T03 (guardas de rota).
- Histórico Git: senha antiga permanece no commit inicial público (já trocada no banco). Decisão pendente do owner: reescrever histórico ou aceitar. Esta SPEC não reescreve sem a decisão.
