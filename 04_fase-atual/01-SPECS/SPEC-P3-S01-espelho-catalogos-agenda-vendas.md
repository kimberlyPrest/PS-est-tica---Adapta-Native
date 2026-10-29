# P3-S01 — Espelho de catálogos, agenda e vendas do Clínica Experts

**Fase:** 3  
**Status:** liberada para implementação (29/10/2026)  
**Dono:** técnico de integração; aceite do owner  
**Origem no escopo:** §3, §7.3, §12.1, RT-07, RT-13, RT-15, RT-23, GATE-01, GATE-05; mapa de dados verificado em 13/10/2026  
**Degrau da solução:** reuso — cliente HTTP e limitador da P2-S02; filas e agendador nativos do Supabase.

## Contexto e decisões fechadas

- Volumes reais: 15 profissionais (12 ativos), 112 procedimentos (105 ativos), 2 salas (Espinheiro e Boa Viagem), cerca de 8.500 agendamentos e 1.300 vendas em 12 meses.
- Um único token cobre as duas unidades: a conexão é da organização, não de cada clínica.
- A sala vem vazia em 99% dos agendamentos (378 de 8.494 têm sala). A unidade do agendamento não pode ser lida diretamente da API.
- O vendedor de toda venda é um profissional cadastrado; a linha de venda traz só o nome do item, sem identificador; no agendamento, o identificador do procedimento é o do catálogo.
- 28 procedimentos têm duração zero, 19 têm preço zero e só 5 têm profissional vinculado.
- `/bookings` e `/sales` exigem intervalo com fuso; `per_page` máximo é 1000; valores vêm em centavos; pacientes não têm filtro por data de alteração.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

A tela "Dados do Clínica Experts" mostra profissionais, procedimentos, agenda e vendas espelhados, com a hora da última atualização, e cada agendamento e venda fica atribuído a uma clínica por regra explícita.

## Limites e dependências

- **Inclui:** espelhos de profissionais, procedimentos, salas, agendamentos e vendas; carga inicial de 12 meses; atualização periódica com marcadores; regra de atribuição de clínica; mapeamentos profissional → clínica e vendedor → usuário; fila de pendentes; tela de consulta.
- **Fora de escopo:** cópia integral da base de pacientes; parcelas, cobranças e contas financeiras; qualquer gravação no Clínica Experts; eventos em tempo real (P4-S01).
- **Entradas e pré-condições:** mapeamento aprovado de profissionais por unidade e de vendedores por usuário (GATE-01, GATE-05). Esses valores não travam a construção: o agente constrói a configuração com um padrão marcado como rascunho e o cliente preenche ou confirma os valores reais no teste desta SPEC (última task).
- **Saídas/artefatos:** tabelas `expert_*_cache`, `appointments_mirror`, `sales_mirror`, `integration_mappings`, `sync_cursors`; função `sync-clinica-experts`; tela de dados e de mapeamento.
- **Dependências e responsáveis:** P2-S02 (conexão real). Cliente entrega o mapeamento; owner valida as contagens.
- **Risco e plano B:** unidade atribuída errada distorcer indicadores por clínica — sem regra, o registro fica pendente em vez de ser chutado; a regra é configuração e pode ser reaplicada.
- **Rollback ou reversão:** pausar a atualização por flag; os espelhos ficam marcados como desatualizados e nada é apagado.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `GET /professionals`, `/procedures`, `/rooms` | Clínica Experts | catálogo completo, uma vez por dia |
| `GET /bookings?starts_at=&ends_at=` | Clínica Experts | paciente, profissional, procedimentos e sala embutidos; nove situações possíveis |
| `GET /sales?starts_at=&ends_at=` | Clínica Experts | comprador, vendedor, itens, formas de pagamento; valores em centavos |
| `appointments_mirror`, `sales_mirror` | Supabase (espelho) | chave pelo UUID externo; só campos mínimos do paciente |
| `integration_mappings` | Supabase | profissional → clínica; vendedor → usuário; sala → clínica |

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P3-S01-01 | A conexão é da organização; o espelho nunca é editado pela interface e o dado do Clínica Experts prevalece em divergência. |
| RN-P3-S01-02 | Clínica do agendamento: (1) sala informada; (2) mapeamento profissional → clínica; (3) sem regra, fica sem clínica e entra na fila "atribuir unidade". |
| RN-P3-S01-03 | Clínica da venda: agendamento do mesmo paciente a até um dia de distância; senão, mapeamento do vendedor; senão, pendente. |
| RN-P3-S01-04 | Carga inicial de 12 meses em janelas mensais. Depois: catálogos uma vez por dia; agendamentos de sete dias atrás a sessenta dias à frente a cada 15 minutos; vendas dos últimos sete dias a cada hora. |
| RN-P3-S01-05 | Do paciente, o espelho guarda só identificador, nome e telefone dos que aparecem em agendamento, venda ou busca. |
| RN-P3-S01-06 | A atualização usa no máximo 40 chamadas por minuto, deixando folga para a busca das atendentes. |
| RN-P3-S01-07 | A falta do paciente não é inferida da API: "não compareceu" foi usado uma vez em 12 meses; o resultado da avaliação vem da P3-S06. |

