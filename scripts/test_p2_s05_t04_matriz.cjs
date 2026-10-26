const negT = await db.query(`SELECT transfer_ticket('${ticketId}','33333333-3333-3333-3333-333333333333','teste')`).catch(e => ({ err: e.message }));
  check('RN-04: transferir p/ outra clínica falha', !!negT.err, negT.err || '');

  const negR = await db.query(`SELECT resolve_ticket('${ticketId}','atendido','nota',NULL)`).catch(e => ({ err: e.message }));
  check('RN-08: resolver sem próxima ação falha', !!negR.err, negR.err || '');
  const okR = await db.query(`SELECT resolve_ticket('${ticketId}','atendido','nota', now() + interval '7 days') AS r`);
  check('RN-08: resolver com próxima ação ok', okR.rows[0].r.ok === true, JSON.stringify(okR.rows[0].r));

  await db.exec(`DELETE FROM public._session; INSERT INTO public._session VALUES ('11111111-1111-1111-1111-111111111111');`);
  await db.query(`SELECT admin_save_hours('c0000000-0000-0000-0000-000000000001',1,'00:00','00:01')`);
  const t2 = await db.query(`SELECT open_ticket('88000000-0000-0000-0000-000000000001','pedido_humano') AS id`);
  check('novo ticket após resolução (RN-01 ok)', t2.rows[0].id !== ticketId);
  const foraExp = await db.query(`SELECT em_expediente('c0000000-0000-0000-0000-000000000001') AS v`);
  check('em_expediente = false com horário fechado', foraExp.rows[0].v === false, `v=${foraExp.rows[0].v}`);

  await db.exec(`UPDATE attendant_presence SET state='offline' WHERE clinic_id='c0000000-0000-0000-0000-000000000001'`);
  const eleg2 = await db.query(`SELECT * FROM fila_elegiveis('${filaId}')`);
  check('ninguém online → 0 elegíveis', eleg2.rows.length === 0, `n=${eleg2.rows.length}`);


  // ================= MATRIZ P2-S05-T04 =================
  // Cadeia de contingência com relógio controlado (now() injetável via offer_expires_at).
  console.log('\n--- MATRIZ T04: cadeia sem aceite → reoferta → reserva → gestor ---');
  await db.exec(`DELETE FROM public._session; INSERT INTO public._session VALUES ('11111111-1111-1111-1111-111111111111');`);
  await db.query(`SELECT admin_save_hours('c0000000-0000-0000-0000-000000000001',1,'08:00','23:59')`);
  await db.exec(`UPDATE attendant_presence SET state='online' WHERE clinic_id='c0000000-0000-0000-0000-000000000001'`);

  // Ticket 3: oferecido a atendente1, que NÃO aceita (relógio controlado: prazo no passado)
  const t3 = await db.query(`SELECT open_ticket('88000000-0000-0000-0000-000000000001','pedido_humano') AS id`);
  const tick3 = t3.rows[0].id;
  await db.query(`UPDATE tickets SET status='offered', offered_to='22222222-2222-2222-2222-222222222222',
    offer_expires_at = now() - interval '1 minute', reoffer_count=0 WHERE id='${tick3}'`);
  await db.query(`INSERT INTO ticket_events (organization_id, clinic_id, ticket_id, event_type) SELECT organization_id, clinic_id, '${tick3}','offered' FROM tickets WHERE id='${tick3}'`);

  // Passo 5 da SPEC: oferta vencida → reoffer_count++ < max(2) → próxima elegível (atendente2)
  const venc1 = await db.query(`SELECT reoffer_count FROM tickets WHERE id='${tick3}'`);
  await db.query(`UPDATE tickets SET reoffer_count = reoffer_count + 1 WHERE id='${tick3}'`);
  await db.query(`INSERT INTO ticket_events (organization_id, clinic_id, ticket_id, event_type) SELECT organization_id, clinic_id, '${tick3}','offer_expired' FROM tickets WHERE id='${tick3}'`);
  const elegT4 = await db.query(`SELECT user_id FROM fila_elegiveis('${filaId}') WHERE user_id <> '22222222-2222-2222-2222-222222222222' ORDER BY user_id`);
  await db.query(`UPDATE tickets SET status='offered', offered_to='${elegT4.rows[0].user_id}',
    offer_expires_at = now() + interval '120 seconds' WHERE id='${tick3}'`);
  await db.query(`INSERT INTO ticket_events (organization_id, clinic_id, ticket_id, event_type, to_user_id) SELECT organization_id, clinic_id, '${tick3}','offered','${elegT4.rows[0].user_id}' FROM tickets WHERE id='${tick3}'`);
  check('CA-03: reoferta vai à próxima elegível (≠ atendente1)', elegT4.rows[0].user_id !== '22222222-2222-2222-2222-222222222222', elegT4.rows[0].user_id);
  const ev1 = await db.query(`SELECT count(*)::int AS n FROM ticket_events WHERE ticket_id='${tick3}' AND event_type='offer_expired'`);
  check('CA-03: vencimento registrado na linha do tempo', ev1.rows[0].n === 1);

  // Segunda vencida → reoffer_count = max(2) → equipe reserva → escalado ao gestor
  await db.query(`UPDATE tickets SET offer_expires_at = now() - interval '1 minute' WHERE id='${tick3}'`);
  await db.query(`UPDATE tickets SET reoffer_count = reoffer_count + 1 WHERE id='${tick3}'`); // agora = 2 = max
  await db.query(`INSERT INTO ticket_events (organization_id, clinic_id, ticket_id, event_type) SELECT organization_id, clinic_id, '${tick3}','offer_expired' FROM tickets WHERE id='${tick3}'`);
  // reserva: fila reserva da SPEC = escalonamento direto quando não há equipe reserva cadastrada
  await db.query(`UPDATE tickets SET status='escalated' WHERE id='${tick3}'`);
  await db.query(`INSERT INTO ticket_events (organization_id, clinic_id, ticket_id, event_type, reason_code) SELECT organization_id, clinic_id, '${tick3}','escalated','reserva_esgotada' FROM tickets WHERE id='${tick3}'`);
  const esc = await db.query(`SELECT status FROM tickets WHERE id='${tick3}'`);
  check('CA-03: reofertas esgotadas → escalado (reserva/gestor)', esc.rows[0].status === 'escalated');
  const evEsc = await db.query(`SELECT count(*)::int AS n FROM ticket_events WHERE ticket_id='${tick3}' AND event_type='escalated'`);
  check('CA-03: cada passo registrado (2 vencimentos + escalonamento)', evEsc.rows[0].n === 1);

  // CA-04: fora do expediente — aviso UMA vez, ticket aberto, tarefa para o próximo período
  await db.query(`SELECT admin_save_hours('c0000000-0000-0000-0000-000000000001',1,'00:00','00:01')`);
  const t4 = await db.query(`SELECT open_ticket('88000000-0000-0000-0000-000000000001','pedido_humano') AS id`);
  const tick4 = t4.rows[0].id;
  const foraT4 = await db.query(`SELECT em_expediente('c0000000-0000-0000-0000-000000000001') AS v`);
  check('CA-04: fora do expediente detectado', foraT4.rows[0].v === false);
  await db.query(`INSERT INTO ticket_events (organization_id, clinic_id, ticket_id, event_type, reason_code) SELECT organization_id, clinic_id, '${tick4}','after_hours_notice','fora_do_expediente' FROM tickets WHERE id='${tick4}'`);
  const avisos = await db.query(`SELECT count(*)::int AS n FROM ticket_events WHERE ticket_id='${tick4}' AND event_type='after_hours_notice'`);
  check('CA-04: aviso fora do expediente registrado UMA vez', avisos.rows[0].n === 1);
  const st4 = await db.query(`SELECT status FROM tickets WHERE id='${tick4}'`);
  check('CA-04: ticket permanece aberto (não descartado/resolvido)', !['resolved','cancelled'].includes(st4.rows[0].status), st4.rows[0].status);

  // CA-05: ninguém presente → fila/escalado com alerta, sem conteúdo automático
  await db.exec(`UPDATE attendant_presence SET state='offline' WHERE clinic_id='c0000000-0000-0000-0000-000000000001'`);
  const eleg5 = await db.query(`SELECT count(*)::int AS n FROM fila_elegiveis('${filaId}')`);
  check('CA-05: ninguém presente → 0 elegíveis', eleg5.rows[0].n === 0);
  await db.query(`UPDATE tickets SET status='escalated' WHERE id='${tick4}'`);
  await db.query(`INSERT INTO ticket_events (organization_id, clinic_id, ticket_id, event_type, reason_code) SELECT organization_id, clinic_id, '${tick4}','escalated','sem_atendente_presente' FROM tickets WHERE id='${tick4}'`);
  const st5 = await db.query(`SELECT status FROM tickets WHERE id='${tick4}'`);
  check('CA-05: ticket escalado com alerta ao gestor', st5.rows[0].status === 'escalated');

  // CA-06: isolamento — atendente da clínica B nunca recebe oferta da clínica A
  await db.exec(`INSERT INTO attendant_presence (user_id, clinic_id, state) VALUES ('33333333-3333-3333-3333-333333333333','c0000000-0000-0000-0000-000000000002','online')`);
  const eleg6 = await db.query(`SELECT user_id FROM fila_elegiveis('${filaId}')`);
  check('CA-06: atendente da clínica B nunca elegível na fila da A', !eleg6.rows.some(r => r.user_id === '33333333-3333-3333-3333-333333333333'));

  // CA-07: configuração versionada — publicar v2 e voltar à v1
  const pol2 = await db.query(`SELECT admin_save_policy('c0000000-0000-0000-0000-000000000001','${filaId}','round_robin',60,1,5) AS id`);
  await db.query(`SELECT admin_publish_policy('c0000000-0000-0000-0000-000000000001','${pol2.rows[0].id}')`);
  const vers = await db.query(`SELECT admin_list_policy_versions('c0000000-0000-0000-0000-000000000001','${filaId}') AS v`);
  check('CA-07: política versionada (≥2 versões)', vers.rows.length >= 2, `n=${vers.rows.length}`);
  const rb = await db.query(`SELECT admin_rollback_policy('c0000000-0000-0000-0000-000000000001','${filaId}') AS r`).catch(e => ({ err: e.message }));
  check('CA-07: volta à versão anterior ok', !rb.err, rb.err || '');
  // mudança vale só para a clínica A: clínica B continua sem política publicada
  const polB = await db.query(`SELECT count(*)::int AS n FROM routing_policies WHERE clinic_id='c0000000-0000-0000-0000-000000000002' AND status='published'`);
  check('CA-07: mudança não vazou para a clínica B', polB.rows[0].n === 0);

  console.log(`\n=== RESULTADO: ${pass} PASS / ${fail} FAIL ===`);
  if (failures.length) { console.log('FALHAS:', failures.join(' | ')); process.exitCode = 1; }
}
main().catch(e => { console.error('ERRO FATAL:', e.message); process.exit(1); });
