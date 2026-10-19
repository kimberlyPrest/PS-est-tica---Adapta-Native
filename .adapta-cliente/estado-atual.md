# Estado atual — Adapta Cliente

- task_id: P2-S02-T02
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P2-S02-conexao-real-clinica-experts.md
- etapa: T01 e T02 IMPLEMENTADAS (2026-10-19) — Skip v0.0.12 (447a9e0) e v0.0.13 (1ec8b97), QA verde; matrizes 23/23 e 18/18; FALTAM os testes de conexão real (T01 passo 4 e T02 contra a API real) — dependem do token no Vault
- entregue_T02: supabase/functions/_shared/providers/expert-search.ts (buscarEmDuasEtapas: etapa a E.164 per_page=10; etapa b últimos 8 dígitos per_page=50 com filtro local de DDD; classificação um/multiplos/provavel/zero; candidatos com birth_masked **/**/AAAA; 429 propagado como limite_externo; budget local parametrizável 90/min); Edge Function search-expert-patient v2 (contrato de saída da SPEC: data{result_class, phone_e164, candidates[uuid,name,birth_masked,active], linked_patient_uuid, cache_hit}; cache grava só candidatos mínimos; base URL com default do contrato; mantém JWT/RLS/TTL/erros sanitizados/falha_nao_bloqueia); scripts/test_p2_s02_t02.mjs (matriz 18/18: E.164, DDD+número, sem 9º, inexistente, 2 e 4 candidatos, inativo, etapa b mesmo DDD/outro DDD, máscaras, 429, carga 200 sem 429 propagado); scripts/test_p2_s02_t01.mjs corrigido para o caminho do repo
- pendencias_da_task: token no Vault via /admin + EXPERT_API_BASE_URL secret → testes de conexão real (T01) e busca real (T02); capturas por papel T03 (3.b/3.c)
- pendencias_do_dono (arrastadas): toggles Auth (signup off no TOPO de Providers + TOTP); decisão histórico Git
- fase_2: 4/28 concluídas + T01/T02 implementadas (aguardam token + aceites)
- proxima_acao: P2-S02-T03 (tela Identificar paciente + cartão de saúde no /admin) — pode ser implementada agora e testada com dado real quando o token chegar
- atualizado_em: 2026-10-19T18:40:00-03:00
