# P3-S07 — Painel do gestor e linha de base

**Fase:** 3  
**Status:** liberada para implementação (29/10/2026)  
**Dono:** técnico de dados; aceite do manager e do owner  
**Origem no escopo:** §17, §1 (resultados mensuráveis), §6.7, RT-12 (parcial), GATE-12  
**Degrau da solução:** dependência existente — biblioteca de gráficos já instalada; agregação diária por agendador.

## Contexto e decisões fechadas

- As metas de melhoria só serão fixadas depois de 30 dias de linha de base confiável.
- A situação das parcelas na API não é confiável (144 de 147 parcelas de setembro de 2026 aparecem como atrasadas): o painel não usa parcelas, cobranças nem contas financeiras.
- Referência de volume: 788 agendamentos e 112 vendas em setembro de 2026.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

Um painel por clínica e período com atendimento, funil, agenda e vendas, em que cada número abre a lista de casos que o compõem, e a linha de base inicial fica registrada, com a data em que a contagem de 30 dias começou.

## Limites e dependências

- **Inclui:** agregação diária reprodutível; dicionário de indicadores com definição, origem e versão; painel com filtro por clínica e período; abertura do número em lista; exportação da linha de base inicial.
- **Fora de escopo:** resumo e recomendações automáticas (P5-S01); indicadores financeiros de parcelas; avaliação individual de pessoas por conteúdo de conversa.
- **Entradas e pré-condições:** definições de indicadores revisadas com o gestor; 12 meses de agenda e vendas espelhados; dias já operados de atendimento. Esses valores não travam a construção: o agente constrói a configuração com um padrão marcado como rascunho e o cliente preenche ou confirma os valores reais no teste desta SPEC (última task).
- **Saídas/artefatos:** tabela `metrics_daily`, função `build-commercial-metrics`, painel, dicionário e relatório de linha de base.
- **Dependências e responsáveis:** P2-S05, P3-S01, P3-S02, P3-S05 e P3-S06. Manager e owner validam.
- **Risco e plano B:** número do painel divergir do Clínica Experts e perder a confiança do gestor — conferência obrigatória contra a contagem direta da API antes do aceite.
- **Rollback ou reversão:** recalcular a partir dos eventos; a versão anterior do indicador continua consultável.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| `metrics_daily` | Supabase | clínica, data, indicador, valor e versão da definição |
| Eventos de conversa, ticket, oportunidade e cadência | Supabase | origem dos indicadores de operação e funil |
| `appointments_mirror`, `sales_mirror` | Supabase (espelho) | origem dos indicadores de agenda e vendas |

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P3-S07-01 | Todo indicador tem definição, origem, versão e responsável publicados na tela. |
| RN-P3-S07-02 | O cálculo é reprodutível: recalcular o mesmo dia devolve o mesmo número. |
| RN-P3-S07-03 | Valores financeiros aparecem só para gestor e proprietário. |
| RN-P3-S07-04 | Indicadores por pessoa mostram volume e prazo, nunca conteúdo de conversa. |
| RN-P3-S07-05 | A linha de base inicial usa 12 meses de agenda e vendas e os dias já operados de atendimento; os 30 dias de atendimento fecham na P5-S06, onde as metas são registradas. |

## Fluxo e regras

1. O agendador recalcula os indicadores do dia anterior por clínica.
2. O gestor abre o painel, escolhe clínica e período.
3. Clica num número e vê a lista de casos.
4. Consulta o dicionário para ver como o número é calculado.
5. Exporta a linha de base inicial e registra a data de início da contagem de 30 dias.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | mês com dados completos | indicadores de operação, funil, agenda e vendas por clínica | número abre a lista de casos |
| Limite | dia sem dados, clínica sem vínculo, indicador recalculado | zero explícito; acesso negado; mesmo valor | nenhum número inventado |
| Falha | espelho desatualizado ou agregação falha | painel avisa "dados até" e não mostra parcial como final | recalcula na próxima execução |

