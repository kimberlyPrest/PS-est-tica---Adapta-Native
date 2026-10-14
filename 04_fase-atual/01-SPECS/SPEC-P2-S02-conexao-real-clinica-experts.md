# P2-S02 — Conexão real com o Clínica Experts e tela de identificação de paciente

**Fase:** 2  
**Status:** liberada para implementação (em paralelo ao fechamento da fase 1)  
**Dono:** técnico de integração; aceite de reception/sales  
**Origem no escopo:** §12, AG-02, RT-05, RT-15, RT-23; pendência operacional da fase 1 (função responde 503 `api_nao_configurada`); verificação ao vivo de 13/10/2026  
**Degrau da solução:** reuso — cliente HTTP, cache e função `search-expert-patient` da P1-S05 já existem; ajusta o contrato ao comportamento real da API e cria a tela.

## Contexto e decisões fechadas

- Base confirmada: `https://api.clinicaexperts.com.br/api/v1` (o host `app.` responde igual e divide o mesmo limite). Cabeçalhos `x-ratelimit-limit: 120` e `x-ratelimit-remaining` vêm em toda resposta.
- A borda (Cloudflare) recusa com 403 código 1010 clientes cuja assinatura não reconhece, antes de validar o token. O cliente HTTP precisa enviar `User-Agent` próprio e isso precisa ser testado a partir da Edge Function.
- O telefone é guardado como `+55DDDNÚMERO` em 97% dos 2.181 pacientes. O filtro `phone` casa por trecho de dígitos: E.164 completo, só DDD+número e até os últimos 8 dígitos funcionam; formato com máscara e número sem o 9º dígito não casam.
- 60 telefones pertencem a 2–4 pacientes (130 cadastros); 32 pacientes não têm telefone; 29 têm comprimento fora do padrão.
- 72% da base está inativa (1.576 de 2.181). `origin` é nulo em 2.180 cadastros, `tags` é texto, `documents` vem como objeto ou como lista vazia, e `updated_at` é igual a `created_at` em todos os cadastros.
- Quatro formatos de erro: `{error:{code,title,fields}}` (404 `API0011`, 422 `API0422`), `{error:"..."}` (403 de módulo desabilitado), `{success:false,message}` (429) e o corpo da borda (`cloudflare_error`).
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

A atendente digita um telefone na tela "Identificar paciente" e vê, com dado real, "paciente", "novo lead" ou "ambíguo" (candidatos lado a lado); o administrador vê a conexão como saudável.

## Limites e dependências

- **Inclui:** base URL e token real no Vault; `User-Agent` próprio; classificação de erro por formato; busca em duas etapas; regra de ambiguidade; limitador guiado pelo cabeçalho; tela de busca; cartão de saúde da conexão no `/admin`.
- **Fora de escopo:** criar ou editar paciente no Clínica Experts (P4-S02); cópia integral da base de pacientes; busca por CPF.
- **Entradas e pré-condições:** token de leitura do cliente gravado pelo `/admin` (nunca em arquivo); três telefones de conferência indicados pela clínica (um único, um compartilhado, um inexistente).
- **Saídas/artefatos:** função `search-expert-patient` v2, tela de busca, cartão de saúde, contrato de erros documentado no mapa de dados.
- **Dependências e responsáveis:** P2-S01 (repositório com as funções). Felipe grava o token; reception/sales validam.
- **Risco e plano B:** a borda voltar a bloquear a assinatura da função — o erro é classificado como `bloqueio_de_borda` e alerta o administrador; plano B é a busca manual no Clínica Experts.
- **Rollback ou reversão:** desligar a flag da busca por clínica; a função volta a responder indisponível sem afetar conversas.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `GET /patients?phone=` | Clínica Experts | filtro por trecho de dígitos; resposta `{data[],meta}`; `per_page` máx. 1000 |
| `GET /patients/{uuid}` | Clínica Experts | mesmos campos da lista, dentro de `data` |
| `expert_patients_cache`, `external_patient_links` | Supabase | só nome, telefone, nascimento, situação e UUID; TTL e invalidação da P1-S05 |
| `integration_calls` | Supabase | operação, status, duração, tentativa e código de erro — sem corpo |

## Contrato técnico detalhado

Segue o `00-CONTRATO-COMUM-FASE-2.md` e o mapa de dados do Clínica Experts (`mapa-de-dados-clinica-experts.md`).

### Configuração

