# Especificação funcional — Console administrativo e atendimento humano

**Versão:** 1.0 — 21/09/2026
**Vínculo:** anexo normativo do `02-Escopo-Definitivo.md`, versão 3.0
**Objetivo:** permitir que a PS Estética configure novas clínicas, integrações, pessoas, agentes e operação sem mudança rotineira de código, preservando segurança, versionamento e isolamento multi-clínica.

## 1. Perfis e escopo

| Perfil | Escopo administrativo |
|---|---|
| `platform_admin` | Infraestrutura lógica, integrações, referências de segredo, saúde e suporte técnico autorizado. |
| `owner` | Todas as clínicas da organização, políticas, agentes, relatórios e publicação de configurações. |
| `clinic_admin` | Usuários, equipes, filas, canais, conteúdo e regras somente das clínicas permitidas. |
| `manager` | Operação, distribuição, SLA, templates e aprovações delegadas; sem acesso a segredo. |
| Atendentes | Inbox, tickets, contexto e sugestões; sem console técnico. |

Regras obrigatórias:

- Toda consulta e mutação recebe `organization_id` e, quando aplicável, `clinic_id` do contexto autorizado, nunca de confiança exclusiva no navegador.
- Usuário sem membership não descobre nome, número, volume, prompt ou existência de dados de outra clínica.
- Alteração administrativa registra autor, motivo, versão, data e valores sanitizados antes/depois.
- Segredo pode ser criado, substituído, rotacionado ou revogado; nunca visualizado após o salvamento.

## 2. Navegação do console

| Rota | Tela | Função principal |
|---|---|---|
| `/admin/overview` | Visão geral | Saúde por clínica, pendências, versões em rascunho e alertas. |
| `/admin/clinics` | Clínicas | Cadastrar, editar, desativar e abrir o assistente de implantação. |
| `/admin/integrations` | Integrações | Meta, Z-API, Clínica Experts e provedor de IA por escopo. |
| `/admin/users` | Usuários | Convites, papéis, memberships, equipes, turnos e capacidade. |
| `/admin/queues` | Filas e SLA | Roteamento, expediente, reoferta, escalonamento e fallback. |
| `/admin/agents` | Agentes | Ativação, modelo, ferramentas, autonomia, orçamento e fallback por clínica. |
| `/admin/prompts` | Prompts | Sistema/instruções, variáveis, sandbox, aprovação, publicação e rollback. |
| `/admin/knowledge` | Conhecimento | Conteúdo aprovado, validade, clínica, categoria e versão. |
| `/admin/templates` | Mensagens | Templates por provedor, finalidade, consentimento e status de aprovação. |
| `/admin/features` | Funcionalidades | Feature flags globais e exceções por clínica. |
| `/admin/health` | Saúde | Webhooks, conexões, filas, cron, dead-letter, latência e custos. |
| `/admin/audit` | Auditoria | Busca por ator, clínica, entidade, ação, versão e período. |
| `/inbox` | Atendimento | Lista de tickets/conversas por fila, SLA e responsável. |

## 3. Assistente de cadastro de clínica

O onboarding da terceira clínica e das seguintes ocorrerá em etapas, com salvamento em rascunho:

1. **Identidade:** nome, código, fuso, endereço, contato responsável e status.
2. **Herança:** copiar defaults da organização ou clonar configuração não sensível de uma clínica existente; credenciais e memberships nunca são clonadas.
3. **Clínica Experts:** ID/mapeamento externo, conexão aplicável, leitura de teste e mapeamentos mínimos.
4. **WhatsApp:** cadastrar número E.164, escolher Meta Cloud API ou Z-API, informar dados protegidos e validar webhook/conectividade.
5. **Pessoas:** convidar/associar atendentes e gestores, equipes, papéis, turnos e capacidade.
6. **Filas:** Comercial, Recepção, Pós-venda e filas especiais; estratégia, SLA, backup e fora do expediente.
7. **Agentes:** escolher agentes ativos, prompts herdados/próprios, conhecimento, ferramentas, autonomia e limites.
8. **Mensagens:** espera, transbordo, fora do horário, falha e templates de follow-up.
9. **Teste:** mensagem inbound/outbound controlada, identificação simulada, criação de ticket, aceite, reoferta e escalonamento.
10. **Publicação:** resumo de impacto, pendências bloqueantes, aprovador e ativação gradual por feature flags.

Uma clínica em `draft` não recebe tráfego. Uma clínica `active` precisa ter ao menos um canal saudável, uma fila padrão, uma equipe elegível, fallback válido e políticas publicadas.

## 4. Integrações e credenciais

