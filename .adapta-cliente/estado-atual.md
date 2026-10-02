# Estado atual — Adapta Cliente

- task_id: P1-S02-T01
- champion: Felipe F3 Energy Drink
- spec: 04_fase-atual/01-SPECS/SPEC-P1-S02-auth-rls.md
- etapa: aguardando_teste_humano
- autorizacao_implementacao: confirmada — 2026-10-02 15:52, decisão de método de login (e-mail e senha) via formulário + clique em "Enviar decisão e autorizar implementação" (Felipe, owner)
- teste_humano: pendente
- verificacao_automatica: passou — matriz validada no banco real: signup público rejeitado; convite sem sessão/não-owner/papel inválido/clínica inexistente rejeitados; convite de owner cria usuário+profile+membership; reenvio reativa sem duplicar (bug corrigido); revogação/reativação preservam a linha; 2 memberships owner criadas para Felipe; migrations `p1_s02_t01_auth_invite`, `p1_s02_t01_auth_invite_fix_id`, `p1_s02_t01_invite_idempotent` + corretiva `fix_clinics_org_id_column_rename`
- aprendizado: pendente
- ultima_acao: fluxo de convite implementado e testado no banco real; correções aplicadas (coluna clinics renomeada acidentalmente restaurada; reenvio idempotente)
- proxima_acao: teste humano de Felipe (convite real de um funcionário); após aprovação, concluir T01
- atualizado_em: 2026-10-02T16:40:00-03:00
