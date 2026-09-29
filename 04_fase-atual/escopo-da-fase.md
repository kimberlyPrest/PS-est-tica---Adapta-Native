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
