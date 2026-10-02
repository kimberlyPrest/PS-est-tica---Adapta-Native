# Estado atual — Adapta Cliente

- task_id: P1-S02-T01
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P1-S02-auth-rls.md
- etapa: aguardando_teste_humano
- autorizacao_implementacao: confirmada — 2026-10-02 16:10, "decisão enviada" (Form com método de login: E-mail e senha) (Felipe, owner)
- teste_humano: pendente
- verificacao_automatica: passou — anon REST: 12/12 (10 tabelas bloqueadas sem sessão, auto-cadastro público bloqueado por trigger pré-existente, login inválido rejeitado); Edge Function admin-invite-user v2: 4/4 negativos (401 sem token, 401 anon, 401 anon com payload, 405 GET); harness validado em navegador (anon 200/[] bloqueado, senha errada rejeitada); memberships owner criadas (2 clínicas, ativas); decisão de login registrada: e-mail e senha
- aprendizado: pendente
- ultima_acao: Edge Function admin-invite-user deployada (auth antes da validação de payload); memberships de owner criadas por dados; harness de teste em artifacts/teste-auth-ps.html
- proxima_acao: teste humano de Felipe (login, reset de senha e convite via harness); após aprovação, concluir T01
- atualizado_em: 2026-10-02T17:05:00-03:00
