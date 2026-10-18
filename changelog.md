# Changelog — Adapta Cliente

## 2026-10-18 — TELA DE SEGUNDO FATOR implementada (v0.0.11, extra fora da SPEC)
- Contexto: no teste humano da T03, o owner era bloqueado em /admin com a tela estática "Segundo fator necessário" — não havia como ATIVAR o fator dentro do app (só pelo painel Supabase). Tela implementada a pedido do Felipe.
- Entrega (Skip 62134, v0.0.11 812ac41, QA verde: setup/static/build/integrations):
  - src/pages/SegundoFator.tsx: fluxo TOTP completo via supabase-js v2 — enroll (QR + chave manual + friendly_name), challenge, verify; unenroll automático de fator pendente anterior (não acumula); erros amigáveis (código inválido, rate limit, fator não encontrado); retorno automático ao destino original (?next=, default /admin).
  - guards.tsx: owner/clinic_admin sem AAL2 agora são REDIRECIONADOS a /segundo-fator?next=/admin (antes: tela estática).
  - src/lib/auth-errors.ts: mensagens amigáveis extraídas de use-auth (sem duplicar).
  - App.tsx: rota /segundo-fator. vitest.config.ts: alias @ (o app usa @/lib/...). package.json: @testing-library/user-event.
  - Testes: 12/12 (7 da guarda — incluindo owner sem AAL2 → /segundo-fator — e 5 da tela MFA: enroll, QR+chave, sucesso, código inválido, challenge direto).
- Lições de teste: mockar pelo MESMO caminho que o componente importa (@/lib/supabase/client); a chain mockada do from() precisa ser THENABLE (await em qualquer ponto resolve) — o erro real era "...eq(...).limit is not a function"; não usar vi.clearAllMocks() quando o mock é configurado no beforeEach.
- Como usar: /admin → redireciona a /segundo-fator → Gerar código QR → escanear no autenticador → código de 6 dígitos → verificado → Continuar → /admin abre.
- Próxima: aceite humano; depois P2-S02-T01 (token Clínica Experts no Vault).

## 2026-10-18 — P2-S01-T03 SINCRONIZADA no Skip (v0.0.8 + v0.0.9, QA verde)
- Sincronização concluída após reconexão do conector Skip: 7 arquivos da T03 gravados no projeto CRM Estética (62134) e QA verde (setup/static/build/integrations) na versão 0.0.8 (f299cf2); migration de convite 20261002185527 substituída pela cópia higienizada (e-mail pessoal removido) na versão 0.0.9 (b215a07), fechando a pendência da T02.
- Entrega da T03: types.ts do catálogo real (14 tabelas + 17 RPCs + Papel); guards.tsx (RequireAuth/RequireRole com AAL2/EmptyState/ErrorState); clinic-selector.tsx; app-shell.tsx; Inicio.tsx (/inicio, estado vazio); AdminProtegido.tsx (/admin owner/clinic_admin + AAL2); App.tsx (/signup removida; /dashboard→/inicio); Index.tsx sem link "Solicitar acesso" e sem a dica de credenciais exposta; Dashboard.tsx (números fixos) e SignUp.tsx removidos.
- Testes de tela 7/7 verdes (Vitest + Testing Library); 0 "as any" em chamada ao Supabase.
- Pendência restante: capturas por papel (humano). Próxima: P2-S01-T04 (suíte de testes + CI).

## 2026-10-18 — P2-S01-T04 implementada (v0.0.10)
- package.json npm test → vitest run (antes era echo "no tests" — por isso qa.test.ran=false no Skip); vitest.config.ts (jsdom/globals); Inicio.test.tsx (7 testes); scripts/scan-secrets.mjs (5 padrões, exit 1 em achado; provas: 0 na árvore, JWT teste → exit 1). Prova da suíte: exit 0 verde / exit 1 com teste falho. Skip v0.0.10 (4f8b442) QA verde (test.ran=false é limitação do runner da plataforma). SPEC P2-S01 COMPLETA (T01–T04). Próxima: P2-S02-T01 (conexão real Clínica Experts) — pré-condição: token entregue pelo /admin no Vault. Pendências do dono seguem: toggles Auth (signup off + TOTP) e decisão sobre histórico Git.

