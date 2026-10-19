# Estado atual — Adapta Cliente

- task_id: P2-S02-T01
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S02-conexao-real-clinica-experts.md
- etapa: IMPLEMENTADA (2026-10-19) — código + matriz 23/23 no sandbox; Skip v0.0.12 (447a9e0) QA verde; FALTA teste de conexão real a partir da função publicada (passo 4 da task) — depende do token no Vault
- entregue: supabase/functions/_shared/providers/clinica-experts.ts (expertGet com User-Agent próprio PSEstetica-CRM/1.0 +supabase-edge, x-correlation-id, Authorization Bearer; classifyExpertError com os 4 formatos do contrato + Cloudflare 1010 → bloqueio_de_borda; httpDeErro (404/400/503/504/502); rateBudget 90/min guiado por x-ratelimit-remaining — abaixo de 10 espera a virada do minuto; retry 2× para transitórios; telemetria sanitizada — token NUNCA em log/erro/retorno; lerPacienteMinimo descarta documents/address/email/annotation/occupation/marital_status/contacts); scripts/test_p2_s02_t01.mjs (matriz 23/23: 9 classificação + 6 http + 3 budget + 3 leitor + UA + smoke expertGet)
- pendencias_da_task: (1) EXPERT_API_BASE_URL nas secrets das funções + token no Vault via /admin (Felipe/suporte Experts); (2) teste de conexão real a partir da Edge Function publicada + diagnóstico sanitizado anexado; (3) deno test oficial na CI do Skip (roda local no sandbox com Node)
- pendencias_do_dono (arrastadas): toggles Auth (signup off no TOPO de Providers + TOTP); decisão histórico Git; capturas por papel T03 (3.b/3.c)
- fase_2: 4/28 concluídas (P2-S01 completa) + P2-S02-T01 implementada (aguarda token + aceite)
- proxima_acao: quando o token chegar → gravar no Vault pelo /admin → eu rodo o teste de conexão real e fecho a T01; depois P2-S02-T02 (busca em duas etapas + limitador)
- atualizado_em: 2026-10-19T17:35:00-03:00
