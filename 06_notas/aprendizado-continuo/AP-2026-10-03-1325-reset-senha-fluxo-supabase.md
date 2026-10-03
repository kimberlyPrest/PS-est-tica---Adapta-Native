# AP-2026-10-03-1325 — Reset de senha no Supabase: fluxo verify e limites de envio

- Status: candidato
- Escopo: projeto do cliente
- Task/SPEC: P1-S02-T01 / SPEC-P1-S02-auth-rls.md
- Sinal: o link de recuperação de senha do Supabase Auth não é uma sessão (JWT): o código precisa ser trocado por sessão via `/auth/v1/verify` antes de definir a senha. Além disso, cada novo pedido de reset invalida o token anterior e o Supabase aplica rate limit de envios por hora (429 over_email_send_rate_limit), o que gera loop de "token expirado" se vários resets forem disparados em sequência.
- Evidência: changelog 2026-10-02/03 (DEBUG task P1-S02-T01); reprodução do 429; login validado de ponta a ponta após definir senha direto no banco.
- Regra reutilizável: em fluxo de reset de senha, (1) trocar o código do e-mail por sessão via verify antes de qualquer chamada autenticada; (2) nunca disparar resets em sequência — um pedido novo invalida o anterior e o rate limit bloqueia novos envios; (3) para o champion, o caminho de menor fricção é definir a senha direto no banco (crypt/gen_salt) e validar o login por API.
- Quando aplicar: qualquer task que envolva Supabase Auth, convites ou recuperação de senha.
- Quando não aplicar: fluxos com frontend publicado com redirect próprio (o site consome o link direto).
- Confiança: alta — causas demonstradas em sequência no banco real.
- Privacidade: sem segredo, dado pessoal ou conteúdo bruto; senha provisória não registrada aqui.
