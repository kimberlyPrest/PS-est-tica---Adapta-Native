-- P2-S05-T02: RPCs do motor de distribuição (aceite concorrente, transferir,
-- devolver, escalar, resolver, voltar à automação) + helper de elegibilidade.
-- Regras: RN-02 (concorrência via version), RN-03 (estratégias), RN-04 (nunca
-- sai da clínica), RN-05 (cadeia), RN-07 (pausa automação), RN-08 (resolver
-- exige código + próxima ação, salvo spam).
-- (v2: fila_elegiveis sem filtro de papéis — owner também é elegível, clínicas pequenas)

-- ===== Elegíveis da fila (nunca de outra clínica — RN-04) =====
CREATE OR REPLACE FUNCTION public.fila_elegiveis(p_queue uuid)
RETURNS TABLE (user_id uuid, active_load int, last_received timestamptz, tem_skills boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  WITH q AS (
    SELECT q.clinic_id, q.team_id, p.skills AS pol_skills, p.strategy
    FROM public.ticket_queues q
    LEFT JOIN LATERAL (
      SELECT skills, strategy FROM public.routing_policies
      WHERE queue_id = q.id AND status = 'published'
      ORDER BY version DESC LIMIT 1
    ) p ON true
    WHERE q.id = p_queue
  )
  SELECT tm.user_id,
    COALESCE(ap.active_load, 0) AS active_load,
    COALESCE(ap.last_seen_at, to_timestamp(0)) AS last_received,
    (COALESCE(q.pol_skills, '{}') = '{}' OR COALESCE(tm.skills, '{}') @> COALESCE(q.pol_skills, '{}')) AS tem_skills
  FROM q
  JOIN public.team_members tm ON tm.team_id = q.team_id AND tm.active
  JOIN public.memberships m ON m.user_id = tm.user_id AND m.clinic_id = q.clinic_id AND m.active
  LEFT JOIN public.attendant_presence ap ON ap.user_id = tm.user_id AND ap.clinic_id = q.clinic_id
  WHERE COALESCE(ap.state, 'offline') = 'online'
    AND COALESCE(ap.active_load, 0) < tm.max_concurrent
    AND NOT EXISTS (
      SELECT 1 FROM public.user_shifts us
      WHERE us.user_id = tm.user_id AND us.clinic_id = q.clinic_id
        AND us.status = 'absent' AND now() BETWEEN us.starts_at AND us.ends_at
    );
$$;

-- ===== Aceite (concorrência otimista — RN-02) =====
CREATE OR REPLACE FUNCTION public.accept_ticket(p_ticket uuid, p_version int) RETURNS json
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid(); v_row public.tickets%ROWTYPE;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'nao_autenticado' USING ERRCODE='42501'; END IF;
  SELECT * INTO v_row FROM public.tickets WHERE id = p_ticket;
  IF v_row.id IS NULL THEN RAISE EXCEPTION 'ticket_inexistente' USING ERRCODE='22023'; END IF;
  IF NOT public.is_clinic_member(v_row.clinic_id) THEN RAISE EXCEPTION 'sem_vinculo' USING ERRCODE='42501'; END IF;
  -- oferta atual é minha OU fila manual (qualquer membro da equipe)
  IF v_row.offered_to IS NOT NULL AND v_row.offered_to <> v_user THEN
    RAISE EXCEPTION 'oferta_de_outro' USING ERRCODE='42501';
  END IF;
  UPDATE public.tickets SET
    status = 'assigned', assigned_to = v_user, offered_to = NULL, offer_expires_at = NULL,
    accepted_at = now(), version = version + 1, updated_at = now()
  WHERE id = p_ticket AND version = p_version AND status IN ('offered','queued')
  RETURNING * INTO v_row;
  IF v_row.id IS NULL THEN
    RETURN json_build_object('ok', false, 'code', 'conflito', 'message', 'Já assumido por outra pessoa');
  END IF;
  INSERT INTO public.ticket_events (organization_id, clinic_id, ticket_id, event_type, from_user_id, to_user_id)
  VALUES (v_row.organization_id, v_row.clinic_id, p_ticket, 'accepted', v_user, v_user);
  -- SLA de aceite: fecha o relógio
  UPDATE public.ticket_sla_events SET acknowledged_at = now() WHERE ticket_id = p_ticket AND metric = 'accept' AND acknowledged_at IS NULL;
  RETURN json_build_object('ok', true, 'ticket_id', p_ticket);
END $$;

-- ===== Transferir (destino na mesma clínica — RN-04) =====
CREATE OR REPLACE FUNCTION public.transfer_ticket(p_ticket uuid, p_to uuid, p_reason text) RETURNS json
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid(); v_row public.tickets%ROWTYPE;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'nao_autenticado' USING ERRCODE='42501'; END IF;
  SELECT * INTO v_row FROM public.tickets WHERE id = p_ticket;
  IF v_row.id IS NULL THEN RAISE EXCEPTION 'ticket_inexistente' USING ERRCODE='22023'; END IF;
  IF NOT public.is_clinic_member(v_row.clinic_id) THEN RAISE EXCEPTION 'sem_vinculo' USING ERRCODE='42501'; END IF;
  IF v_row.assigned_to <> v_user AND NOT public.has_clinic_role(v_row.clinic_id, '{manager,owner,clinic_admin}') THEN
    RAISE EXCEPTION 'papel_insuficiente' USING ERRCODE='42501';
  END IF;
  IF NOT public.is_clinic_member_of(v_row.clinic_id, p_to) THEN
    RAISE EXCEPTION 'destino_fora_da_clinica' USING ERRCODE='42501';
  END IF;
  UPDATE public.tickets SET assigned_to = p_to, status = 'assigned', version = version + 1, updated_at = now()
  WHERE id = p_ticket RETURNING * INTO v_row;
  INSERT INTO public.ticket_events (organization_id, clinic_id, ticket_id, event_type, from_user_id, to_user_id, reason_code)
  VALUES (v_row.organization_id, v_row.clinic_id, p_ticket, 'transferred', v_user, p_to, p_reason);
  RETURN json_build_object('ok', true);
END $$;

-- ===== Devolver à fila =====
CREATE OR REPLACE FUNCTION public.return_ticket(p_ticket uuid, p_reason text) RETURNS json
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid(); v_row public.tickets%ROWTYPE;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'nao_autenticado' USING ERRCODE='42501'; END IF;
  SELECT * INTO v_row FROM public.tickets WHERE id = p_ticket;
  IF v_row.id IS NULL THEN RAISE EXCEPTION 'ticket_inexistente' USING ERRCODE='22023'; END IF;
  IF NOT public.is_clinic_member(v_row.clinic_id) THEN RAISE EXCEPTION 'sem_vinculo' USING ERRCODE='42501'; END IF;
  IF v_row.assigned_to <> v_user AND NOT public.has_clinic_role(v_row.clinic_id, '{manager,owner,clinic_admin}') THEN
    RAISE EXCEPTION 'papel_insuficiente' USING ERRCODE='42501';
  END IF;
  UPDATE public.tickets SET status = 'queued', assigned_to = NULL, offered_to = NULL,
    offer_expires_at = NULL, version = version + 1, updated_at = now()
  WHERE id = p_ticket RETURNING * INTO v_row;
  INSERT INTO public.ticket_events (organization_id, clinic_id, ticket_id, event_type, from_user_id, reason_code)
  VALUES (v_row.organization_id, v_row.clinic_id, p_ticket, 'returned', v_user, p_reason);
  RETURN json_build_object('ok', true);
END $$;

-- ===== Escalar =====
CREATE OR REPLACE FUNCTION public.escalate_ticket(p_ticket uuid, p_reason text) RETURNS json
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid(); v_row public.tickets%ROWTYPE;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'nao_autenticado' USING ERRCODE='42501'; END IF;
  SELECT * INTO v_row FROM public.tickets WHERE id = p_ticket;
  IF v_row.id IS NULL THEN RAISE EXCEPTION 'ticket_inexistente' USING ERRCODE='22023'; END IF;
  IF NOT public.is_clinic_member(v_row.clinic_id) THEN RAISE EXCEPTION 'sem_vinculo' USING ERRCODE='42501'; END IF;
  IF v_row.assigned_to <> v_user AND v_row.offered_to <> v_user
     AND NOT public.has_clinic_role(v_row.clinic_id, '{manager,owner,clinic_admin}') THEN
    RAISE EXCEPTION 'papel_insuficiente' USING ERRCODE='42501';
  END IF;
  UPDATE public.tickets SET status = 'escalated', version = version + 1, updated_at = now()
  WHERE id = p_ticket RETURNING * INTO v_row;
  INSERT INTO public.ticket_events (organization_id, clinic_id, ticket_id, event_type, from_user_id, reason_code)
  VALUES (v_row.organization_id, v_row.clinic_id, p_ticket, 'escalated', v_user, p_reason);
  RETURN json_build_object('ok', true);
END $$;

-- ===== Resolver (RN-08: código obrigatório; next_action_at obrigatório salvo spam) =====
CREATE OR REPLACE FUNCTION public.resolve_ticket(p_ticket uuid, p_code text, p_note text, p_next_action timestamptz DEFAULT NULL) RETURNS json
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid(); v_row public.tickets%ROWTYPE;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'nao_autenticado' USING ERRCODE='42501'; END IF;
  IF p_code NOT IN ('atendido','agendamento_encaminhado','sem_resposta_cliente','spam','transferido_outra_clinica') THEN
    RAISE EXCEPTION 'codigo_invalido' USING ERRCODE='22023';
  END IF;
  SELECT * INTO v_row FROM public.tickets WHERE id = p_ticket;
  IF v_row.id IS NULL THEN RAISE EXCEPTION 'ticket_inexistente' USING ERRCODE='22023'; END IF;
  IF NOT public.is_clinic_member(v_row.clinic_id) THEN RAISE EXCEPTION 'sem_vinculo' USING ERRCODE='42501'; END IF;
  IF v_row.assigned_to <> v_user AND NOT public.has_clinic_role(v_row.clinic_id, '{manager,owner,clinic_admin}') THEN
    RAISE EXCEPTION 'papel_insuficiente' USING ERRCODE='42501';
  END IF;
  IF p_code <> 'spam' AND p_next_action IS NULL THEN
    RAISE EXCEPTION 'proxima_acao_obrigatoria' USING ERRCODE='22023';
  END IF;
  UPDATE public.tickets SET status = 'resolved', resolved_at = now(), resolution_code = p_code,
    resolution_note = p_note, next_action_at = p_next_action, version = version + 1, updated_at = now()
  WHERE id = p_ticket RETURNING * INTO v_row;
  INSERT INTO public.ticket_events (organization_id, clinic_id, ticket_id, event_type, from_user_id, reason_code, metadata_sanitized)
  VALUES (v_row.organization_id, v_row.clinic_id, p_ticket, 'resolved', v_user, p_code,
    jsonb_build_object('note', COALESCE(p_note,''), 'next_action_at', p_next_action));
  RETURN json_build_object('ok', true);
END $$;

-- ===== Voltar à automação (RN-07) =====
CREATE OR REPLACE FUNCTION public.return_to_automation(p_conversation uuid) RETURNS json
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid(); v_row public.conversations%ROWTYPE; v_ticket uuid;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'nao_autenticado' USING ERRCODE='42501'; END IF;
  SELECT * INTO v_row FROM public.conversations WHERE id = p_conversation;
  IF v_row.id IS NULL THEN RAISE EXCEPTION 'conversa_inexistente' USING ERRCODE='22023'; END IF;
  IF NOT public.is_clinic_member(v_row.clinic_id) THEN RAISE EXCEPTION 'sem_vinculo' USING ERRCODE='42501'; END IF;
  UPDATE public.conversations SET automation_paused = false, updated_at = now() WHERE id = p_conversation;
  -- resolve ticket aberto, se houver
  SELECT id INTO v_ticket FROM public.tickets WHERE conversation_id = p_conversation AND status NOT IN ('resolved','cancelled');
  IF v_ticket IS NOT NULL THEN
    UPDATE public.tickets SET status = 'resolved', resolved_at = now(), resolution_code = 'atendido',
      version = version + 1, updated_at = now() WHERE id = v_ticket;
    INSERT INTO public.ticket_events (organization_id, clinic_id, ticket_id, event_type, from_user_id, reason_code)
    SELECT organization_id, clinic_id, v_ticket, 'resolved', v_user, 'atendido' FROM public.tickets WHERE id = v_ticket;
  END IF;
  RETURN json_build_object('ok', true);
END $$;

-- ===== Helper: membro específico =====
CREATE OR REPLACE FUNCTION public.is_clinic_member_of(p_clinic uuid, p_user uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships m
    WHERE m.clinic_id = p_clinic AND m.user_id = p_user AND m.active = true
  );
$$;

-- ===== Helper: dentro do expediente (business_hours + closures, fuso da clínica) =====
CREATE OR REPLACE FUNCTION public.em_expediente(p_clinic uuid, p_now timestamptz DEFAULT now()) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  WITH tz AS (SELECT COALESCE(timezone, 'America/Recife') AS tz FROM public.clinics WHERE id = p_clinic),
  local AS (
    SELECT (p_now AT TIME ZONE tz.tz) AS agora FROM tz
  )
  SELECT
    NOT EXISTS (SELECT 1 FROM public.business_closures bc WHERE bc.clinic_id = p_clinic AND bc.date = (SELECT (agora)::date FROM local))
    AND EXISTS (
      SELECT 1 FROM public.business_hours bh, local l
      WHERE bh.clinic_id = p_clinic
        AND bh.weekday = EXTRACT(DOW FROM l.agora)::int
        AND l.agora::time >= bh.opens_at AND l.agora::time < bh.closes_at
    );
$$;

-- Grants
GRANT EXECUTE ON FUNCTION public.fila_elegiveis(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_ticket(uuid,int) TO authenticated;
GRANT EXECUTE ON FUNCTION public.transfer_ticket(uuid,uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.return_ticket(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.escalate_ticket(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_ticket(uuid,text,text,timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION public.return_to_automation(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_clinic_member_of(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.em_expediente(uuid,timestamptz) TO authenticated;
