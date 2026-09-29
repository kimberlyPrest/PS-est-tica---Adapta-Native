# P1-S02 — Autenticação, papéis e isolamento RLS

**Fase:** 1
**Status:** liberada para implementação
**Dono:** owner, clinic_admin, manager, sales, reception, post_sales, viewer
**Origem no escopo:** 5; 6.2; 6.3; 7.1; 14; 15; 18/Fase 1
**Degrau da solução:** construção mínima sobre arquitetura Supabase e conectores já definidos; esta SPEC entrega somente a capacidade indicada no título.

## Contexto e decisões fechadas

- **Estado atual:** planejamento consolidado; esta capacidade ainda não está implementada.
- **Estado desejado:** Permitir login e acesso por membership/role, com isolamento aplicado no banco em todas as tabelas expostas.
- **Decisões fechadas:** Revogação remove acesso sem apagar autoria; múltiplos papéis/memberships não ampliam escopo fora das clínicas autorizadas; views seguras por security_invoker/equivalente.
- **Aprovações:** confirmadas pela responsável em 29/09/2026 e registradas em `03-Projeto/decisoes-do-projeto.md`; sem gate de aprovação pendente.

## Resultado observável

Permitir login e acesso por membership/role, com isolamento aplicado no banco em todas as tabelas expostas.

## Limites, atores e dados

- **Inclui:** Permitir login e acesso por membership/role, com isolamento aplicado no banco em todas as tabelas expostas.
- **Fora de escopo:** demais capacidades do projeto fora do título desta SPEC; itens explicitamente fora da fase conforme seção 18 do escopo.
- **Atores e permissões:** owner, clinic_admin, manager, sales, reception, post_sales, viewer; aplicar RLS/membership e privilégio mínimo.
- **Dados:** `profiles`, `memberships`, papéis da seção 4; sessão Auth; políticas RLS para tabelas expostas.
- **Dependências:** capacidades prévias listadas no índice da fase e ambientes/acessos autorizados do cliente. Dependência técnica indica ordem de execução, não aprovação pendente.
- **Superfícies afetadas:** Supabase/Postgres/RLS/Edge Functions/Queues/Storage e console web somente conforme a integração descrita nesta SPEC; não presumir arquivos/repositório de implementação inexistentes.
- **Segurança/privacidade:** segredos exclusivamente server-side; correlation ID; logs sanitizados; isolamento por `organization_id`/`clinic_id`; dados sintéticos em testes.
- **Risco e rollback:** desligar feature flag/canal/loop afetado; manter estado local consistente e caminho manual; migration compatível e replay idempotente.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato | Autorização | Idempotência/resiliência |
|---|---|---|---|---|
| Supabase Auth e Postgres RLS; login e-mail/senha ou magic link; MFA para owner/admin quando disponível; `anon` sem dados operacionais; service_role apenas server-side. | `profiles`, `memberships`, papéis da seção 4; sessão Auth; políticas RLS para tabelas expostas. | owner, clinic_admin, manager, sales, reception, post_sales, viewer | correlação, retry limitado/backoff, dead-letter e tratamento de status definidos no escopo |

## Regras de negócio

| ID | Regra | Consequência |
|---|---|---|
| RN-P1-S02-01 | Revogação remove acesso sem apagar autoria; múltiplos papéis/memberships não ampliam escopo fora das clínicas autorizadas; views seguras por security_invoker/equivalente. | Validar no servidor e auditar decisão. |

## Fluxo e cenários

1. Validar sessão, clínica/membership e configuração efetiva/versionada.
2. Validar entrada/estado e aplicar a regra de domínio antes de qualquer chamada externa.
3. Processar em transação/fila conforme contrato; gravar correlation ID, versão, resultado e erro sanitizado.
4. Apresentar resultado ao ator e manter caminho seguro de recuperação/rollback.

| Cenário | Entrada/condição | Resultado esperado | Evidência |
|---|---|---|---|
| Principal | configuração aprovada e dados válidos | Usuário sem sessão não lê dados operacionais. | Suite RLS com usuários sintéticos A/B, anon e admin; leitura e escrita cross-clinic negadas. |
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
- [ ] **CA-P1-S02-01:** Usuário sem sessão não lê dados operacionais.
- [ ] **CA-P1-S02-02:** Membro da clínica A não lê nem altera clínica B via API direta.
- [ ] **CA-P1-S02-03:** Revogar membership invalida acesso futuro e mantém histórico/auditoria.

## TDD da SPEC

| Etapa | Prova | Ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | ausência da capacidade/contrato | executar Suite RLS com usuários sintéticos A/B, anon e admin; leitura e escrita cross-clinic negadas. antes da implementação | pelo menos CA-P1-S02-01 falha por motivo esperado | saída de teste/cenário versionada |
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
| P1-S02-T01 | Configurar Auth e fluxo de convite/login conforme decisão aprovada. | técnico de implementação | Critério CA correspondente atendido no recorte desta tarefa | Teste/fluxo desta task conforme seção TDD | relatório/captura sanitizada vinculada ao run | ☐ Liberada |
| P1-S02-T02 | Aplicar políticas RLS por organização/clínica às tabelas expostas e revisar views. | técnico de integração | Critério CA correspondente atendido no recorte desta tarefa | Teste/fluxo desta task conforme seção TDD | relatório/captura sanitizada vinculada ao run | ☐ Liberada |
| P1-S02-T03 | Executar matriz positiva/negativa por role, membership e revogação. | QA + dono operacional | Critério CA correspondente atendido no recorte desta tarefa | Teste/fluxo desta task conforme seção TDD | relatório/captura sanitizada vinculada ao run | ☐ Liberada |

## Emendas

| Data | Origem | Alteração | Motivo |
|---|---|---|---|
| — | — | Nenhuma | SPEC inicial |