### 4.1 Meta WhatsApp Cloud API

Campos operacionais: clínica, número E.164, identificador do número, identificador da conta empresarial, versão do adapter, URL de webhook, status, capacidades e templates associados. Tokens e segredos são enviados diretamente ao serviço server-side e substituídos por `secret_ref`.

Ações: salvar rascunho, testar autenticação, validar webhook, sincronizar capacidades/templates, ativar, pausar, rotacionar credencial e ver diagnóstico sanitizado.

### 4.2 Z-API

Campos operacionais: clínica, número E.164, identificador da instância, URL/base permitida, versão do adapter, webhooks configurados, status da sessão e capacidades. Token de instância e `Client-Token` são protegidos por `secret_ref`.

Ações: testar autenticação, validar instância/número, verificar sessão, registrar webhooks, ativar, pausar, substituir credencial e iniciar procedimento controlado de reconexão. QR code ou dado equivalente só aparece para administrador autorizado, de forma temporária e sem persistência em log.

### 4.3 Clínica Experts

Campos operacionais: escopo organização/clínica, referência da credencial, ID externo da clínica, limite interno de requisições, timeout, cache e allowlist de leitura/escrita. A tela oferece mapeamento assistido de profissionais, procedimentos, salas, vendedores, pipelines e estágios.

### 4.4 Teste e publicação

- Teste de conexão é não destrutivo e usa endpoint de leitura/health quando disponível.
- Resultado mostra sucesso, latência, data, escopo, código sanitizado e ação recomendada; nunca mostra cabeçalho ou resposta sensível.
- Configuração inválida não pode ser publicada.
- Rotação mantém referência anterior apenas pelo tempo técnico de rollback e a revoga conforme runbook.

## 5. Usuários, equipes e atendentes

O cadastro permite convite, nome, e-mail, telefone corporativo opcional, status, papéis, clínicas, equipes, habilidades, turno, capacidade simultânea e substituto. Uma mesma pessoa pode atuar em mais de uma clínica somente se receber memberships explícitas; isso não ocorre por herança.

Estados de presença: `offline`, `available`, `busy`, `away` e `do_not_disturb`. A capacidade efetiva considera presença, turno, ausências e tickets ativos. O gestor pode redistribuir ticket com motivo obrigatório.

## 6. Agentes, prompts e conhecimento

### 6.1 Configuração do agente por clínica

- Habilitado/desabilitado.
- Prompt de sistema e instruções específicas.
- Política de modelo e fallback de modelo, sem expor chave.
- Allowlist de ferramentas e operações de cada ferramenta.
- Confiança mínima para sugerir e, quando permitido, enviar.
- Autonomia: `recommend_only`, `human_approval`, `auto_low_risk` ou `disabled`.
- Timeout, número máximo de chamadas, orçamento por execução/dia e concorrência.
- Base de conhecimento e versão ativa.
- Comportamento diante de ambiguidade, ferramenta indisponível, custo excedido ou política ausente.

### 6.2 Ciclo de prompt

`draft -> validating -> approved -> published -> superseded|rolled_back`

O editor oferece variáveis permitidas, validação contra prompt injection básico, preview do contexto que será enviado, dados sintéticos de teste, comparação lado a lado e avaliação de casos de referência. Publicar fixa conteúdo, modelo, ferramentas e thresholds em uma versão imutável. Rollback cria evento; não apaga versões.

Variáveis e dados não permitidos são rejeitados no servidor. Prompt não pode referenciar segredo, executar SQL, alterar RLS ou habilitar ferramenta fora da allowlist.

## 7. Inbox e ticket de atendimento

### 7.1 Lista de tickets

Filtros: clínica, fila, status, prioridade, SLA, atendente, paciente/lead, provider, número, intenção, data e sem responsável. Cada item exibe tempo de espera, última mensagem, prioridade, identificação, fila, responsável e alerta de SLA.

Visualizações salvas: “Minha fila”, “Sem responsável”, “SLA próximo”, “Escalados”, “Falha de provider”, “Aguardando cliente” e visões customizadas permitidas.

### 7.2 Área do ticket

- Cabeçalho com clínica, número/provedor, contato, paciente/lead, prioridade, SLA, fila e responsável.
- Conversa cronológica com direção, autoria, status de envio e anexos permitidos.
- Contexto comercial: lead, oportunidade, estágio, tarefas e próxima ação.
- Contexto Clínica Experts mínimo e autorizado: vínculo, agendamentos relevantes e demais dados necessários ao caso.
- Ações humanas: aceitar, responder, anexar, transferir, escalar, aguardar cliente, criar tarefa, marcar resultado e resolver.
- Bloqueio de envio quando a conta estiver indisponível; rascunho permanece salvo e claramente não enviado.

