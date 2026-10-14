# P2-S01 — Base versionada, tipada e protegida no repositório do CRM

**Fase:** 2  
**Status:** liberada para implementação (em paralelo ao fechamento da fase 1)  
**Dono:** responsável técnico (implementação) com aceite do owner  
**Origem no escopo:** §6.1, §6.2, §6.3, §15, §21; dívidas da fase 1 observadas no repositório `crm-est-tica` (commit f19b12a, 13/10/2026)  
**Degrau da solução:** reuso — banco e funções da fase 1 já existem no Supabase; esta SPEC só os traz para o repositório e fecha lacunas de segurança.

## Contexto e decisões fechadas

- O repositório do CRM tem uma única migration (`profiles` + usuário semeado) e nenhuma Edge Function; as 16 tasks da fase 1 foram aceitas contra o banco real, mas o código do backend não está versionado junto do app.
- A migration versionada cria um usuário com e-mail real e senha em texto claro, em repositório público.
- `/signup` é uma rota pública; `profiles.role` nasce como `admin` e a policy de leitura de `profiles` é `USING (true)` na migration versionada (o estado real do banco precisa ser conferido).
- `src/lib/supabase/types.ts` não contém tabelas; as chamadas usam `as any`. `npm test` não executa nada.
- O Dashboard exibe números fixos ("8 agendamentos", "142 clientes", "98% de fidelização") como se fossem reais.
- O `/admin` cobre clínicas, usuários, vínculos e equipes; não há tela de conexões (P1-S04) nem de busca de paciente (P1-S05) — esses fluxos foram aceitos por roteiro, fora do app.
- **Aprovações:** GATE-01 a GATE-17 confirmados pela responsável em 29/09/2026 (`02-Escopo-Definitivo/decisoes-e-aprovacoes.md`). Os valores concretos de cada gate são entradas desta SPEC, carregados dos registros do cliente.

## Resultado observável

Quem tem acesso clona o repositório, recria o banco da fase 1 do zero com um comando e roda a suíte de testes; o app não tem cadastro aberto, senha em código nem número fictício em tela.

## Limites e dependências

- **Inclui:** versionar migrations e Edge Functions da fase 1; gerar tipos; remover seed com senha e trocar a credencial exposta; segundo fator para proprietário e administradores; fechar o cadastro aberto (acesso só por convite); guarda de rota por sessão, vínculo e papel; seletor de clínica; estado vazio no Dashboard; suíte de testes e CI com varredura de segredos.
- **Fora de escopo:** funcionalidade nova de produto; mudança de schema que não seja correção aditiva; redesenho visual.
- **Entradas e pré-condições:** acesso ao projeto Supabase `psestetica`; artefatos SQL/TS da fase 1 (`artifacts/` e `scripts/` do agente do cliente); repositório do CRM.
- **Saídas/artefatos:** `supabase/migrations/*`, `supabase/functions/*`, `types.ts` gerado, testes, workflow de CI, relatório de diff vazio.
- **Dependências e responsáveis:** fase 1 aceita (16/16). Felipe fornece acesso ao projeto; técnico executa; owner aceita.
- **Risco e plano B:** migration importada divergir do banco real (já ocorreu na PK de `memberships`) — o diff contra o banco é o juiz; se divergir, vira DÚVIDA para a consultora, nunca correção silenciosa.
- **Rollback ou reversão:** mudanças são aditivas e em repositório; reverter o commit restaura o estado anterior sem tocar dados. A troca de senha do usuário semeado não é revertida.
- **Segurança e privacidade:** segredos só no servidor (Vault); isolamento por organização e clínica no banco; identificador de correlação; logs sem dado pessoal nem token; testes com dados sintéticos.

## Dados e integrações

| Origem/destino | Fonte de verdade | Contrato |
|---|---|---|
| Banco real `psestetica` → `supabase/migrations` | banco real | catálogo de tabelas, constraints, policies, funções e RPCs da fase 1 |
| Funções `admin-*` e `search-expert-patient` → `supabase/functions` | funções em produção | mesmo comportamento aceito pelos runners da fase 1 |
| `auth.users` semeado | Supabase Auth | credencial trocada; migration deixa de conter senha e e-mail |

## Contrato técnico detalhado

Segue o `00-CONTRATO-COMUM-FASE-2.md`.

### Repositórios envolvidos

| Repositório | Papel nesta SPEC |
|---|---|
| `crm-est-tica` (app) | passa a conter `supabase/migrations`, `supabase/functions`, tipos gerados, testes e CI |
| `artifacts/` e `scripts/` do agente da fase 1 | origem dos SQL e TS já aceitos (ex.: `p1_s05_t02_search_cache.sql`, `p1_s05_t02_edge_search_expert_patient.ts`) |

