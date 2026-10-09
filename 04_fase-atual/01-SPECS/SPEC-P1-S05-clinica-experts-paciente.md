# P1-S05 — Cliente Clínica Experts e busca/identificação de paciente

**Fase:** 1
**Status:** liberada para implementação
**Dono:** sales, reception, post_sales e serviço Edge Function
**Origem no escopo:** 9/AG-02; 10; 11/search-expert-patient; 12; 14; 16; 18/Fase 1
**Degrau da solução:** construção mínima sobre arquitetura Supabase e conectores já definidos; esta SPEC entrega somente a capacidade indicada no título.

## Contexto e decisões fechadas

- **Estado atual:** planejamento consolidado; esta capacidade ainda não está implementada.
- **Estado desejado:** Buscar paciente por telefone normalizado usando apenas chamadas server-side e classificar o contato como paciente, novo lead ou ambíguo.
- **Decisões fechadas:** Normalizar E.164; nome sozinho nunca confirma identidade; zero=novo lead; um=potencial paciente; múltiplos=ambíguo e validação humana; cache tem expiry e invalidation; retry limitado/backoff para transitórios.
- **Aprovações:** confirmadas pela responsável em 29/09/2026 e registradas em `03-Projeto/decisoes-do-projeto.md`; sem gate de aprovação pendente.

## Resultado observável

Buscar paciente por telefone normalizado usando apenas chamadas server-side e classificar o contato como paciente, novo lead ou ambíguo.

## Limites, atores e dados

- **Inclui:** Buscar paciente por telefone normalizado usando apenas chamadas server-side e classificar o contato como paciente, novo lead ou ambíguo.
- **Fora de escopo:** demais capacidades do projeto fora do título desta SPEC; itens explicitamente fora da fase conforme seção 18 do escopo.
- **Atores e permissões:** sales, reception, post_sales e serviço Edge Function; aplicar RLS/membership e privilégio mínimo.
- **Dados:** `external_patient_links`, `expert_patients_cache`, `contacts`; campos mínimos, UUID externo, `match_method`, confiança, validade do cache.
- **Dependências:** capacidades prévias listadas no índice da fase e ambientes/acessos autorizados do cliente. Dependência técnica indica ordem de execução, não aprovação pendente.
- **Superfícies afetadas:** Supabase/Postgres/RLS/Edge Functions/Queues/Storage e console web somente conforme a integração descrita nesta SPEC; não presumir arquivos/repositório de implementação inexistentes.
- **Segurança/privacidade:** segredos exclusivamente server-side; correlation ID; logs sanitizados; isolamento por `organization_id`/`clinic_id`; dados sintéticos em testes.
- **Risco e rollback:** desligar feature flag/canal/loop afetado; manter estado local consistente e caminho manual; migration compatível e replay idempotente.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato | Autorização | Idempotência/resiliência |
|---|---|---|---|---|
| GET `/patients?phone=<E.164>` e GET `/patients/{uuid}`; Bearer server-side; API até 120 req/min, `page`/`per_page` máx.1000, respostas 401/404/422/429; endpoint via função `search-expert-patient`. | `external_patient_links`, `expert_patients_cache`, `contacts`; campos mínimos, UUID externo, `match_method`, confiança, validade do cache. | sales, reception, post_sales e serviço Edge Function | correlação, retry limitado/backoff, dead-letter e tratamento de status definidos no escopo |

## Regras de negócio

| ID | Regra | Consequência |
|---|---|---|
| RN-P1-S05-01 | Normalizar E.164; nome sozinho nunca confirma identidade; zero=novo lead; um=potencial paciente; múltiplos=ambíguo e validação humana; cache tem expiry e invalidation; retry limitado/backoff para transitórios. | Validar no servidor e auditar decisão. |

## Fluxo e cenários

1. Validar sessão, clínica/membership e configuração efetiva/versionada.
2. Validar entrada/estado e aplicar a regra de domínio antes de qualquer chamada externa.
3. Processar em transação/fila conforme contrato; gravar correlation ID, versão, resultado e erro sanitizado.
4. Apresentar resultado ao ator e manter caminho seguro de recuperação/rollback.

| Cenário | Entrada/condição | Resultado esperado | Evidência |
|---|---|---|---|
| Principal | configuração aprovada e dados válidos | Busca zero/um/múltiplos produz estados definidos sem escolher múltiplos automaticamente. | Fixtures 0/1/2 resultados; API simulada 401/422/429/timeout; inspeção de log/browser; verificação expiração cache. |
| Limite | dado ausente, duplicado, sem permissão ou fora de janela | negar/omitir somente ação afetada; nenhuma exposição ou duplicação | log sanitizado e estado final |
| Falha | timeout, 401/422/429, fila ou serviço indisponível quando aplicável | sem falso sucesso; estado recuperável e fallback humano | correlation ID + registro de retry/dead-letter |