| Item | Onde fica | Valor |
|---|---|---|
| `EXPERT_API_BASE_URL` | secret da Edge Function | `https://api.clinicaexperts.com.br/api/v1` |
| Token | Vault, via `/admin/conexoes` (P1-S04) | gravado pelo owner; nunca em arquivo, `.env`, chat ou log |
| `integration_connections` | linha `provider='clinica_experts'`, `clinic_id` nulo (conexão da organização), `connection_key='principal'` | um token cobre as duas unidades |
| `User-Agent` | constante em `_shared/providers/clinica-experts.ts` | `PSEstetica-CRM/1.0 (+supabase-edge)` |

### Cliente HTTP (`_shared/providers/clinica-experts.ts`)

| Função | Assinatura | Observação |
|---|---|---|
| `expertGet(path, query, ctx)` | `Promise<{status, data, meta, headers}>` | só `GET`; acrescenta `Authorization`, `Accept: application/json`, `User-Agent`, `x-correlation-id` |
| `classifyExpertError(status, body)` | devolve `code` do contrato comum | regras abaixo |
| `rateBudget.take(connectionId)` | aguarda vaga | 90 por minuto; lê `x-ratelimit-remaining`; abaixo de 10, espera a virada do minuto |

Classificação de erro:

| Resposta | `code` interno | HTTP devolvido à tela | Nova tentativa |
|---|---|---|---|
| 401 | `credencial_invalida` | 502 `falha_externa` | não |
| 403 com `cloudflare_error: true` | `bloqueio_de_borda` | 502 `falha_externa` | não; alerta ao administrador |
| 403 com `{"error":"Feature ..."}` | `modulo_desabilitado` | 503 `indisponivel` | não |
| 404 com `API0011` | `paciente_nao_encontrado` | 404 | não |
| 422 com `API0422` | `entrada_recusada` (repassa `fields`) | 400 | não |
| 429 | `limite_externo` | 503 após esgotar | sim, 2× |
| 5xx / tempo esgotado | `falha_transitoria` / `tempo_esgotado` | 502 / 504 | sim, 2× |

Leitor de paciente (descarta tudo que não está na lista):

```ts
type ExpertPatientMin = {
  expert_patient_uuid: string; name: string; phone_e164: string | null;
  birth_date: string | null;  // YYYY-MM-DD, nunca exibido inteiro
  active: boolean; source_created_at: string;
}
```

`documents`, `address`, `email`, `annotation`, `occupation`, `marital_status` e `contacts` são descartados antes de qualquer gravação ou log.

### Busca em duas etapas

1. `phone = normalize_e164(entrada)`; inválido → 400.
2. Cache válido em `expert_patients_cache` (`clinic_id`, `phone_e164`, `expires_at > now()`, `invalidated = false`) → devolve.
3. Etapa (a): `GET /patients?phone=<E.164 sem +>&per_page=10`.
4. Se zero e o número tiver 9º dígito: etapa (b) `GET /patients?phone=<últimos 8 dígitos>&per_page=50`, filtrando localmente pelo mesmo DDD.
5. Classificação: (a) com 1 → `um`; (a) com 2+ → `multiplos`; (b) com 1+ → `provavel`; nada → `zero`.
6. Grava cache (TTL 1 h) com `result_class` e a lista mínima de candidatos.

### Função `search-expert-patient` (v2)

`POST /functions/v1/search-expert-patient` — JWT obrigatório.

Entrada: `{"clinic_id": "uuid", "phone": "texto", "force_refresh": false}`

Saída:

```json
{"data": {
  "result_class": "um | multiplos | provavel | zero",
  "phone_e164": "+5581900000001",
  "candidates": [{"expert_patient_uuid": "uuid", "name": "texto", "birth_masked": "**/**/1990", "active": true}],
  "linked_patient_uuid": "uuid ou null",
  "cache_hit": true
}, "correlation_id": "uuid"}
```

Permissão: `has_clinic_role(clinic_id, '{owner,clinic_admin,manager,sales,reception,post_sales}')`.

### Vínculo confirmado

Emenda ao RPC `link_expert_patient` da P1-S05: passa a aceitar `sales`, `reception` e `post_sales` da clínica para **criar** vínculo; **desfazer** vínculo continua restrito a `owner` e `clinic_admin`. `match_method` aceita `manual` e `manual_provavel` (etapa b).

### Telas

**`/pacientes/identificar`**

