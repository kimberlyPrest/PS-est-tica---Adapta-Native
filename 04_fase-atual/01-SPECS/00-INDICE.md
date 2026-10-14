# Índice de SPECs — Fase 1

Todas as SPECs estão liberadas para implementação. Dependências listadas abaixo são ordem técnica de entrega, sem aprovação pendente.

| ID | Capacidade | SPEC | Tasks | Dependência técnica |
|---|---|---|---|---|
| P1-S01 | Esquema multi-clínica e migrations | [SPEC-P1-S01-schema-tenancy.md](./SPEC-P1-S01-schema-tenancy.md) | P1-S01-T01, P1-S01-T02, P1-S01-T04, P1-S01-T03 | — |
| P1-S02 | Autenticação, papéis e isolamento RLS | [SPEC-P1-S02-auth-rls.md](./SPEC-P1-S02-auth-rls.md) | P1-S02-T01, P1-S02-T02, P1-S02-T03 | P1-S01 schema |
| P1-S03 | Console inicial de organizações, clínicas e usuários | [SPEC-P1-S03-admin-organizacao.md](./SPEC-P1-S03-admin-organizacao.md) | P1-S03-T01, P1-S03-T02, P1-S03-T03 | P1-S01 + P1-S02 |
| P1-S04 | Conexões, secrets e configuração versionada | [SPEC-P1-S04-admin-secrets-config.md](./SPEC-P1-S04-admin-secrets-config.md) | P1-S04-T01, P1-S04-T02, P1-S04-T03 | P1-S01 + P1-S02 |
| P1-S05 | Cliente Clínica Experts e busca/identificação de paciente | [SPEC-P1-S05-clinica-experts-paciente.md](./SPEC-P1-S05-clinica-experts-paciente.md) | P1-S05-T01, P1-S05-T02, P1-S05-T03 | P1-S01 + P1-S02 + P1-S04 |

# Índice de SPECs — Fase 2

**Inbox WhatsApp, triagem e transbordo** — Toda mensagem de WhatsApp entra no CRM, é ligada à clínica e ao contato certos e chega a uma resposta aprovada ou a uma atendente, com fila, prazo e responsável.

**Leia antes de qualquer task:** [00-CONTRATO-COMUM-FASE-2.md](./00-CONTRATO-COMUM-FASE-2.md) — convenções de banco, acesso, funções, filas, telas e provas que valem para todas as SPECs desta fase.

Status de todas: liberada para implementação (em paralelo ao fechamento da fase 1). Dependência técnica indica ordem de execução.

| ID | Capacidade | SPEC | Tasks | Dependência técnica | Prazo |
|---|---|---|---|---|---|
| P2-S01 | Base versionada, tipada e protegida no repositório do CRM | [SPEC-P2-S01-base-versionada-e-protegida.md](./SPEC-P2-S01-base-versionada-e-protegida.md) | P2-S01-T01, P2-S01-T02, P2-S01-T03, P2-S01-T04 | fase 1 aceita (16/16) | 16/10/2026 |
| P2-S02 | Conexão real com o Clínica Experts e tela de identificação de paciente | [SPEC-P2-S02-conexao-real-clinica-experts.md](./SPEC-P2-S02-conexao-real-clinica-experts.md) | P2-S02-T01, P2-S02-T02, P2-S02-T03, P2-S02-T04 | P2-S01 (repositório com as funções) | 20/10/2026 |
| P2-S03 | Números de WhatsApp conectados (Meta Cloud API e Z-API) | [SPEC-P2-S03-numeros-whatsapp-meta-zapi.md](./SPEC-P2-S03-numeros-whatsapp-meta-zapi.md) | P2-S03-T01, P2-S03-T02, P2-S03-T03, P2-S03-T04 | P2-S01; P1-S04 (segredos) | 22/10/2026 |
| P2-S04 | Conversas e caixa de entrada em tempo real | [SPEC-P2-S04-conversas-e-caixa-de-entrada.md](./SPEC-P2-S04-conversas-e-caixa-de-entrada.md) | P2-S04-T01, P2-S04-T02, P2-S04-T03, P2-S04-T04 | P2-S02 e P2-S03 | 26/10/2026 |
| P2-S05 | Tickets, filas, prazos e cadeia de transbordo | [SPEC-P2-S05-tickets-filas-sla-transbordo.md](./SPEC-P2-S05-tickets-filas-sla-transbordo.md) | P2-S05-T01, P2-S05-T02, P2-S05-T03, P2-S05-T04 | P2-S04 | 28/10/2026 |
| P2-S06 | Triagem automática, guardião de políticas e respostas aprovadas | [SPEC-P2-S06-triagem-guardiao-respostas-aprovadas.md](./SPEC-P2-S06-triagem-guardiao-respostas-aprovadas.md) | P2-S06-T01, P2-S06-T02, P2-S06-T03, P2-S06-T04 | P2-S04 e P2-S05 | 30/10/2026 |
| P2-S07 | Copiloto da atendente e versões de prompt | [SPEC-P2-S07-copiloto-da-atendente-e-prompts.md](./SPEC-P2-S07-copiloto-da-atendente-e-prompts.md) | P2-S07-T01, P2-S07-T02, P2-S07-T03, P2-S07-T04 | P2-S05 e P2-S06 | 04/11/2026 |

## Fora desta fase

| Item | Motivo |
|---|---|
| Instagram produtivo | fase futura (P5-S08 apenas prepara o canal, desligado) |
| Campanha em massa | fase 4 (P4-S04) |
| Agendamento feito pelo sistema | fase 4 (P4-S02), com confirmação humana |
| Gravação no CRM do Clínica Experts | fora do programa enquanto o módulo estiver desabilitado na clínica |
| Funil, tarefas e follow-up | fase 3 |
