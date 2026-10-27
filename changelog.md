# Changelog

## 2026-10-27 (2) — P2-S07-T03: ACEITA (+ correção do agent_key na tela)

- Aceite do owner: "teste ok" (13:09). P2-S07-T03 fechada — fase 2 em 18/28 (64%).
- Correção: o set do prompt da T01 usa `prompt_sets.agent_key = 'AG-01'` (não `AG-14`, que é o código da SPEC). A tela consultava a chave errada e abria sem selo de origem e sem texto.
- Fix (Skip v0.0.59): constante `AGENTE_COPILOTO='AG-01'`; editor preenchido com o texto em uso; histórico com coluna Origem; aviso quando nenhum prompt publicado existe.
- Migration `p2_s07_t03b_list_versions_origem`: `admin_list_prompt_versions` devolve `origem` (propria/organizacao) por linha.
- Ciclo provado no banco real (PS Recife): publicar sem sandbox → 42501 `sandbox_reprovado`; sandbox 10/10; publicar v1 → efetivo `propria`; Caruaru segue `organizacao`; fixture removida.
- Lição: conferir `prompt_sets.agent_key` no banco antes de fixar a chave do agente na tela — o código da SPEC (AG-14) não é a chave usada no seed (AG-01).

## 2026-10-27 (1) — P2-S07-T03: console de prompts com sandbox, publicação e volta

- Migration `p2_s07_t03_console_prompts` aplicada no Supabase real: 7 RPCs (rascunho, sandbox 10 casos, publicação com trava de sandbox, volta de versão, histórico, efetivo com origem, stats de uso) + `_guardiao_sandbox` (espelho SQL do guardião da Edge). Runner PGlite 25/25.
- Telas (Skip v0.0.58): aba "Instruções do copiloto" em /admin/agentes (editor + sandbox + publicar + voltar + herança + histórico) e indicador de uso do copiloto em /filas (30 dias).
- Pendência: aceite do Felipe → T04 fecha a fase 2.

## 2026-10-26 (5) — P2-S04-T03: consumidor v10 com _shared reais (correção do deploy v9)

- O deploy v9 do process-inbound-event saiu com STUB do expert-search (identificação voltaria 'indisponivel' mesmo com token válido). Reimplantado como v10 com expert_search.ts + clinica-experts-v2.ts REAIS no bundle.
- Fumaça v10 aprovada: mensagem sintética → conversa com selo REAL novo_lead (não stub). Fixture limpa.
- probe-payload (Edge de diagnóstico) permanece publicada — deletar junto com probe-egress-experts no encerramento do diagnóstico.
