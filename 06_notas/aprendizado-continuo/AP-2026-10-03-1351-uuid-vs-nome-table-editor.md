# AP-2026-10-03-1351 — Table Editor exige UUID, não nome, em campos FK

- Status: candidato
- Escopo: projeto do cliente
- Task/SPEC: P1-S01-T03 / SPEC-P1-S01-schema-tenancy.md
- Sinal: no teste humano da T03, o champion preencheu o campo `organization_id` com o nome "PS ESTETICA" e recebeu `22P02: invalid input syntax for type uuid`. O roteiro de teste não informava o valor do UUID nem explicava que o campo espera identificador, não texto.
- Evidência: mensagem do champion com o erro 22P02 (2026-10-03 13:47); consulta ao banco confirmando o UUID da organização; sucesso imediato após fornecer o valor ("FUNCIONOU", 13:51).
- Regra reutilizável: em roteiros de teste humano com inserção manual no Table Editor, todo campo FK/UUID deve vir acompanhado do valor exato a colar (ou instrução explícita de usar o seletor), não apenas o nome de exibição.
- Quando aplicar: qualquer task cujo teste humano envolva preencher campos de chave estrangeira manualmente.
- Quando não aplicar: testes via SQL com joins ou telas com seletor automático.
- Confiança: alta — erro reproduzido e corrigido na mesma sessão.
- Privacidade: sem segredo, dado pessoal ou conteúdo bruto.