## Fluxo e regras

1. O administrador carrega os mapeamentos aprovados.
2. A carga inicial percorre 12 meses de agendamentos e vendas, mês a mês.
3. O agendador enfileira as atualizações periódicas por recurso.
4. Cada registro é gravado pelo UUID externo e recebe a clínica pela regra.
5. A tela mostra os espelhos, a última atualização e os pendentes de unidade.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | carga inicial com mapeamento carregado | contagens por mês iguais às da API; pendentes de unidade abaixo de 2% | relatório de conferência |
| Limite | profissional sem mapeamento, procedimento sem duração, venda sem agendamento próximo | registro pendente e sinalizado; nada é chutado | administrador completa o mapeamento e reaplica a regra |
| Falha | Clínica Experts fora do ar ou limite atingido | atualização registra a falha, mantém o marcador e a tela mostra "desatualizado desde" | retoma do marcador na próxima execução |

## Checklist de execução

- [ ] Mapeamento aprovado carregado.
- [ ] Carga inicial concluída sem resposta de limite excedido.
- [ ] Contagens conferidas mês a mês.
- [ ] Fila "atribuir unidade" revisada com o cliente.
- [ ] Owner validou a tela de dados.

## Critérios de aceite

- [ ] **CA-P3-S01-01:** A carga inicial de 12 meses termina sem nenhuma resposta 429 e com contagens mensais de agendamentos e vendas iguais ao total informado pela API.
- [ ] **CA-P3-S01-02:** Os catálogos espelhados batem em quantidade e nos campos ativo, duração e preço.
- [ ] **CA-P3-S01-03:** Todo agendamento espelhado tem clínica ou está na fila "atribuir unidade"; com o mapeamento aprovado, os pendentes ficam abaixo de 2%.
- [ ] **CA-P3-S01-04:** Rodar a atualização duas vezes não duplica nem altera registros que não mudaram.
- [ ] **CA-P3-S01-05:** Uma mudança de situação feita no Clínica Experts aparece no espelho em até 15 minutos.
- [ ] **CA-P3-S01-06:** Com o Clínica Experts fora do ar, a atualização registra a falha, mantém o marcador e a tela mostra "desatualizado desde".
- [ ] **CA-P3-S01-07:** Cada usuário vê agenda e vendas só das suas clínicas, e valores de venda aparecem apenas para gestor e proprietário.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | espelho vazio | consultar agenda de um mês conhecido | zero registros: CA-P3-S01-01 falha | saída versionada do runner ou roteiro, anexada à task |
| GREEN | carga inicial e atualização | carregar um mês e comparar com o total da API | CA-P3-S01-01, CA-P3-S01-02 e CA-P3-S01-04 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | atribuição, atraso, indisponibilidade e permissão | registro sem mapeamento; mudança de situação; API simulada fora do ar; usuário de outra clínica | CA-P3-S01-03, CA-P3-S01-05, CA-P3-S01-06 e CA-P3-S01-07 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** API simulada com um mês sintético (com e sem sala, com e sem mapeamento); conferência final contra a API real em ambiente autorizado.  
**Caminhos de erro obrigatórios:** 429, timeout, intervalo sem fuso (422), profissional sem mapeamento, venda sem agendamento próximo, registro repetido.  
**Evidência exigida:** relatório de conferência mensal, lista de pendentes e capturas da tela de dados.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P3-S01-T01 | Criar os espelhos, os marcadores e as telas de mapeamento profissional → clínica e vendedor → usuário. | técnico de banco + frontend | CA-P3-S01-07 | RED do espelho vazio; permissão por clínica | capturas do mapeamento e matriz de acesso | P2-S02-T01 | 05/11/2026 | ☐ Liberada |
| P3-S01-T02 | Implementar a carga inicial de 12 meses e a atualização periódica com orçamento de chamadas. | técnico de integração | CA-P3-S01-01, CA-P3-S01-02, CA-P3-S01-04, CA-P3-S01-05 | GREEN de um mês e idempotência | relatório do runner e contagens | T01 concluída | 05/11/2026 | ☐ Liberada |
| P3-S01-T03 | Implementar a regra de atribuição de clínica e a fila "atribuir unidade". | técnico de integração | CA-P3-S01-03 | bordas de atribuição | lista de pendentes antes e depois | T02 concluída | 06/11/2026 | ☐ Liberada |
| P3-S01-T04 | Conferir contagens contra a API, a indisponibilidade e demonstrar a tela de dados. | QA + owner | CA-P3-S01-01, CA-P3-S01-03, CA-P3-S01-06, CA-P3-S01-07 | REGRESSÃO completa | relatório de conferência e aceite | T03 concluída | 06/11/2026 | ☐ Liberada |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| 2026-10-29 | Liberação da fase 3 | Pré-condições das tasks e teste do cliente | Valor que depende do cliente deixa de travar a construção: entra como rascunho e é confirmado no teste da SPEC, na última task, conforme o contrato comum (seção 8) |