## Instruções de implementação

1. Ler o escopo nas seções de origem acima, seção 7 (dados), seção 14 (regras) e seções 15–16 (segurança/resiliência).
2. Alterar somente as superfícies necessárias a esta capacidade e manter compatibilidade com SPECs dependentes.
3. Não modificar fonte de verdade, política de autonomia ou configuração de outra clínica.
4. Executar tarefas na ordem indicada; cada task deve deixar estado válido e evidência própria.
5. Parar operação externa se credencial/ambiente autorizado estiver indisponível; tratar como incidente técnico, não como aprovação pendente.
6. Estado válido ao concluir: capacidade demonstrável, telemetria sanitizada, rollback/fallback conhecido e critérios abaixo aprovados.

## Critérios de aceite
- [ ] **CA-P1-S05-01:** Busca zero/um/múltiplos produz estados definidos sem escolher múltiplos automaticamente.
- [ ] **CA-P1-S05-02:** 401/422/429/timeout têm erro operacional sanitizado e correlação; falha não bloqueia conversa local.
- [ ] **CA-P1-S05-03:** Token nunca chega ao cliente; cache mínimo expira e pode ser invalidado.

## TDD da SPEC

| Etapa | Prova | Ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | ausência da capacidade/contrato | executar Fixtures 0/1/2 resultados; API simulada 401/422/429/timeout; inspeção de log/browser; verificação expiração cache. antes da implementação | pelo menos CA-P1-S05-01 falha por motivo esperado | saída de teste/cenário versionada |
| GREEN | fluxo principal | implementar tarefas vinculadas e executar testes unitários + integração/UI pertinentes | todos os CA passam no caminho válido | relatório CI e captura/log sanitizado |
| REFACTOR/REGRESSÃO | erro, permissão, duplicidade, rollback e integração | repetir matriz definida em Cenários | nenhum vazamento, duplicação ou regressão; CA mantêm-se válidos | relatório de regressão + aceite do dono |

**Dados/fixtures:** massa sintética multi-clínica e respostas simuladas de API/provedor; nunca incluir token/dado real em commit ou evidência.
**Caminhos de erro obrigatórios:** duplicidade, vazio/inválido, falta de permissão, timeout/limite de taxa, indisponibilidade e rollback conforme integração.
**Evidência exigida:** execução automatizada versionada, registros sanitizados e demonstração pela função operacional indicada.

## Operação e handoff

- **Demonstração:** executar o cenário principal acima como um ator autorizado e uma tentativa negativa de outra clínica.
- **Monitoramento:** health, sucesso/falha, latência, retry/dead-letter e métricas de domínio conforme tabela/feature.
- **Operação:** dono listado nesta SPEC; runbook/rollback da fase.
- **Pendência:** nenhuma pendência de aprovação; dependências de sequência estão indicadas como dependências técnicas.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Status |
|---|---|---|---|---|---|---|
| P1-S05-T01 | Implementar cliente server-side HTTP com timeout, rate limiter e telemetria sanitizada. | técnico de implementação | Critério CA correspondente atendido no recorte desta tarefa | Teste/fluxo desta task conforme seção TDD | relatório/captura sanitizada vinculada ao run | ☑ Concluída 09/10 — aceite "teste ok" (roteiro 11/11; runner 21/21 revalidado) |
| P1-S05-T02 | Implementar busca, normalização, deduplicação, vínculo humano e cache mínimo com TTL. | técnico de integração | Critério CA correspondente atendido no recorte desta tarefa | Teste/fluxo desta task conforme seção TDD | relatório/captura sanitizada vinculada ao run | ☑ Implementada 09/10 — runner 22/22; migration + Edge Function aplicadas; aguarda teste humano |
| P1-S05-T03 | Construir fluxo de busca demonstrável e executar matriz zero/um/múltiplos/falhas. | QA + dono operacional | Critério CA correspondente atendido no recorte desta tarefa | Teste/fluxo desta task conforme seção TDD | relatório/captura sanitizada vinculada ao run | ☐ Liberada |

## Emendas

| Data | Origem | Alteração | Motivo |
|---|---|---|---|
| — | — | Nenhuma | SPEC inicial |