### Estrutura final do repositório

```
supabase/
  config.toml
  migrations/
    20260929135430_create_profiles_and_seed.sql      (existente — será neutralizada, ver abaixo)
    2026..._p1_s01_t01_tenancy_core.sql               (importada do banco real)
    2026..._p1_s01_t02_*.sql ... p1_s05_t02_search_cache.sql
    2026..._p2_s01_hardening.sql                      (nova)
  functions/
    _shared/  admin-save-integration-config/  admin-test-connection/  search-expert-patient/  ...
scripts/           runners PGlite da fase 1 + novos
src/lib/supabase/types.ts   (gerado)
.github/workflows/ci.yml
```

### Importação do banco real

1. Listar migrations aplicadas: `supabase migration list --linked`. A ordem do repositório deve ser **a mesma** do histórico remoto (mesmos timestamps de versão).
2. Para cada migration aplicada que não está no repositório, recuperar o SQL do artefato aceito na fase 1. Se o artefato não existir, gerar com `supabase db dump --linked --schema public` **só para comparação** e registrar DÚVIDA — não inventar SQL.
3. Prova: em banco local vazio, `supabase db reset` e depois `supabase db diff --linked --schema public` deve sair vazio. Também comparar `pg_policies`, `pg_proc` (nome, argumentos, `security definer`) e `pg_constraint`.

### Seed com senha

- A migration `20260929135430_create_profiles_and_seed.sql` já foi aplicada; **não editar o arquivo** de forma que mude o resultado no banco. Criar migration nova `p2_s01_hardening` que não recria usuário.
- Para tirar a senha da árvore atual: substituir o bloco `DO $$ ... $$` de seed por um comentário `-- seed removido em P2-S01; usuário criado por convite` **e** registrar em `06_notas/` que o arquivo foi alterado após aplicado (o banco não muda, porque a migration já consta como aplicada). O teste de reset em banco vazio passa a criar zero usuários.
- Trocar a senha do usuário semeado pelo fluxo de redefinição (P1-S02) e registrar só a data, nunca a senha.
- Histórico do Git: a senha continua no commit antigo do repositório público. A decisão (reescrever o histórico ou aceitar com a senha já trocada) é do owner e fica registrada; esta SPEC não reescreve histórico sem essa decisão.

### Migration `p2_s01_hardening`

| Item | Mudança |
|---|---|
| `profiles` select | trocar `USING (true)` por: próprio perfil **ou** perfis que compartilham alguma organização com o usuário |
| `profiles.role` | deixa de ser usada pelo app; coluna mantida (não destrutivo); comentário `deprecated: usar memberships` |
| `handle_new_user()` | cria `profiles` com `role` nulo; nunca concede papel |
| Cadastro aberto | desligar "Allow new users to sign up" no Auth do projeto; manter convite (`admin_invite_user`) |
| Segundo fator | ativar TOTP no Auth; o app exige `aal2` para usuários com papel `owner` ou `clinic_admin` |

### Telas

| Rota | Comportamento |
|---|---|
| `/` | login; após entrar, vai para `/inicio` |
| `/signup` | removida; acesso só por convite |
| `/inicio` | mostra clínicas do usuário e atalhos; números só de consulta real (nenhum valor fixo) ou estado vazio "ainda sem dados" |
| qualquer rota protegida | sem sessão → `/`; sem vínculo → tela "Você ainda não tem acesso a nenhuma clínica"; papel insuficiente → "Acesso restrito" |
| `/admin/*` | `owner` e `clinic_admin` (com segundo fator) |

Componentes novos: `AppShell` (menu lateral + topo), `ClinicSelector`, `RequireAuth`, `RequireRole`, `EmptyState`, `ErrorState` (mostra `correlation_id`). O seletor guarda a clínica escolhida em `localStorage` por conveniência, e o servidor valida sempre.

### CI (`.github/workflows/ci.yml`)

| Passo | Comando | Falha quando |
|---|---|---|
| Tipos e lint | `npm run build` e `npm run lint` | erro de tipo ou lint |
| Testes de tela | `npx vitest run` | qualquer teste falha |
| Banco | `supabase db start` + `supabase db reset` + runners `scripts/test_*.js` | migration ou runner falha |
| Funções | `deno test supabase/functions` | qualquer teste falha |
| Segredos | `gitleaks detect --no-git` na árvore atual | qualquer ocorrência |

