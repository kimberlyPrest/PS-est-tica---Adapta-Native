# Fase 1 — Jornada de execução

<!-- fase-format:2 -->

- [x] Materializar organizations, clinics, profiles e memberships sem perder o baseline existente. @técnico de banco #projeto — concluída em 2026-09-29 <!-- id:86eb4738-bb19-4b90-9746-36f037eeb983 -->
      > P1-S01-T01 — CA-P1-S01-01: quatro contratos T01 presentes; instalação limpa e upgrade aprovados; profiles e histórico preservados. | migration 20260929145212; testes PGlite e validação humana registrados no changelog.
- [ ] Criar clinic_settings, teams, team_members, contacts, contact_identities e integration_connections com PKs, timestamps e escopo organization/clinic. @técnico de banco #projeto   <!-- id:2072d8ea-9798-423d-9b53-02d7ad1baf7a -->
      > P1-S01-T02 — CA-P1-S01-02: seis contratos e FKs presentes; connections usam `organization_id`, `clinic_id` opcional e `connection_key`; tabelas têm PK técnica `id` e timestamps comuns. | CA e cenário TDD correspondente na SPEC.
- [ ] Aplicar e validar as constraints UNIQUE adicionais da SPEC P1-S01. @técnico de banco + QA #projeto   <!-- id:bd34f885-f8b2-41e9-9a14-d7dc6143fdc2 -->
      > P1-S01-T04 — CA-P1-S01-04: duplicatas das chaves declaradas são rejeitadas e coexistências permitidas são aceitas. | Matriz sintética de unicidades na SPEC.
- [ ] Validar instalação limpa, upgrade e integridade relacional após T01, T02 e T04. @QA + técnico de banco #projeto   <!-- id:3d1eb137-481f-40fd-ba4f-5739d6b10739 -->
      > P1-S01-T03 — CA-P1-S01-03: instalação limpa e upgrade passam; `profiles` e histórico aplicado são preservados; terceira clínica é cadastrada sem nova migration. | CA e cenário TDD correspondente na SPEC.
- [ ] Configurar Auth e fluxo de convite/login conforme decisão aprovada. @técnico de implementação #projeto   <!-- id:ee1ff632-b444-42a9-bb01-a4e2337cab92 -->
      > P1-S02-T01 — Usuário sem sessão não lê dados operacionais. | CA e cenário TDD correspondente na SPEC.
- [ ] Aplicar políticas RLS por organização/clínica às tabelas expostas e revisar views. @técnico de integração #projeto   <!-- id:31435da1-a1b6-4f22-816c-8bac3569d62b -->
      > P1-S02-T02 — Membro da clínica A não lê nem altera clínica B via API direta. | CA e cenário TDD correspondente na SPEC.
- [ ] Executar matriz positiva/negativa por role, membership e revogação. @QA + dono operacional #projeto   <!-- id:94e9b0b0-2dc4-4315-9442-38d737ce41fa -->
      > P1-S02-T03 — Revogar membership invalida acesso futuro e mantém histórico/auditoria. | CA e cenário TDD correspondente na SPEC.
- [ ] Construir telas responsivas de clínicas, usuários, memberships e equipes. @técnico de implementação #projeto   <!-- id:a1038748-e36a-4178-9abe-ecccad2ecc7b -->
      > P1-S03-T01 — Owner cria/edita clínica e convida usuário com papel/clínicas delimitados. | CA e cenário TDD correspondente na SPEC.
- [ ] Validar campos, herança, estados de convite e restrições de role no servidor. @técnico de integração #projeto   <!-- id:ed0c201b-0540-495c-a9d4-1b0644af232a -->
      > P1-S03-T02 — Clinic_admin administra apenas a própria clínica. | CA e cenário TDD correspondente na SPEC.
- [ ] Demonstrar cadastro da terceira clínica e auditoria das mudanças. @QA + dono operacional #projeto   <!-- id:6cbad606-5a39-42a6-97c0-80aa99107bd0 -->
      > P1-S03-T03 — Configuração incompleta permanece em rascunho; nenhuma ação oferece SQL livre. | CA e cenário TDD correspondente na SPEC.
- [ ] Implementar gravação server-side do segredo e referência opaca. @técnico de implementação #projeto   <!-- id:12ff97c9-efcd-48f8-a8a1-eebc2e9b145f -->
      > P1-S04-T01 — Salvar segredo retorna somente estado/sufixo mascarado seguro; inspeção de rede não revela valor. | CA e cenário TDD correspondente na SPEC.
- [ ] Implementar formulário de conexão, teste sanitizado, versionamento e audit log. @técnico de integração #projeto   <!-- id:2cd2eba8-d205-42de-9d20-160cf75c0a73 -->
      > P1-S04-T02 — Teste retorna diagnóstico sanitizado e registra status/horário. | CA e cenário TDD correspondente na SPEC.