### 7.3 Copiloto de IA

O painel do AG-14 mostra:

- resumo curto e fatos principais;
- intenção e confiança;
- estado paciente/lead e evidência do vínculo;
- resposta sugerida com fontes internas;
- próxima melhor ação;
- dados faltantes e perguntas recomendadas;
- opções de agenda quando disponíveis;
- alertas de risco, consentimento, prazo e política.

Cada item pode ser usado, editado ou descartado. A interface destaca quando parte da sugestão está desatualizada, sem fonte ou depende de confirmação. O envio final registra versão da sugestão, edição humana e autor.

## 8. Roteamento e fallback do transbordo

### 8.1 Gatilhos de ticket

Pedido explícito de pessoa; baixa confiança; identidade ambígua; assunto clínico/financeiro/reclamação; agendamento; política que exige humano; falha de IA/ferramenta; mensagem não suportada; decisão do agente/atendente; ou SLA de automação excedido.

### 8.2 Cadeia padrão

| Ordem | Condição | Ação |
|---|---|---|
| 1 | Há atendente elegível | Ofertar conforme estratégia e iniciar tempo de aceite. |
| 2 | Oferta expirou | Reofertar à próxima elegível, respeitando capacidade e limite. |
| 3 | Reofertas esgotadas | Enviar para equipe de backup da mesma clínica. |
| 4 | Backup indisponível/SLA crítico | Escalar para manager/plantonista e emitir alerta. |
| 5 | Fora do expediente | Mensagem aprovada, ticket aberto e tarefa no próximo período útil. |
| 6 | Ninguém disponível | Manter fila e modo somente humano; nunca inventar resposta para liberar backlog. |

### 8.3 Falhas técnicas

| Falha | Comportamento |
|---|---|
| IA indisponível | Atendimento e fila continuam; mostrar contexto local e checklist manual. |
| Clínica Experts indisponível | Usar cache dentro da validade, marcar dado potencialmente desatualizado e criar retry; ações sensíveis aguardam humano. |
| Meta indisponível | Outbox, retry idempotente, circuit breaker, alerta e dead-letter. |
| Z-API desconectada | Pausar automações da instância, alertar administrador, preservar tickets/rascunhos e orientar reconexão. |
| Realtime indisponível | Polling controlado/refresh e alerta; nenhuma atribuição é perdida porque o banco é a fonte de verdade. |
| Fila/worker atrasado | Alerta de lag, consumidor reserva e replay seguro. |

Troca de provedor, número ou clínica nunca é automática. Se o cliente autorizar contato por outro canal, a atendente inicia uma nova interação vinculada, com motivo, consentimento e autoria registrados.

## 9. Critérios de aceite do console

- [ ] `owner` cadastra uma terceira clínica completa sem alteração de código.
- [ ] Cada clínica possui números, providers, atendentes, equipes, filas, SLA, prompts e templates independentes.
- [ ] Configuração herdada mostra origem e pode ser sobrescrita só no escopo permitido.
- [ ] Meta e Z-API recebem, enviam e atualizam status por adapters independentes.
- [ ] Credenciais não aparecem em HTML, logs, banco operacional, auditoria ou resposta de teste.
- [ ] Prompt passa por rascunho, teste, publicação, comparação e rollback.
- [ ] Feature flag desliga agente/auto-resposta por clínica sem derrubar atendimento humano.
- [ ] Ticket percorre oferta, aceite, reoferta, backup, escalonamento e fora do expediente.
- [ ] AG-14 sugere com evidências; atendente aceita, edita ou rejeita antes de enviar.
- [ ] Falha da IA, Clínica Experts, Meta e Z-API é simulada com os fallbacks definidos.
- [ ] RLS impede leitura e escrita cruzadas entre clínicas não autorizadas.
- [ ] Toda mudança administrativa relevante é auditável e reversível por versão quando aplicável.

## 10. Decisões que permanecem para a implantação

- Mapa real de clínicas, números e provider de cada número.
- Titularidade e credenciais das contas Meta e instâncias Z-API.
- Lista inicial de atendentes, vínculos, equipes, turnos, capacidades e habilidades.
- SLA de aceite, primeira resposta, reoferta e escalonamento por fila.
- Equipes de backup, managers/plantonistas e mensagem fora do horário.
- Aprovadores e necessidade de dupla aprovação para configuração sensível.
- Prompts, templates, conhecimento e níveis de autonomia iniciais.
- Aceite formal do risco operacional do canal não oficial.