`npm test` passa a chamar `vitest run` (o script atual que só imprime texto é substituído).

## Regras de negócio

| ID | Regra |
|---|---|
| RN-P2-S01-01 | O estado físico do banco prevalece sobre o texto: a migration versionada deve reproduzir o banco real, e o diff precisa ser vazio. |
| RN-P2-S01-02 | Ninguém nasce com papel: acesso existe só por `memberships`; `profiles.role` deixa de ser fonte de permissão. |
| RN-P2-S01-03 | Nenhuma tela mostra número que não venha do banco; sem dado, mostra estado vazio. |
| RN-P2-S01-04 | Segredo, senha ou e-mail pessoal nunca entram em migration, código, teste ou evidência. |

## Fluxo e regras

1. Extrair do banco real o schema e as funções da fase 1 e gravar como migrations ordenadas.
2. Recriar em banco vazio e comparar com o banco real até o diff ficar vazio.
3. Retirar o seed com senha, trocar a senha do usuário afetado e fechar o cadastro público.
4. Gerar tipos, remover `as any`, aplicar guarda de rota e seletor de clínica, limpar o Dashboard.
5. Ligar testes e varredura de segredos ao CI e demonstrar clone → reset → testes verdes.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | clone limpo + banco vazio | um comando recria o banco da fase 1 e os testes passam | registrar diff e saída do CI |
| Limite | usuário autenticado sem vínculo, ou tentativa de cadastro sem convite | tela "sem acesso"; nenhuma linha operacional pela API direta | auditar tentativa; nenhum papel é atribuído |
| Falha | migration importada diverge do banco real | CI falha com o diff; nada é aplicado em produção | abrir DÚVIDA para a consultora e corrigir por migration aditiva |

## Checklist de execução

- [ ] Acesso ao projeto Supabase e aos artefatos da fase 1 conferido.
- [ ] Diff contra o banco real vazio e anexado.
- [ ] Senha do usuário semeado trocada e varredura de segredos sem ocorrências.
- [ ] Rotas protegidas e Dashboard sem valores fixos conferidos em tela.
- [ ] CI verde anexado e owner informado da troca de credencial.

## Critérios de aceite

- [ ] **CA-P2-S01-01:** Em banco vazio, um comando aplica todas as migrations e o diff contra o projeto real é vazio.
- [ ] **CA-P2-S01-02:** As Edge Functions da fase 1 estão no repositório e o deploy a partir dele mantém verdes os runners aceitos na fase 1.
- [ ] **CA-P2-S01-03:** A varredura de segredos na árvore atual retorna zero ocorrências (senha, token, e-mail pessoal), a senha do usuário semeado foi trocada, e a decisão sobre reescrever o histórico público — onde a senha permanece no commit antigo — está registrada.
- [ ] **CA-P2-S01-04:** Usuário sem convite não obtém acesso, e usuário sem vínculo lê zero linhas operacionais pela API direta e vê a tela "sem acesso".
- [ ] **CA-P2-S01-05:** `types.ts` gerado contém as tabelas, não resta `as any` em chamada ao Supabase, e `npm test` executa testes reais e falha quando um teste falha.
- [ ] **CA-P2-S01-06:** O Dashboard não exibe valor fixo: sem dado, mostra estado vazio.
- [ ] **CA-P2-S01-07:** Proprietário e administradores só entram com o segundo fator de autenticação.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | reset em banco vazio e teste de leitura sem vínculo | `supabase db reset` + `supabase db diff --linked`; chamada REST como usuário sem membership | diff não vazio e/ou leitura indevida: CA-P2-S01-01 e CA-P2-S01-04 falham | saída versionada do runner ou roteiro, anexada à task |
| GREEN | migrations e funções importadas; cadastro fechado | repetir reset, diff, runners da fase 1 e `npm test` | CA-P2-S01-01 a CA-P2-S01-05 passam | saída versionada do runner ou roteiro, anexada à task |
| REFACTOR/REGRESSÃO | varredura de segredos, guarda de rota e Dashboard | varredura na árvore atual e no histórico (o histórico acusa o commit antigo: decisão registrada); navegação como cada papel; entrada de administrador sem segundo fator | zero segredos na árvore atual; nenhuma rota vaza; CA-P2-S01-06 e CA-P2-S01-07 passam | saída versionada do runner ou roteiro, anexada à task |

**Dados/fixtures:** banco vazio local (PGlite ou Supabase local); usuários sintéticos por papel; nenhum dado real.  
**Caminhos de erro obrigatórios:** diff não vazio; usuário sem vínculo; convite expirado; teste quebrado propositalmente (CI deve falhar).  
**Evidência exigida:** saída do diff, relatório do CI, captura das rotas protegidas e registro da troca de credencial (sem o valor).

