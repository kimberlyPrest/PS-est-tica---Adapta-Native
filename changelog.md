# Changelog

## 2026-10-27 (3) — P2-S07-T04: matriz do copiloto + demonstração ponta a ponta (fase 2 fechada)

- Matriz de 13 cenários no banco real (PS Recife) com fixture sintética: ticket na fila → oferta pelo cron → aceite → sugestão do copiloto em **7,86 s** (limite 10 s) → edição e envio pela atendente → resolução com próxima ação.
- Guardião: pedido de preço/desconto → `blocked / conteudo_proibido`, resposta nula e envio recusado (`sugestao_bloqueada`).
- IA indisponível: erro tratado, painel na lista manual e **envio manual mantém o ticket operável**.
- Indicador de uso por clínica: 9 geradas, 1 editada (11,1%), 1 bloqueada.
- Fixtures removidas (0 contatos/conversas remanescentes); presença do owner voltou a offline.
- **SPEC P2-S07 COMPLETA (4/4). Fase 2 em 21/28 (75%)** — restam P2-S02 (token Experts) e P2-S03-T02/T04 (credenciais Meta), bloqueadas por credenciais do dono.
- Achados da fixture: `contacts.primary_phone_e164` é obrigatório para envio (contato sem telefone quebra `send_human_message` na FK de `outbound_requests`); `conversations.status` exige `new/triaging/resolved/spam/opted_out` quando não há owner/team; `resolve_ticket` só aceita `atendido/agendamento_encaminhado/sem_resposta_cliente/spam/transferido_outra_clinica`.

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

## 2026-10-26 (5) — P2-S04-T03: consumidor v10 com _shared reais (correção do deploy v9)

- O deploy v9 do process-inbound-event saiu com STUB do expert-search (identificação voltaria 'indisponivel' mesmo com token válido). Reimplantado como v10 com expert_search.ts + clinica-experts-v2.ts REAIS no bundle.
- Fumaça v10 aprovada: mensagem sintética → conversa com selo REAL novo_lead (não stub). Fixture limpa.
- probe-payload (Edge de diagnóstico) permanece publicada — deletar junto com probe-egress-experts no encerramento do diagnóstico.