| Elemento | Comportamento |
|---|---|
| Campo telefone | aceita qualquer formato; mostra o E.164 normalizado antes de buscar |
| Botão Buscar | chama a função; desabilitado durante a busca |
| Resultado `um` | cartão com nome, nascimento mascarado, selo Ativo/Inativo, botão "Confirmar vínculo" |
| Resultado `multiplos` | lista de cartões lado a lado, aviso "Mais de um cadastro usa este telefone. Confirme com o cliente.", nenhum pré-selecionado |
| Resultado `provavel` | cartão com selo "Provável — confirmar" e motivo "número cadastrado sem o 9º dígito" |
| Resultado `zero` | "Nenhum paciente com este telefone — tratar como novo contato" |
| Erros | mensagem por `code`, com `correlation_id` copiável e link "Buscar direto no Clínica Experts" |
| Atualizar | "Buscar de novo" chama com `force_refresh=true` |

**`/admin/conexoes`** — cartão "Clínica Experts": situação (saudável, com erro, não configurada), último teste, limite restante no último teste, botão "Testar conexão" (leitura `GET /rooms?per_page=1`), botão "Trocar token". Nunca mostra o token.

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P2-S02-01 | Toda chamada envia `User-Agent` identificável (`PSEstetica-CRM/<versão>`). 403 com `cloudflare_error` é `bloqueio_de_borda`: não é credencial inválida e não é repetido. |
| RN-P2-S02-02 | Busca em duas etapas: (a) E.164 completo; (b) se zero, últimos 8 dígitos com filtro local por DDD, para cobrir cadastro sem o 9º dígito. Resultado da etapa (b) é "provável" e sempre pede confirmação humana. |
| RN-P2-S02-03 | Dois ou mais pacientes com o mesmo telefone são "ambíguo": a tela lista nome, nascimento mascarado e situação; o sistema não escolhe. |
| RN-P2-S02-04 | Paciente inativo é paciente: classifica como existente, com selo "inativo". |
| RN-P2-S02-05 | Limite interno de 90 chamadas por minuto por conexão; com `x-ratelimit-remaining` abaixo de 10 a fila espera a virada do minuto. |
| RN-P2-S02-06 | O leitor aceita `documents` como objeto ou lista e datas com `-03:00` ou `Z`; CPF, RG e endereço nunca são gravados nem registrados em log. |

## Fluxo e regras

1. Administrador grava base URL e token pelo `/admin` e roda o teste de conexão.
2. Atendente informa o telefone; o servidor normaliza para E.164 e consulta o cache.
3. Sem cache válido, executa a etapa (a) e, se preciso, a etapa (b).
4. Classifica zero, um, provável ou ambíguo e grava só os campos mínimos no cache.
5. A tela mostra o resultado; a confirmação humana grava o vínculo.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | telefone com um único cadastro | "paciente" com selo ativo/inativo | vínculo só após confirmação humana |
| Limite | telefone compartilhado, sem o 9º dígito ou sem cadastro | "ambíguo" com candidatos, "provável — confirmar" ou "novo lead" | atendente escolhe ou segue como lead |
| Falha | 401, 403 de borda, 422, 429 ou timeout | mensagem operacional distinta por causa, com correlation ID; sem falso "novo lead" | busca manual no Clínica Experts; alerta ao administrador |

## Checklist de execução

- [ ] Token gravado pelo `/admin` e ausente de qualquer arquivo.
- [ ] Três telefones de conferência recebidos da clínica.
- [ ] Matriz de formatos de telefone executada.
- [ ] Varredura de dado sensível em rede, cache e logs anexada.
- [ ] Reception/sales validaram a tela.

## Critérios de aceite

