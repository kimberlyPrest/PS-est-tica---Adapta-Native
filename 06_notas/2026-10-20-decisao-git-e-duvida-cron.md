# Notas — 2026-10-20

## DEC-2026-10-20-01 — Histórico Git do repositório de handoff

**Decisão do owner (Felipe) em 2026-10-20, 14:22: MANTER o histórico completo.**

O repositório de handoff conserva todo o histórico de commits desde a fase 1 (incluindo as migrations aplicadas no banco real e seus relatórios). Justificativa: rastreabilidade das migrations aplicadas em produção — cada migration no Supabase real tem correspondência commit-a-commit no histórico.

Pendência de fechamento: confirmar com a consultora que essa decisão encerra o item "decisão sobre histórico Git" listado como pendência do dono na P2-S01-T02/T04 (a varredura de segredos da T02 já rodou limpa — 0 ocorrências — e a senha do semeado foi trocada em 03/10, então o histórico antigo não contém credencial válida).

## DÚVIDA-2026-10-20-01 — INTERNAL_JOB_SECRET no pg_cron (P2-S03-T02)

O contrato comum (§5) pede que o pg_cron dispare os consumidores com `INTERNAL_JOB_SECRET`. Impasse técnico encontrado na implementação da P2-S03-T02:

- O segredo não pode ser gravado no Vault via SQL (tabela `vault.secrets` nega INSERT/UPDATE ao papel do postgres — erro 42501 na tentativa).
- Solução provisória aplicada: segredo configurado como Edge Function secret no Skip (env `INTERNAL_JOB_SECRET`); os jobs do cron disparam as funções **sem** o header `x-internal-job` — as funções validam o header e hoje recusariam a chamada do cron (403), ou seja, **os consumidores não processam via cron até resolver**.

Pergunta à consultora: qual mecanismo oficial para o cron autenticar na Edge Function? Opções: (a) segredo em tabela interna de config do banco (não no Vault), lido por uma função SECURITY DEFINER que monta o header; (b) cron dispara uma RPC SECURITY DEFINER que faz o http_post com o header; (c) outra definida pela consultora. Enquanto isso, a fila pode ser drenada manualmente/disparo controlado para testes.