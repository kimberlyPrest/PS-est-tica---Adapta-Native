# Mapa de dados — Clínica Experts → CRM PS Estética

**Verificação ao vivo:** 13/10/2026, 55 chamadas de leitura (`GET`) com o token do cliente. Nenhuma gravação foi feita.
**Uso:** referência das SPECs das fases 2 a 5 (citada como "mapa de dados"). Complementa a seção 12 do escopo definitivo (`02-Escopo-Definitivo/02-Escopo-Definitivo.md`); onde houver diferença, vale o que está aqui, por ser mais recente.
**Privacidade:** este documento traz só contagens e formatos. Nenhum nome, telefone ou documento de paciente está registrado.

## 1. Conexão

| Tema | Fato verificado | Consequência |
|---|---|---|
| Base | `https://api.clinicaexperts.com.br/api/v1`. O host `app.clinicaexperts.com.br/api/v1` responde igual e divide o mesmo limite. | Usar `api.`; configurar `EXPERT_API_BASE_URL`. |
| Autenticação | `Authorization: Bearer <token>`. Um único token cobre as duas unidades (Espinheiro e Boa Viagem). | A conexão é da organização, não de cada clínica. |
| Limite | Cabeçalhos `x-ratelimit-limit: 120` e `x-ratelimit-remaining` em toda resposta. A página de códigos de retorno da documentação fala em 100 por minuto; o cabeçalho real diz 120. | Limite interno de 90 por minuto, guiado pelo cabeçalho. |
| Borda | Cliente HTTP com assinatura não reconhecida recebe `403` da Cloudflare (código 1010) **antes** da validação do token. Ocorreu com a biblioteca padrão do Python; `curl` passou. | O cliente das Edge Functions precisa enviar `User-Agent` próprio, e isso precisa ser testado a partir da função. Tratar como `bloqueio_de_borda`, sem repetir. |
| Paginação | `page` + `per_page`, máximo 1000 (5000 devolve `422`). `meta` traz `of` (total) e `last_page`. | Carga de pacientes em 3 chamadas; um mês de agenda em 1. |
| Datas | Filtros de intervalo exigem ISO 8601 com fuso (`2026-09-01T00:00:00-03:00`); sem fuso devolve `422`. As respostas misturam `-03:00` (pacientes, agendamentos, vendas) e UTC com `Z` (profissionais, salas, emissão de cobrança). | Normalizar tudo para `timestamptz`. |
| Valores | Inteiros em centavos. | Guardar como inteiro. |

### Formatos de erro

| Situação | Status | Corpo |
|---|---|---|
| Validação | 422 | `{"error":{"code":"API0422","title":"Invalid data","user_message":...,"fields":{campo:[mensagens]}}}` |
| Não encontrado | 404 | `{"error":{"code":"API0011","title":"Patient not found",...}}` |
| Módulo desabilitado | 403 | `{"error":"Feature crm is not enabled for this clinic"}` (texto simples) |
| Limite | 429 | `{"success":false,"message":"Too Many Requests"}` |
| Bloqueio de borda | 403 | corpo da Cloudflare com `cloudflare_error: true` e `error_code: 1010` |

## 2. O que puxar, para onde e com que frequência

