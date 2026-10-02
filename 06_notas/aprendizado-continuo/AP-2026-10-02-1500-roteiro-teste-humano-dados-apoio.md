# AP-2026-10-02-1500 — Roteiro de teste humano exige dados de apoio

- Status: candidato
- Escopo: projeto do cliente
- Task/SPEC: P1-S01-T04 / SPEC-P1-S01-schema-tenancy.md
- Sinal: teste humano da T04 falhou não por defeito da entrega, mas porque o roteiro pedia inserção no Table Editor sem que os dados obrigatórios de apoio (organização) existissem — tabelas estavam vazias. Adicionalmente, a query de verificação passada ao cliente usava `connamespace = 'public'` (texto) quando a coluna é OID, causando erro 22P02.
- Evidência: changelog 2026-10-02 (DEBUG task P1-S01-T04); reprodução da falha da query no banco real; prova ao vivo da constraint após inserir dados de apoio.
- Regra reutilizável: antes de passar roteiro de teste humano que envolve inserção via Table Editor em banco vazio, verificar e criar os registros-pai obrigatórios (FKs) e validar a query de verificação executando-a no banco real antes de entregá-la ao champion.
- Quando aplicar: toda task de schema que termine em teste humano com inserção manual de dados.
- Quando não aplicar: testes puramente de leitura em tabelas já populadas.
- Confiança: alta — causa demonstrada ao vivo no banco real.
- Privacidade: sem segredo, dado pessoal ou conteúdo bruto.