- [ ] Provar não exposição de segredo, falhas 401/429/timeout e rollback. @QA + dono operacional #projeto   <!-- id:88e308ae-fc63-465c-9fc5-92917913e837 -->
      > P1-S04-T03 — Rollback restaura configuração anterior sem apagar auditoria. | CA e cenário TDD correspondente na SPEC.
- [ ] Implementar cliente server-side HTTP com timeout, rate limiter e telemetria sanitizada. @técnico de implementação #projeto   <!-- id:2f4e0848-e94d-40f9-80d6-314d205b2364 -->
      > P1-S05-T01 — Busca zero/um/múltiplos produz estados definidos sem escolher múltiplos automaticamente. | CA e cenário TDD correspondente na SPEC.
- [ ] Implementar busca, normalização, deduplicação, vínculo humano e cache mínimo com TTL. @técnico de integração #projeto   <!-- id:c883b0e2-d40e-4992-a291-845a4256eaa2 -->
      > P1-S05-T02 — 401/422/429/timeout têm erro operacional sanitizado e correlação; falha não bloqueia conversa local. | CA e cenário TDD correspondente na SPEC.
- [ ] Construir fluxo de busca demonstrável e executar matriz zero/um/múltiplos/falhas. @QA + dono operacional #projeto   <!-- id:2e94d2a3-5242-4885-a050-2a4c606ff697 -->
      > P1-S05-T03 — Token nunca chega ao cliente; cache mínimo expira e pode ser invalidado. | CA e cenário TDD correspondente na SPEC.

# Fase 2 — Jornada de execução

- [ ] Importar migrations e funções do banco real para o repositório e provar diff vazio. @"técnico de banco" #projeto !14/10/2026
      > P2-S01-T01 — CA-P2-S01-01, CA-P2-S01-02 | Roteiro da task na SPEC.
- [ ] Remover seed com senha, trocar a credencial exposta, fechar o cadastro aberto e corrigir a leitura de `profiles`. @"técnico de segurança" #projeto !15/10/2026
      > P2-S01-T02 — CA-P2-S01-03, CA-P2-S01-04, CA-P2-S01-07 | Roteiro da task na SPEC.
- [ ] Gerar tipos, remover `as any`, criar guarda de rota e seletor de clínica e limpar o Dashboard. @"técnico de frontend" #projeto !15/10/2026
      > P2-S01-T03 — CA-P2-S01-04, CA-P2-S01-05, CA-P2-S01-06 | Roteiro da task na SPEC.
- [ ] Configurar suíte de testes e CI com varredura de segredos e demonstrar clone → reset → testes. @"QA" #projeto !16/10/2026
      > P2-S01-T04 — CA-P2-S01-01, CA-P2-S01-03, CA-P2-S01-05 | Roteiro da task na SPEC.
- [ ] Configurar base URL, token no Vault e `User-Agent`; classificar erros pelos quatro formatos. @"técnico de integração" #projeto !16/10/2026
      > P2-S02-T01 — CA-P2-S02-01, CA-P2-S02-04 | Roteiro da task na SPEC.
- [ ] Implementar busca em duas etapas, regra de ambiguidade e limitador guiado pelo cabeçalho. @"técnico de integração" #projeto !19/10/2026
      > P2-S02-T02 — CA-P2-S02-02, CA-P2-S02-03, CA-P2-S02-05 | Roteiro da task na SPEC.
- [ ] Construir a tela "Identificar paciente" e o cartão de saúde da conexão no `/admin`. @"técnico de frontend" #projeto !19/10/2026
      > P2-S02-T03 — CA-P2-S02-02, CA-P2-S02-07 | Roteiro da task na SPEC.
- [ ] Rodar a matriz com os telefones indicados pela clínica e a varredura de dado sensível. @"QA + reception" #projeto !20/10/2026
      > P2-S02-T04 — CA-P2-S02-02, CA-P2-S02-06, CA-P2-S02-07 | Roteiro da task na SPEC.
- [ ] Criar contas de canal, recibos, filas e o cadastro com teste de conexão no `/admin`. @"técnico de banco + frontend" #projeto !20/10/2026
      > P2-S03-T01 — CA-P2-S03-01 | Roteiro da task na SPEC.
- [ ] Implementar adaptador e webhook da Meta Cloud API (entrada, saída, situação, janela e modelos). @"técnico de integração" #projeto !21/10/2026
      > P2-S03-T02 — CA-P2-S03-02, CA-P2-S03-03, CA-P2-S03-05, CA-P2-S03-07 | Roteiro da task na SPEC.
- [ ] Implementar adaptador e webhook da Z-API (entrada, saída, situação e desconexão). @"técnico de integração" #projeto !21/10/2026
      > P2-S03-T03 — CA-P2-S03-02, CA-P2-S03-03, CA-P2-S03-05, CA-P2-S03-06 | Roteiro da task na SPEC.
- [ ] Executar a matriz de contrato dos dois provedores e demonstrar envio e recebimento reais. @"QA + owner" #projeto !22/10/2026
      > P2-S03-T04 — CA-P2-S03-02, CA-P2-S03-03, CA-P2-S03-04, CA-P2-S03-05, CA-P2-S03-06, CA-P2-S03-07, CA-P2-S03-08 | Roteiro da task na SPEC.