- [ ] **CA-P2-S02-01:** Com token real no Vault e base URL configurada, o teste de conexão retorna saudável e a função deixa de responder 503.
- [ ] **CA-P2-S02-02:** Os três telefones de conferência retornam, na tela, "paciente", "ambíguo" (com todos os candidatos) e "novo lead".
- [ ] **CA-P2-S02-03:** Um número cadastrado sem o 9º dígito é encontrado pela segunda etapa e marcado "provável — confirmar".
- [ ] **CA-P2-S02-04:** Uma chamada recusada pela borda gera erro `bloqueio_de_borda` sanitizado e sem nova tentativa; 401, 422, 429 e timeout produzem mensagens distintas.
- [ ] **CA-P2-S02-05:** Em 200 buscas seguidas de teste, o provedor não devolve nenhum 429.
- [ ] **CA-P2-S02-06:** Inspeção de rede, cache e logs não encontra CPF, RG, endereço nem token.
- [ ] **CA-P2-S02-07:** Usuário de outra clínica ou de outra organização recebe 403 e não lê o cache.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | busca real ainda indisponível | chamar a função com token real e os três telefones | 503 ou classificação errada: CA-P2-S02-01 e CA-P2-S02-02 falham | saída versionada do runner ou roteiro, anexada à task |
| GREEN | conexão ativa e busca em duas etapas | repetir a matriz de formatos (E.164, DDD+número, sem o 9º, com máscara) | CA-P2-S02-01 a CA-P2-S02-03 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | erros, limite e privacidade | API simulada para 401/403-borda/422/429/timeout; 200 buscas; varredura de dado sensível | CA-P2-S02-04 a CA-P2-S02-07 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** API simulada com os quatro formatos de erro; três telefones reais indicados pela clínica só no ambiente autorizado; nenhum dado real em commit ou evidência.  
**Caminhos de erro obrigatórios:** 401, 403 de borda, 403 de módulo, 404, 422, 429, timeout, telefone inválido, usuário sem vínculo.  
**Evidência exigida:** relatório do runner, capturas da tela nos três estados e varredura de dado sensível.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P2-S02-T01 | Configurar base URL, token no Vault e `User-Agent`; classificar erros pelos quatro formatos. | técnico de integração | CA-P2-S02-01, CA-P2-S02-04 | RED de conexão; simulação dos erros | teste de conexão saudável e matriz de erros | P2-S01-T01; token entregue pelo cliente pelo `/admin` | 16/10/2026 | ☐ Liberada |
| P2-S02-T02 | Implementar busca em duas etapas, regra de ambiguidade e limitador guiado pelo cabeçalho. | técnico de integração | CA-P2-S02-02, CA-P2-S02-03, CA-P2-S02-05 | matriz de formatos de telefone; 200 buscas | relatório do runner | T01 concluída | 19/10/2026 | ☐ Liberada |
| P2-S02-T03 | Construir a tela "Identificar paciente" e o cartão de saúde da conexão no `/admin`. | técnico de frontend | CA-P2-S02-02, CA-P2-S02-07 | cenário principal e negativa de outra clínica e de outra organização | capturas dos estados | T02 concluída | 19/10/2026 | ☐ Liberada |
| P2-S02-T04 | Rodar a matriz com os telefones indicados pela clínica e a varredura de dado sensível. | QA + reception | CA-P2-S02-02, CA-P2-S02-06, CA-P2-S02-07 | REGRESSÃO completa em ambiente autorizado | relatório e aceite da recepção | T03 concluída; telefones de conferência recebidos | 20/10/2026 | ☐ Liberada |

## Roteiro das tasks

### P2-S02-T01 — Base URL, token, User-Agent e erros
1. Owner grava o token pelo `/admin/conexoes` (não colar em chat nem arquivo). Apagar o `.env` com token da pasta do Drive e trocar o token no painel do Clínica Experts se ele tiver circulado.
2. Configurar `EXPERT_API_BASE_URL` nas secrets das funções.
3. Acrescentar `User-Agent` e a classificação de erros no cliente HTTP; testes `deno test` com respostas simuladas dos quatro formatos de erro e do corpo da Cloudflare.
4. Rodar o teste de conexão real a partir da função publicada (não do computador) e anexar o diagnóstico sanitizado.
**Pronto quando:** teste de conexão saudável a partir da Edge Function e matriz de erros verde.

### P2-S02-T02 — Busca em duas etapas, ambiguidade e limitador
1. Implementar o leitor mínimo e a busca em duas etapas.
2. Implementar o limitador guiado por `x-ratelimit-remaining`.
3. Testes: E.164, só DDD+número, sem o 9º dígito, com máscara, 2 e 4 candidatos, zero, paciente inativo.
4. Teste de carga: 200 buscas sintéticas contra a API simulada com limite de 120/min — nenhuma 429 propagada.
**Pronto quando:** runner verde com os casos acima.

### P2-S02-T03 — Tela de busca e cartão de saúde
1. Criar `/pacientes/identificar` com os quatro resultados e os estados de erro.
2. Criar o cartão Clínica Experts em `/admin/conexoes`.
3. Aplicar a emenda do `link_expert_patient` e o botão "Confirmar vínculo".
4. Teste de tela por resultado e teste negativo: usuário de outra clínica recebe 403.
**Pronto quando:** capturas dos quatro estados e teste negativo anexados.

### P2-S02-T04 — Conferência com números reais
1. Pedir à clínica três telefones de conferência (um único, um compartilhado, um sem cadastro) e um número antigo sem o 9º dígito, se houver.
2. Executar a busca na tela com a recepção.
3. Inspecionar rede, cache e logs: nenhum CPF, RG, endereço ou token.
4. Registrar o aceite da recepção.
**Pronto quando:** roteiro humano "teste ok" e varredura sem ocorrências.

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| — | — | Nenhuma | SPEC inicial |