| Recurso | Endpoint | Campos que entram no CRM | Destino | Frequência | SPEC |
|---|---|---|---|---|---|
| Paciente (busca) | `GET /patients?phone=` | `uuid`, `name`, `phone`, `date_birth`, `active` | `expert_patients_cache`, `external_patient_links` | sob demanda, com validade | P2-S02 |
| Paciente (detalhe) | `GET /patients/{uuid}` | os mesmos | idem | sob demanda | P2-S02 |
| Profissionais | `GET /professionals` | `uuid`, `name`, `active` | `expert_professionals_cache` | diária | P3-S01 |
| Procedimentos | `GET /procedures` | `id`, `name`, `duration`, `price`, `active`, `professionals[]` | `expert_procedures_cache` | diária | P3-S01 |
| Salas | `GET /rooms` | `id`, `name`, `active` | `expert_rooms_cache` | diária | P3-S01 |
| Agenda | `GET /bookings?starts_at=&ends_at=` | `uuid`, `starts_at`, `ends_at`, `status`, `source`, `patient.uuid`, `professional.uuid`, `procedures[].id`, `rooms[].id`, `updated_at` | `appointments_mirror` | 12 meses na carga; depois de 7 dias atrás a 60 à frente, a cada 15 min | P3-S01 |
| Agenda do paciente | `GET /bookings?patient=<uuid>&starts_at=&ends_at=` | os mesmos | consulta direta | sob demanda | P3-S04 |
| Horários livres | `GET /available-hours?professional_uuid=&date=` | lista de `"HH:MM"` | não é guardado (memória de 2 min) | sob demanda | P3-S04 |
| Vendas | `GET /sales?starts_at=&ends_at=` | `uuid`, `type`, `status`, `sale_date`, `buyer.uuid`, `seller.uuid`, `final_amount`, `discount_amount`, `procedures[].name`, `generate_credits` | `sales_mirror` | 12 meses na carga; depois últimos 7 dias, a cada hora | P3-S01 |
| Eventos | painel do Clínica Experts → `webhook-clinica-experts` | aviso + leitura do recurso por `uuid` | `webhook_receipts` → espelhos | em tempo real | P4-S01 |
| Bloqueios de agenda | `GET /calendar-locks` | — | não é puxado: `/available-hours` já considera | — | — |

### O que não entra no CRM

| Dado | Motivo |
|---|---|
| CPF, RG, endereço, estado civil, profissão, anotações do paciente | minimização (LGPD); a API devolve, o sistema descarta antes de gravar e nunca registra em log |
| Base integral de pacientes | só entram os que aparecem em busca, agendamento ou venda |
| Parcelas, cobranças, contas e categorias financeiras | fora do programa; além disso a situação das parcelas não é confiável (ver seção 4) |
| Convênios, combos, eventos e lembretes de calendário | vazios na clínica (0 registros) |
| Dados de comissão e de conselho dos profissionais | sem uso no processo comercial |

## 3. Comportamentos que mudam o desenho

1. **Filtro de telefone casa por trecho de dígitos.** O telefone é guardado como `+55DDDNÚMERO` em 2.120 de 2.181 cadastros. Funcionam: E.164 completo, `55DDD...`, `DDD...`, o número sem DDD e os últimos 8 dígitos. Não funcionam: formato com máscara `(81) 9...` e o número sem o 9º dígito. Por isso a busca é em duas etapas (P2-S02).
2. **Telefone não identifica uma pessoa.** 60 telefones pertencem a mais de um paciente (130 cadastros; até 4 no mesmo número). 32 pacientes não têm telefone; 29 têm comprimento fora do padrão.
3. **A unidade não vem no agendamento.** Há duas salas (Espinheiro `15373`, Boa Viagem `15376`), mas só 378 dos 8.494 agendamentos de 12 meses têm sala. A clínica do agendamento precisa de regra própria: sala, depois mapeamento do profissional, depois fila de pendentes (P3-S01).
4. **Vendedor é sempre um profissional.** Em 144 vendas conferidas, todo `seller.uuid` existe em `/professionals` e todo `buyer.uuid` existe em `/patients`. O mapeamento vendedor → usuário do CRM usa o identificador do profissional.
5. **Linha de venda não tem identificador de procedimento**, só o nome, e inclui produtos que não estão no catálogo de procedimentos (por exemplo, cintas). No agendamento, `procedures[].id` é o identificador do catálogo (100% de correspondência).
6. **Não há filtro por data de alteração em pacientes**, e `updated_at` é igual a `created_at` em todos os 2.181 cadastros. Atualização incremental de paciente não é possível pela lista; depende dos eventos (P4-S01) e da leitura sob demanda.
7. **Origem do lead não existe na fonte.** `origin` está preenchido em 1 de 2.181 pacientes. A origem precisa ser capturada no CRM (P3-S02).
8. **Falta não é registrada.** Em 12 meses: 5.612 realizados, 2.542 cancelados, 65 agendados, 15 confirmados, 1 "não compareceu" e 0 "reagendado". O comparecimento não pode ser inferido da API (P3-S06).
9. **Catálogo incompleto para agenda.** Dos 112 procedimentos, 28 têm duração zero, 19 têm preço zero e só 5 têm profissional vinculado. A relação procedimento → profissionais é mantida no CRM (P3-S04).
10. **Módulo de CRM desabilitado.** `/crm/pipelines`, `/crm/opportunities`, `/crm/conversions` e `/crm/conversion-metrics` devolvem `403`. Reconfirmado em 13/10/2026; o GATE-17 segue pelo caminho do CRM próprio.
11. **Formatos irregulares.** `documents` vem como objeto (`{"CPF":...}`) em 1.870 cadastros e como lista vazia em 311; `tags` é texto; `notifications` usa a chave `whatsapp_lite`.
12. **Sem chave de idempotência nas gravações.** A proteção contra duplicidade é local: conferir antes de repetir (P4-S02).
13. **Eventos sem contrato documentado.** A documentação lista 27 eventos e diz que o endereço é cadastrado no painel; não descreve o corpo nem a autenticação (P4-S01, GATE-13).

