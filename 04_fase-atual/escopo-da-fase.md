# Fase 1 — Base Supabase e identificação de paciente

## Resultado
Usuários autorizados entram no CRM e veem somente suas clínicas; administradores cadastram clínicas, usuários e conexões pela interface; a equipe consulta contato e identifica estado de paciente com segurança.

## Entregas da fase

1. Esquema multi-clínica e migrations versionadas.
2. Autenticação, papéis e isolamento RLS.
3. Console inicial de organizações, clínicas, usuários, memberships e equipes.
4. Conexões, secrets e configurações versionadas.
5. Cliente server-side da Clínica Experts e busca/identificação de paciente.

## Critérios globais
Isolamento entre clínicas aplicado no banco; segredos no servidor; busca com estados zero/um/múltiplos; erros externos sanitizados e recuperáveis; uma terceira clínica pode ser cadastrada sem mudança de código.

As cinco SPECs detalham os contratos, tasks e evidências. Todas as aprovações foram confirmadas pela responsável; dependências técnicas estão indicadas no índice.

# Fase 2 — Inbox WhatsApp, triagem e transbordo

## Resultado
Toda mensagem de WhatsApp entra no CRM, é ligada à clínica e ao contato certos e chega a uma resposta aprovada ou a uma atendente, com fila, prazo e responsável.

## Entregas da fase

1. Base versionada, tipada e protegida no repositório do CRM (P2-S01).
2. Conexão real com o Clínica Experts e tela de identificação de paciente (P2-S02).
3. Números de WhatsApp conectados (Meta Cloud API e Z-API) (P2-S03).
4. Conversas e caixa de entrada em tempo real (P2-S04).
5. Tickets, filas, prazos e cadeia de transbordo (P2-S05).
6. Triagem automática, guardião de políticas e respostas aprovadas (P2-S06).
7. Copiloto da atendente e versões de prompt (P2-S07).

## Critérios globais
Nenhuma mensagem duplicada ou perdida; nenhuma conversa, ticket ou configuração visível fora da clínica; nenhuma resposta automática sobre preço, desconto, saúde ou reclamação; sugestão da IA nunca enviada sem o clique da atendente; segredos só no servidor; atendimento humano funciona com IA, Clínica Experts ou provedor fora do ar.

A fase 2 roda em paralelo ao fechamento operacional da fase 1. Convenções técnicas comuns em `01-SPECS/00-CONTRATO-COMUM-FASE-2.md`.

# Fase 3 — CRM, agenda assistida, follow-up e painel

## Resultado
A equipe conduz o lead do primeiro contato à avaliação, com dono e próxima ação em cada caso, e o gestor enxerga funil, prazos, conversão e a primeira linha de base.

## Entregas da fase

1. Espelho de catálogos, agenda e vendas do Clínica Experts, separado por unidade (P3-S01).
2. Funil comercial com leads, oportunidades e motivos de perda (P3-S02).
3. Tarefas e próxima ação obrigatória em todo contato (P3-S03).
4. Agenda assistida no atendimento, sem gravar no Clínica Experts (P3-S04).
5. Follow-up por cadência configurável (P3-S05).
6. Resultado da avaliação e recuperação de quem não fechou (P3-S06).
7. Painel do gestor e linha de base (P3-S07).

## Critérios globais
Nada é gravado no Clínica Experts; o dado do Clínica Experts prevalece em divergência; nenhum contato fica sem próxima ação; nenhuma mensagem sai sozinha sem modelo aprovado e interruptor ligado na clínica; cada usuário vê só as suas clínicas.

Convenções técnicas comuns em `01-SPECS/00-CONTRATO-COMUM-FASE-2.md`, que vale também para esta fase.
