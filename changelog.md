## 2026-10-28 (3) — DESVIO registrado na SPEC: P2-S03-T04 depende de um segundo número

- O owner decidiu **registrar desvio formal** em vez de comprar um segundo número agora (28/10, 06:41).
- Motivo técnico, verificado na documentação da Meta: um número registrado no Cloud API **não pode** operar simultaneamente no aplicativo WhatsApp nem em API não oficial, e a exclusão do portfólio é caminho de ida — a ajuda do WhatsApp declara que número excluído não volta para outra conta da plataforma, além de apagar os dados do número. Não existe caminho técnico com um número só.
- Alternativa descartada e por quê: retirar `+55 81 98234-9927` da Meta para liberá-lo à Z-API. Destruiria o canal Meta recém-aceito na T02, apagaria o `phone_number_id` 707487385771432 (ao re-registrar vem outro), perderia o histórico do número e colocaria em risco não oficial o número de pós-procedimento da clínica.
- Documento criado: `06_notas/desvio-p2-s03-t04-segundo-numero.md` — com o problema em linguagem simples, o que já foi provado (CA-P2-S03-06 nas duas partes), o que falta, os três bugs corrigidos e **três opções** para a consultora decidir (aceitar prova por provedor; manter bloqueada; ou emendar a SPEC separando T04a/T04b).
- Recomendação técnica registrada: opção 1 ou 3. A opção 2 trava a fase 2 por item de infraestrutura de baixo custo e prazo incerto.
- **Nada foi alterado** em schema, SPEC, canal de produção ou número. Canal Meta segue `active`, Z-API segue `disabled`.
- Estado do handoff atualizado: `.adapta-cliente/estado-atual.md` → `etapa: desvio_registrado_aguardando_consultora`.