## Checklist de execução

- [ ] Definições revisadas com o gestor.
- [ ] Conferência contra a API executada para um mês.
- [ ] Recalcular o mesmo dia conferido.
- [ ] Permissão de valores financeiros conferida.
- [ ] Linha de base inicial exportada e data de início dos 30 dias registrada.

## Critérios de aceite

- [ ] **CA-P3-S07-01:** O painel mostra os indicadores de operação: volume, tempo de primeira resposta, tempo em fila, prazo vencido e taxa de transbordo.
- [ ] **CA-P3-S07-02:** O painel mostra o funil: leads por origem, lead para agendamento, comparecimento, avaliação para venda, perda por motivo e ciclo.
- [ ] **CA-P3-S07-03:** Agendados, realizados, cancelados, vendas e ticket médio batem com a contagem direta na API para o mês de conferência, com diferença zero e as duas contagens tiradas no mesmo instante de corte.
- [ ] **CA-P3-S07-04:** Recalcular o mesmo dia produz o mesmo número.
- [ ] **CA-P3-S07-05:** Clicar em um número abre a lista filtrada dos casos que o compõem.
- [ ] **CA-P3-S07-06:** O dicionário de indicadores está publicado na tela com definição, origem e versão.
- [ ] **CA-P3-S07-07:** O filtro por clínica respeita os vínculos do usuário e os valores financeiros aparecem só para gestor e proprietário.
- [ ] **CA-P3-S07-08:** A linha de base inicial foi exportada e validada pelo gestor, com a data de início da contagem de 30 dias de atendimento.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | painel sem dados | abrir o painel de um mês conhecido | vazio: CA-P3-S07-01 falha | saída versionada do runner ou roteiro, anexada à task |
| GREEN | agregação e painel | calcular um mês e abrir os números em lista | CA-P3-S07-01, CA-P3-S07-02, CA-P3-S07-05 e CA-P3-S07-06 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | conferência, reprodutibilidade, permissão e linha de base | comparar com a API; recalcular; usuário de outra clínica e outro papel; exportar a linha de base inicial | CA-P3-S07-03, CA-P3-S07-04, CA-P3-S07-07 e CA-P3-S07-08 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** mês sintético com resultado conhecido; conferência final contra a API real em ambiente autorizado.  
**Caminhos de erro obrigatórios:** dia sem dados, espelho atrasado, indicador sem definição, usuário sem permissão.  
**Evidência exigida:** tabela de conferência, capturas do painel e linha de base inicial validada.

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P3-S07-T01 | Criar a agregação diária reprodutível e o dicionário de indicadores. | técnico de dados | CA-P3-S07-04, CA-P3-S07-06 | RED/GREEN da agregação | relatório do runner e dicionário | P3-S01-T02; P3-S02-T01 | 19/11/2026 | ☐ Liberada |
| P3-S07-T02 | Construir o painel com filtros, abertura do número em lista e permissões. | técnico de frontend | CA-P3-S07-01, CA-P3-S07-02, CA-P3-S07-05, CA-P3-S07-07 | cenário principal e permissão | capturas do painel | T01 concluída | 19/11/2026 | ☐ Liberada |
| P3-S07-T03 | Conferir os números contra a API, registrar a linha de base e demonstrar a fase 3. | QA + manager | CA-P3-S07-03, CA-P3-S07-04, CA-P3-S07-08 | REGRESSÃO e conferência do mês | tabela de conferência e linha de base inicial validada | T02; SPECs P3-S01 a P3-S06 concluídas | 19/11/2026 | ☐ Liberada |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| 2026-10-29 | Liberação da fase 3 | Pré-condições das tasks e teste do cliente | Valor que depende do cliente deixa de travar a construção: entra como rascunho e é confirmado no teste da SPEC, na última task, conforme o contrato comum (seção 8) |
