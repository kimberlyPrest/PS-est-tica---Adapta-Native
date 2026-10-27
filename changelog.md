
## 2026-10-27 (3) — P2-S02 FECHADA: token Experts validado + bug `date_birth` corrigido

- Aceite do owner: "teste ok" (19:18). **SPEC P2-S02 COMPLETA (T01–T03)** — fase 2 em **24/28 (86%)**.
- Token do painel (Configurações → Integrações → aba Tokens) gravado pelo owner em Administração → Conexões → PS Recife → "Trocar token"; ref novo no Vault (`11b03308-…`, 48 chars ASCII).
- **Autenticação provada contra a API real**: `GET https://api.clinicaexperts.com.br/api/v1/patients?phone=5581989859531` → **200** com paciente real; idem etapa (b) por últimos 8 dígitos. Doc oficial: `https://clinicaexperts.readme.io` (Bearer).
- **Erro de diagnóstico (registrado para não repetir)**: eu testava via `pg_net` chamando `net.http_get(url, headers)` — a assinatura é `net.http_get(url, params, headers)`, então os cabeçalhos iam no lugar dos query params e o `Authorization` **nunca era enviado**. Toda chamada chegava sem token → 401 idêntico ao de token inventado, o que me levou a concluir erradamente que a chave era inválida. Regra: provar o eco dos headers com `httpbin.org/headers` antes de acusar o provedor.
- **BUG REAL corrigido**: `lerPacienteMinimo` lia `bruto.birth_date`, mas a API devolve **`date_birth`** (doc oficial + resposta real) → `birth_masked` saía `null` em todo candidato. Fix tolerante (`date_birth` primeiro, `birth_date` como fallback). Edge `search-expert-patient` **v10** publicada (v9 intermediária era placeholder — corrigida na mesma sessão).
- Prova ponta a ponta pelo caminho do app (login → Edge): `{"result_class":"um","candidates":[{"name":"Abel Luiz da Silva","birth_masked":"**/**/1965","active":false}]}`.
- Cache `expert_patients_cache`: entradas antigas com `birth_masked: null` marcadas `invalidated=true` para regenerar.
- Código versionado no handoff: `supabase/functions/_shared/providers/clinica-experts.ts`, `expert-search.ts` e `search-expert-patient/index.ts` (commit `defed98`).
