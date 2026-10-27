# Changelog

## 2026-10-27 (1) — P2-S07-T03: console de prompts com sandbox, publicação e volta

- Migration `p2_s07_t03_console_prompts` aplicada no Supabase real: 7 RPCs (rascunho, sandbox 10 casos, publicação com trava de sandbox, volta de versão, histórico, efetivo com origem, stats de uso) + `_guardiao_sandbox` (espelho SQL do guardião da Edge). Runner PGlite 25/25.
- Telas (Skip v0.0.58): aba "Instruções do copiloto" em /admin/agentes (editor + sandbox + publicar + voltar + herança + histórico) e indicador de uso do copiloto em /filas (30 dias).
- Pendência: aceite do Felipe → T04 fecha a fase 2.

## 2026-10-26 (5) — P2-S04-T03: consumidor v10 com _shared reais (correção do deploy v9)

- O deploy v9 do process-inbound-event saiu com STUB do expert-search (identificação voltaria 'indisponivel' mesmo com token válido). Reimplantado como v10 com expert-search.ts + clinica-experts-v2.ts REAIS no bundle.
- Fumaça v10 aprovada: mensagem sintética → conversa com selo REAL novo_lead (não stub). Fixture limpa.
- probe-payload (Edge de diagnóstico) permanece publicada — deletar junto com probe-egress-experts no encerramento do diagnóstico.