## 2026-10-14 — P2-S01-T02 CONCLUÍDA (primeira task da fase 2)
- Aceite humano: "teste ok" (Felipe, 2026-10-14 22:43, canal web) após conferência no Skip: 3 pastas em supabase/functions/, 19 migrations em supabase/migrations/, versão 0.0.7 com QA 5/5, seed sem senha/e-mail.
- Entrega: repositório do CRM (Skip 62134) passa a conter a base da fase 1 — 19 migrations com os timestamps EXATOS do histórico real (fonte: supabase_migrations.schema_migrations do projeto psestetica; SQL literal, não reconstruído) + Edge Functions search-expert-patient (importa _shared/), _shared/clinic_experts_client (módulo T01 aceito) e admin-invite-user (recuperada da produção v2). Seed 20260929135430 neutralizada; corretiva de rename ganhou guarda para instalação limpa.
- Pendências operacionais registradas (não bloqueiam): diff formal vazio e replay dos runners exigem Supabase CLI (fora do sandbox); decisão do owner sobre histórico Git (senha antiga no commit inicial, já trocada no banco).
- Artefato: artifacts/RELATORIO_P2_S01_T01_20261014.md. Quadro atualizado (commit 2c736e0).
- Próxima: P2-S01-T02 (hardening) mediante pedido do dono. Prazos da fase 2: S01 16/10 · S02 20/10 · S03 22/10 · S04 26/10 · S05 28/10 · S06 30/10 · S07 04/11.

## 2026-10-14 — FASE 2 LIBERADA (em paralelo ao fechamento da fase 1)
- Incluídas as SPECs P2-S01 a P2-S07 em `04_fase-atual/01-SPECS/`, com contrato técnico detalhado (tabelas coluna a coluna, regras de acesso, funções, filas, telas), TDD, critérios de aceite (53) e roteiro passo a passo das 28 tasks.
- Incluído `00-CONTRATO-COMUM-FASE-2.md`: convenções de banco, RLS, envelope de erro das funções, filas, interruptores, rotas de tela e provas.
- Incluído `03-Produto-e-Arquitetura/mapa-de-dados-clinica-experts.md` (API verificada ao vivo em 13/10/2026, somente leitura).
- `fase.md`, `jornada.md`, `escopo-da-fase.md`, índice, STATUS, estado atual, README, visão geral e manifesto atualizados.
- Nenhuma credencial incluída.

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
- Revalidação de fechamento: banco real (2 tabelas novas, 4 policies, 3 funções, normalize 8→9 dígitos ok, cache/links 0 linhas) + Edge Function ao vivo (owner autenticado → 503 api_nao_configurada com correlation_id a4419eb2, sem falso sucesso; anon → 401).
- Fase 1: 14/16 (87,5%). Próxima: P1-S05-T03 (fluxo demonstrável + matriz zero/um/múltiplos/falhas) — última da fase 1, mediante pedido.

## 2026-10-09 — P1-S05-T02 IMPLEMENTADA
- Migration p1_s05_t02_search_cache aplicada no Supabase (uhozizrpmmpemvegtqaq): função normalize_e164 (E.164 server-side; formatado BR/sem DDI/idempotente; 8 dígitos ganha 9º; inválido 22023); tabela external_patient_links (vínculo CONFIRMADO por humano — CHECK match_method IN ('manual'); dedup: UNIQUE (clinic_id, contact_id, expert_patient_uuid) + UNIQUE (clinic_id, expert_patient_uuid) com rebind sem duplicar; RLS leitura org / escrita writer); tabela expert_patients_cache (payload, result_class zero/um/multiplos/erro, expires_at TTL, invalidated, correlation_id; UNIQUE (clinic_id, phone_e164); RLS leitura org / escrita membro — dado derivado da busca); RPCs invalidate_expert_cache (normaliza telefone; idempotente) e link_expert_patient (só owner/clinic_admin; contato da mesma org; rebind sem duplicar); EXECUTE só authenticated.
- Edge Function search-expert-patient v1 deployada (verify_jwt): autentica JWT → normaliza via RPC → valida membro da org via RLS → consulta cache com TTL → chama API Clínica Experts pelo módulo T01 (timeout/rate limiter/retry; token lido do Vault via service role, NUNCA exposto) → classifica zero/um/múltiplos (múltiplos NUNCA escolhidos automaticamente) → grava cache TTL 1h. Erros sanitizados com correlation_id; falha não bloqueia conversa local (falha_nao_bloqueia).
- Verificação: runner scripts/test_s05_t02.js 22/22 (PGlite instalação limpa T01→T02; roles anon/authenticated; auth.uid via request.jwt.claims). Prova ao vivo: login owner OK; função autenticada → 503 api_nao_configurada + correlation_id (EXPERT_API_BASE_URL ainda não configurada — sem falso sucesso); sem JWT → 401.
- Correções no caminho: regex \d inválida no Postgres (usar [0-9]); DDI 55 com 13 dígitos; UUIDs de teste com 9 chars no 1º grupo; createClient exigia URL+key; import ESM no topo.
- Artefatos: artifacts/p1_s05_t02_search_cache.sql · artifacts/p1_s05_t02_edge_search_expert_patient.ts · artifacts/RELATORIO_P1_S05_T02_20261009.md
- Pendências: EXPERT_API_BASE_URL (env) + token real (via /admin→Vault) quando Felipe fornecer.
- Fase 1: 13/16 concluídas (81,25%); T02 aguarda teste humano. Próxima: P1-S05-T03 (fluxo demonstrável + matriz zero/um/múltiplos/falhas) — última da fase 1.