## 4. Volumes e linha de base aproximada

| Indicador | Valor | Observação |
|---|---|---|
| Pacientes | 2.181 (605 ativos, 1.576 inativos) | eram 2.161 em 29/09: cerca de 20 novos em duas semanas |
| Novos cadastros por mês | 20 a 101 nos últimos 12 meses; 73 em set/2026 | 63 dos 73 de setembro tiveram agendamento no mês |
| Profissionais | 15 (12 ativos); 7 com agenda em set/2026 | 10 aparecem como vendedores no mês |
| Procedimentos | 112 (105 ativos) | |
| Agendamentos | 8.494 em 12 meses; 788 em set/2026 | 261 pacientes distintos em setembro |
| Cancelamento | 30% em 12 meses; 29% em set/2026 | |
| Antecedência do agendamento | mediana de 6 dias; 90% em até 16 dias | |
| Vendas | 1.307 em 12 meses; 112 em set/2026 | 90 compradores distintos em setembro |
| Faturamento registrado | R$ 341.231,78 em set/2026; ticket médio de R$ 3.046,71 | campo de desconto nunca usado |
| Forma de pagamento | PIX e máquina de cartão; 64% dos pagamentos em parcela única (set/2026) | |
| Avaliações (set/2026) | 90 agendadas; 51 realizadas; 38 canceladas (42%) | procedimentos com "avaliação" no nome |
| Avaliação → venda | 21 dos 51 avaliados compraram até 13/10 (41%); 14 no mesmo dia | cerca de 30 avaliados por mês sem fechamento |
| Parcelas (set/2026) | 147; 144 como "atrasada" | o módulo financeiro não reflete a realidade; não usar |

Os percentuais são aproximados: a avaliação foi identificada pelo nome do procedimento e a venda pelo mesmo paciente em setembro e outubro. A P3-S06 troca o nome pelo identificador e a P3-S07 confere os números antes de publicar.

## 5. Pendências que dependem do cliente ou do suporte

| Tema | Pergunta | Quem responde | Bloqueia |
|---|---|---|---|
| Unidade do agendamento | Cada profissional atende em uma só unidade? Qual? | Felipe | P3-S01 |
| Avaliações | Quais procedimentos contam como avaliação (há duas grafias de "Avaliação capilar")? | Felipe | P3-S06 |
| Eventos | Qual é a autenticação e o formato do corpo dos eventos? | suporte do Clínica Experts | P4-S01 |
| Borda | O bloqueio por assinatura pode ser liberado para o cliente das Edge Functions? | suporte do Clínica Experts | P2-S02 |
| Token de gravação | É possível emitir token separado só para as gravações permitidas? | suporte do Clínica Experts | P4-S02 |
| Módulo CRM | A clínica vai habilitar o módulo? Se sim, vira SPEC nova. | Felipe | — |
| Falta | A clínica passará a marcar "não compareceu" no Clínica Experts? | Felipe | P3-S06 |