## Tasks vinculadas

| ID | Task | Dono | Critério | Recorte da prova | Evidência | Pré-condições | Prazo | Status |
|---|---|---|---|---|---|---|---|---|
| P2-S01-T01 | Importar migrations e funções do banco real para o repositório e provar diff vazio. | técnico de banco | CA-P2-S01-01, CA-P2-S01-02 | RED/GREEN de reset + diff; runners da fase 1 | saída do diff vazio e dos runners | acesso ao projeto Supabase | 14/10/2026 | ☐ Liberada |
| P2-S01-T02 | Remover seed com senha, trocar a credencial exposta, fechar o cadastro aberto e corrigir a leitura de `profiles`. | técnico de segurança | CA-P2-S01-03, CA-P2-S01-04, CA-P2-S01-07 | varredura de segredos; leitura por API como usuário sem vínculo | relatório da varredura e matriz de acesso negado | T01 concluída | 15/10/2026 | ☐ Liberada |
| P2-S01-T03 | Gerar tipos, remover `as any`, criar guarda de rota e seletor de clínica e limpar o Dashboard. | técnico de frontend | CA-P2-S01-04, CA-P2-S01-05, CA-P2-S01-06 | build tipado; navegação por papel; Dashboard sem dado | capturas por papel e saída do build | T01 concluída | 15/10/2026 | ☐ Liberada |
| P2-S01-T04 | Configurar suíte de testes e CI com varredura de segredos e demonstrar clone → reset → testes. | QA | CA-P2-S01-01, CA-P2-S01-03, CA-P2-S01-05 | REFACTOR/REGRESSÃO completa em clone limpo | execução do CI anexada | T02 e T03 concluídas | 16/10/2026 | ☐ Liberada |

## Roteiro das tasks

### P2-S01-T01 — Importar migrations e funções e provar diff vazio
1. Criar branch `p2-s01-base`.
2. Executar `supabase link` com o projeto `psestetica` e listar migrations aplicadas.
3. Copiar os SQL aceitos da fase 1 para `supabase/migrations/` com os timestamps do histórico remoto.
4. Copiar as Edge Functions aceitas para `supabase/functions/`, extraindo código comum para `_shared/`.
5. Rodar reset local + diff contra o projeto; repetir até o diff ficar vazio.
6. Rodar os runners da fase 1 contra o banco local.
**Pronto quando:** diff vazio anexado e runners da fase 1 verdes a partir do repositório.

### P2-S01-T02 — Retirar senha, fechar cadastro, corrigir leitura de perfis, segundo fator
1. Trocar a senha do usuário semeado (fluxo de redefinição) e registrar a data.
2. Criar a migration `p2_s01_hardening` conforme a tabela acima e neutralizar o bloco de seed no arquivo antigo.
3. Desligar o cadastro aberto no Auth e ativar TOTP.
4. Escrever runner: usuário sem vínculo lê 0 linhas em todas as tabelas operacionais; usuário da organização A não lê perfis da organização B; cadastro direto pela API de Auth é recusado.
5. Rodar `gitleaks` na árvore e no histórico; anexar o resultado e a decisão do owner sobre o histórico.
**Pronto quando:** CA-03, CA-04 e CA-07 provados.

### P2-S01-T03 — Tipos, guarda de rota, seletor de clínica e Dashboard limpo
1. `supabase gen types typescript --linked > src/lib/supabase/types.ts`.
2. Remover todo `as any` em chamadas ao Supabase (`use-auth.tsx`, `Admin.tsx`).
3. Criar `AppShell`, `ClinicSelector`, `RequireAuth`, `RequireRole` e as rotas da tabela.
4. Remover `/signup` e os números fixos do Dashboard (renomeado para `/inicio`).
5. Testes de tela: cada papel vê só o menu permitido; usuário sem vínculo vê a tela de sem acesso.
**Pronto quando:** build tipado sem `as any`, testes de tela verdes, capturas por papel.

### P2-S01-T04 — Testes automáticos e CI
1. Configurar Vitest, `deno test` e runners de banco no CI.
2. Configurar `gitleaks` na árvore atual.
3. Quebrar um teste de propósito e mostrar o CI vermelho; consertar e mostrar verde.
4. Demonstrar em clone limpo: `npm ci`, `supabase db reset`, `npm test`.
**Pronto quando:** CI verde anexado e demonstração gravada.

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| — | — | Nenhuma | SPEC inicial |
