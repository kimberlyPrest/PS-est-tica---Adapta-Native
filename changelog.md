# Changelog — Adapta Cliente

## 2026-10-09 — P1-S05-T03 CONCLUÍDA · FASE 1 COMPLETA (16/16)
- Aceite humano: "teste ok" (Felipe, 2026-10-09, canal web) após roteiro roteiro-t03-matriz-v1-20261009.html (17 passos) validado 17/17 ✔ no navegador antes da entrega.
- Parte A (Supabase real, sessão do owner): fixtures sintéticas de cache criadas pelo roteiro (0901–0904) e REMOVIDAS ao final (0 restantes, confirmado na revalidação); busca "um" via cache (HTTP 200), "zero" → novo lead, "múltiplos" → 2 resultados devolvidos SEM escolher (CA-P1-S05-01); cache expirado ignorado (TTL); invalidação explícita → cache não mais usado; busca sem cache → 503 api_nao_configurada com correlation_id, sem falso sucesso (CA-P1-S05-02); negativa de outra clínica: vendedor PSC→PSR → 403, controle na própria → 503; sem sessão → 401.
- Parte B (módulo T01 real embutido vs API simulada): 401→credencial, 422→entrada, 429→recupera no 3º esforço respeitando retry-after, timeout sem travar; varredura final: 0 ocorrências do token (CA-P1-S05-03).
- Revalidação de fechamento com evidência fresca: banco real (2 tabelas, 4 policies, 3 funções, 0 fixtures) + Edge Function ao vivo (owner 503 sanitizado correlation_id 52b4bf41; anon 401).
- **FASE 1 COMPLETA: 16/16 tasks (100%)** — SPECs P1-S01 (tenancy) · P1-S02 (auth/RLS) · P1-S03 (admin/organização) · P1-S04 (segredos/Vault) · P1-S05 (busca Clínica Experts) todas concluídas com aceite humano.
- Artefato: artifacts/roteiro-t03-matriz-v1-20261009.html (gerador scripts/gerar_roteiro_t03.mjs + template).
- Pendências operacionais: EXPERT_API_BASE_URL + token real da API Clínica Experts (via /admin→Vault) quando Felipe fornecer; até lá a função responde 503 sanitizado.
- Próxima: planejamento da fase 2 com o Felipe.

## 2026-10-09 — P1-S05-T02 CONCLUÍDA
- Aceite humano: "teste ok" (Felipe, 2026-10-09, canal web) após roteiro roteiro-t02-busca-v1-20261009.html (8 passos contra o Supabase real com sessão do owner: login, normalização E.164, 22023, 503 api_nao_configurada com correlation_id, 400 entrada, 401 anon, invalidação idempotente, RLS anon 0) validado 8/8 ✔ no navegador antes da entrega.
- Revalidação de fechamento com evidência fresca: banco real (2 tabelas novas, 4 policies, 3 funções, normalize 8→9 dígitos ok, cache/links 0 linhas) + Edge Function ao vivo (owner autenticado → 503 api_nao_configurada com correlation_id a4419eb2, sem falso sucesso; anon → 401).
- Fase 1: 14/16 (87,5%). Próxima: P1-S05-T03 (fluxo demonstrável + matriz zero/um/múltiplos/falhas) — última da fase 1, mediante pedido.

## 2026-10-09 — P1-S05-T02 IMPLEMENTADA
- Migration p1_s05_t02_search_cache aplicada no Supabase (uhozizrpmmpemvegtqaq): função normalize_e164 (E.164 server-side; formatado BR/sem DDI/idempotente; 8 dígitos ganha 9º; inválido 22023); tabela external_patient_links (vínculo CONFIRMADO por humano — CHECK match_method IN ('manual'); dedup: UNIQUE (clinic_id, contact_id, expert_patient_uuid) + UNIQUE (clinic_id, expert_patient_uuid) com rebind sem duplicar; RLS leitura org / escrita writer); tabela expert_patients_cache (payload, result_class zero/um/multiplos/erro, expires_at TTL, invalidated, correlation_id; UNIQUE (clinic_id, phone_e164); RLS leitura org / escrita membro — dado derivado da busca); RPCs invalidate_expert_cache (normaliza telefone; idempotente) e link_expert_patient (só owner/clinic_admin; contato da mesma org; rebind sem duplicar); EXECUTE só authenticated.
- Edge Function search-expert-patient v1 deployada (verify_jwt): autentica JWT → normaliza via RPC → valida membro da org via RLS → consulta cache com TTL → chama API Clínica Experts pelo módulo T01 (timeout/rate limiter/retry; token lido do Vault via service role, NUNCA exposto) → classifica zero/um/múltiplos (múltiplos NUNCA escolhidos automaticamente) → grava cache TTL 1h. Erros sanitizados com correlation_id; falha não bloqueia conversa local (falha_nao_bloqueia).
- Verificação: runner scripts/test_s05_t02.js 22/22 (PGlite instalação limpa T01→T02; roles anon/authenticated; auth.uid via request.jwt.claims). Prova ao vivo: login owner OK; função autenticada → 503 api_nao_configurada + correlation_id (EXPERT_API_BASE_URL ainda não configurada — sem falso sucesso); sem JWT → 401.
- Correções no caminho: regex \d inválida no Postgres (usar [0-9]); DDI 55 com 13 dígitos; UUIDs de teste com 9 chars no 1º grupo; createClient exigia URL+key; import ESM no topo.
- Artefatos: artifacts/p1_s05_t02_search_cache.sql · artifacts/p1_s05_t02_edge_search_expert_patient.ts · artifacts/RELATORIO_P1_S05_T02_20261009.md
- Pendências: EXPERT_API_BASE_URL (env) + token real (via /admin→Vault) quando Felipe fornecer.
- Fase 1: 13/16 concluídas (81,25%); T02 aguarda teste humano. Próxima: P1-S05-T03 (fluxo demonstrável + matriz zero/um/múltiplos/falhas) — última da fase 1.