- [ ] Criar as tabelas de conversa com isolamento por clínica e o consumidor da fila de entrada. @"técnico de banco + integração" #projeto !22/10/2026
      > P2-S04-T01 — CA-P2-S04-01, CA-P2-S04-02, CA-P2-S04-07 | Roteiro da task na SPEC.
- [ ] Construir a caixa de entrada e a conversa em tempo real, com envio de resposta e situação. @"técnico de frontend" #projeto !23/10/2026
      > P2-S04-T02 — CA-P2-S04-01, CA-P2-S04-04 | Roteiro da task na SPEC.
- [ ] Ligar a identificação do contato, a saída da lista por palavra-chave e os anexos privados. @"técnico de integração" #projeto !26/10/2026
      > P2-S04-T03 — CA-P2-S04-03, CA-P2-S04-06, CA-P2-S04-08 | Roteiro da task na SPEC.
- [ ] Executar a matriz de isolamento e repetição e demonstrar a caixa de entrada em duas clínicas. @"QA + reception" #projeto !26/10/2026
      > P2-S04-T04 — CA-P2-S04-02, CA-P2-S04-05, CA-P2-S04-07 | Roteiro da task na SPEC.
- [ ] Criar tickets, expediente, presença e política de distribuição, com o console de filas, horários e prazos. @"técnico de banco + frontend" #projeto !27/10/2026
      > P2-S05-T01 — CA-P2-S05-01, CA-P2-S05-07 | Roteiro da task na SPEC.
- [ ] Implementar o motor de distribuição, reoferta, escalonamento e alertas de prazo. @"técnico de integração" #projeto !27/10/2026
      > P2-S05-T02 — CA-P2-S05-01, CA-P2-S05-03, CA-P2-S05-04, CA-P2-S05-05, CA-P2-S05-06 | Roteiro da task na SPEC.
- [ ] Construir a tela do ticket (aceitar, transferir, devolver, escalar, resolver), a presença e a visão do gestor. @"técnico de frontend" #projeto !28/10/2026
      > P2-S05-T03 — CA-P2-S05-02, CA-P2-S05-08 | Roteiro da task na SPEC.
- [ ] Executar a matriz de contingência e isolamento e demonstrar com o gestor. @"QA + manager" #projeto !28/10/2026
      > P2-S05-T04 — CA-P2-S05-03, CA-P2-S05-04, CA-P2-S05-05, CA-P2-S05-06, CA-P2-S05-07 | Roteiro da task na SPEC.
- [ ] Criar o ambiente de execução de agentes, as tabelas de registro e o guardião determinístico. @"técnico de IA" #projeto !29/10/2026
      > P2-S06-T01 — CA-P2-S06-02, CA-P2-S06-06 | Roteiro da task na SPEC.
- [ ] Implementar a triagem de intenção e a resposta com conteúdo aprovado. @"técnico de IA" #projeto !29/10/2026
      > P2-S06-T02 — CA-P2-S06-01, CA-P2-S06-03, CA-P2-S06-07 | Roteiro da task na SPEC.
- [ ] Construir o console de conhecimento, modelos de mensagem, rotas e interruptores por clínica. @"técnico de frontend" #projeto !30/10/2026
      > P2-S06-T03 — CA-P2-S06-03, CA-P2-S06-05 | Roteiro da task na SPEC.
- [ ] Executar a matriz das 20 mensagens, as falhas de IA e a demonstração. @"QA + manager" #projeto !30/10/2026
      > P2-S06-T04 — CA-P2-S06-01, CA-P2-S06-02, CA-P2-S06-04, CA-P2-S06-05, CA-P2-S06-07, CA-P2-S06-08 | Roteiro da task na SPEC.
- [ ] Implementar a função de sugestão com evidências e o registro de uso. @"técnico de IA" #projeto !03/11/2026
      > P2-S07-T01 — CA-P2-S07-01, CA-P2-S07-03 | Roteiro da task na SPEC.
- [ ] Construir o painel do copiloto no ticket com usar, editar, descartar e ver evidências. @"técnico de frontend" #projeto !03/11/2026
      > P2-S07-T02 — CA-P2-S07-01, CA-P2-S07-02, CA-P2-S07-04 | Roteiro da task na SPEC.
- [ ] Construir o console de agentes e prompts com rascunho, teste, publicação, volta de versão e herança. @"técnico de frontend + IA" #projeto !04/11/2026
      > P2-S07-T03 — CA-P2-S07-05, CA-P2-S07-06, CA-P2-S07-07 | Roteiro da task na SPEC.
- [ ] Executar a matriz do copiloto e a demonstração ponta a ponta da fase 2 com as atendentes. @"QA + atendentes" #projeto !04/11/2026
      > P2-S07-T04 — CA-P2-S07-02, CA-P2-S07-03, CA-P2-S07-04, CA-P2-S07-06 | Roteiro da task na SPEC.
