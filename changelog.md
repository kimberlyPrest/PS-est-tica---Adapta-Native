# Changelog — Adapta Cliente

## 2026-10-19 — P2-S02-T01 IMPLEMENTADA (v0.0.12; falta teste real com token)
- Cliente HTTP da conexão REAL: supabase/functions/_shared/providers/clinica-experts.ts — expertGet (User-Agent próprio PSEstetica-CRM/1.0 (+supabase-edge) exigido pela borda Cloudflare; x-correlation-id; Bearer só no header), classifyExpertError (4 formatos do contrato: {error:{code,title,fields}} / {error:"..."} / {success:false,message} / cloudflare_error → credencial_invalida, bloqueio_de_borda, modulo_desabilitado, paciente_nao_encontrado, entrada_recusada, limite_externo, falha_transitoria, tempo_esgotado), httpDeErro (mapa 404/400/503/504/502), rateBudget.take (90/min; x-ratelimit-remaining < 10 → espera virada), retry 2× transitórios, telemetria sanitizada (token NUNCA sai), lerPacienteMinimo (só uuid/name/phone/birth/active/created; descarta documents/address/email/annotation/occupation).
- Matriz 23/23 (scripts/test_p2_s02_t01.mjs): 9 classificação + 6 http-por-code + 3 rateBudget + 3 leitor mínimo + User-Agent + smoke expertGet. Skip v0.0.12 (447a9e0) QA verde.
- Lição de sandbox: runner com servidor HTTP real + strip-types prende o event-loop — matriz pura + smoke com guarda de 3s resolve; deno test oficial fica para a CI do Skip.
- Pendências para FECHAR a T01: EXPERT_API_BASE_URL (secret) + token no Vault via /admin → teste de conexão real a partir da função publicada com diagnóstico sanitizado. Próxima: P2-S02-T02 (busca em duas etapas + limitador).

## 2026-10-18 — TELA DE SEGUNDO FATOR implementada (v0.0.11, extra fora da SPEC)
- Contexto: no teste humano da T03, o owner era bloqueado em /admin com a tela estática "Segundo fator necessário" — não havia como ATIVAR o fator dentro do app (só pelo painel Supabase). Tela implementada a pedido do Felipe.
- Entrega (Skip 62134, v0.0.11 812ac41, QA verde): src/pages/SegundoFator.tsx (fluxo TOTP completo via supabase-js v2 — enroll QR + chave manual, challenge, verify; unenroll de fator pendente; erros amigáveis; retorno ?next=); guards.tsx com redirect automático (owner/clinic_admin sem AAL2 → /segundo-fator?next=/admin); src/lib/auth-errors.ts; rota /segundo-fator; vitest.config.ts alias @; @testing-library/user-event. Testes 12/12 (7 guarda + 5 MFA).
- Lições de teste: mockar pelo MESMO caminho que o componente importa (@/lib/...); chain mockada do from() precisa ser THENABLE; não usar vi.clearAllMocks() com mockResolvedValue no beforeEach.
- Como usar: /admin → redireciona → Gerar QR → escanear → código → Continuar → /admin abre.

## 2026-10-18 — P2-S01-T03 SINCRONIZADA (v0.0.8+v0.0.9) e T04 (v0.0.10) — SPEC P2-S01 COMPLETA
- T03: 7 arquivos gravados no Skip (types do catálogo real, guards AAL2, clinic-selector, app-shell, /inicio, AdminProtegido, App sem /signup) + Index.tsx limpo (sem link de cadastro/credenciais expostas) + Dashboard/SignUp removidos → v0.0.8 (f299cf2); migration de convite higienizada → v0.0.9 (b215a07). QA verde.
- T04: npm test → vitest run (antes echo "no tests"); vitest.config.ts; Inicio.test.tsx (7); scripts/scan-secrets.mjs (5 padrões; provas 0 na árvore / JWT teste → exit 1). Prova da suíte: exit 0 verde / exit 1 com teste falho. v0.0.10 (4f8b442) QA verde.
- Diagnóstico "Administração não aparece": cache do navegador do Felipe — provado por login no preview via browser (screenshot artifacts/c3079d66). Captura do bloqueio "Segundo fator necessário" = aceite do passo 3.a.

## 2026-10-14 — P2-S01-T01 e T02 CONCLUÍDAS · FASE 2 LIBERADA
- T01 (aceite "teste ok"): 19 migrations com timestamps exatos do histórico real + 3 Edge Functions; seed neutralizada; v0.0.7 QA 5/5.
- T02: hardening (handle_new_user sem papel; profiles.role deprecada/nullable; policy USING(true) eliminada; cadastro público bloqueado 42501; runner 18/18; varredura 0 segredos).
- Fase 2 liberada: 7 SPECs (P2-S01..S07) + contrato comum; prazos S01 16/10 · S02 20/10 · S03 22/10 · S04 26/10 · S05 28/10 · S06 30/10 · S07 04/11 — 28 tasks.

## 2026-10-09 — FASE 1 COMPLETA (16/16) · P1-S05 T02/T03
- P1-S05-T03 (aceite "teste ok", roteiro 17/17): matriz zero/um/múltiplos/falhas; fixtures removidas; token nunca exposto. FASE 1 COMPLETA: P1-S01 tenancy · P1-S02 auth/RLS · P1-S03 admin · P1-S04 segredos/Vault · P1-S05 busca.
- P1-S05-T02 (aceite "teste ok", roteiro 8/8): normalize_e164, external_patient_links (vínculo manual), expert_patients_cache (TTL), Edge Function search-expert-patient v1 (503 sanitizado sem token configurado; 401 anon).
- Pendências operacionais: EXPERT_API_BASE_URL + token real (suporte Clínica Experts; docs.nicochat.com confirma endpoint e Bearer).