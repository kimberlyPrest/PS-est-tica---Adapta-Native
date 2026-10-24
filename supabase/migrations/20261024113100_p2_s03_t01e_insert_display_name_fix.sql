-- ============================================================
-- P2-S03-T01e — fix do INSERT: p_display_name direto (sem variável local)
--   (correção de "column v_display_name does not exist" no cadastro de canal)
-- Causa: a versão T01d usava a variável v_display_name no VALUES do INSERT,
--   mas ela não existia (o parâmetro é p_display_name) — plpgsql resolveu como
--   nome de coluna e o Postgres recusou (42703).
-- Fix: usar p_display_name direto no VALUES. Idempotente; replay seguro.
-- Data: 2026-10-24.
-- ============================================================

CREATE OR REPLACE FUNCTION public.admin_save_channel_account(
  p_clinic_id uuid,
  p_provider text,
  p_phone text,
  p_display_name text,
  p_external_account_id text,
  p_external_business_id text,
  p_token text,
  p_second_secret text
)
RETURNS TABLE (
  channel_account_id uuid,
  created boolean,
  webhook_secret_once text
)
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_org uuid;
  v_phone text;
  v_conn uuid;
  v_conn_existing uuid;
  v_webhook_secret text;
  v_secret_id uuid;
  v_secret_ref text;
  v_channel uuid;
  v_existe uuid;
  v_dono uuid;
  v_status_existente text;
  v_nome_secreto text;
BEGIN
  -- Papel: owner/clinic_admin da clínica.
  SELECT c.organization_id INTO v_org
    FROM public.clinics c WHERE c.id = p_clinic_id AND c.status = 'active';
  IF v_org IS NULL THEN
    RAISE EXCEPTION 'Clinica nao encontrada ou inativa' USING ERRCODE = 'P0004';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.memberships m
     WHERE m.clinic_id = p_clinic_id AND m.user_id = auth.uid()
       AND m.active = true AND m.role IN ('owner','clinic_admin')
  ) THEN
    RAISE EXCEPTION 'Somente owner/clinic_admin administram canais' USING ERRCODE = '42501';
  END IF;

  IF p_provider NOT IN ('meta_cloud','z_api') THEN
    RAISE EXCEPTION 'Provedor invalido' USING ERRCODE = 'P0004';
  END IF;
  IF COALESCE(p_token,'') = '' OR COALESCE(p_external_account_id,'') = '' THEN
    RAISE EXCEPTION 'Token e ID externo sao obrigatorios' USING ERRCODE = 'P0004';
  END IF;

  v_phone := public.normalize_e164(p_phone);

  -- RN-P2-S03-01: número ativo pertence a uma só clínica.
  SELECT id, status INTO v_existe, v_status_existente
    FROM public.channel_accounts
   WHERE phone_e164 = v_phone AND status IN ('active','paused','disconnected')
     AND clinic_id <> p_clinic_id
   LIMIT 1;
  IF v_existe IS NOT NULL THEN
    RAISE EXCEPTION 'Este numero ja esta ativo em outra clinica' USING ERRCODE = 'P0004';
  END IF;

  -- Conexão de credenciais do canal (uma por canal; provider canal_<provider>).
  SELECT id INTO v_conn_existing
    FROM public.integration_connections
   WHERE clinic_id = p_clinic_id
     AND provider = 'canal_' || p_provider
     AND connection_key = p_external_account_id
   LIMIT 1;

  IF v_conn_existing IS NOT NULL THEN
    v_conn := v_conn_existing;
    PERFORM public.admin_save_integration_secret(
      p_clinic_id, 'canal_' || p_provider, p_external_account_id, p_token,
      jsonb_build_object('second_secret_hint', right(coalesce(p_second_secret,''), 4)));
  ELSE
    INSERT INTO public.integration_connections (
      organization_id, clinic_id, provider, connection_key, secret_ref, health_status)
    VALUES (v_org, p_clinic_id, 'canal_' || p_provider, p_external_account_id,
            'vault:pending', 'not_configured')
    RETURNING id INTO v_conn;
    PERFORM public.admin_save_integration_secret(
      p_clinic_id, 'canal_' || p_provider, p_external_account_id, p_token,
      jsonb_build_object('second_secret_hint', right(coalesce(p_second_secret,''), 4)));
  END IF;

  -- Segredo do webhook via API da extensão (INSERT direto em vault.secrets é
  -- negado no Supabase real); description '' (NOT NULL). Devolvido UMA vez.
  v_webhook_secret := public._admin_gen_secret();
  v_nome_secreto := 'webhook_' || p_provider || '_' || p_clinic_id::text || '_' || p_external_account_id;
  SELECT id INTO v_secret_id FROM vault.secrets WHERE name = v_nome_secreto LIMIT 1;
  IF v_secret_id IS NOT NULL THEN
    PERFORM vault.update_secret(v_secret_id, v_webhook_secret, v_nome_secreto, '', NULL);
  ELSE
    v_secret_id := vault.create_secret(v_webhook_secret, v_nome_secreto, '', NULL);
  END IF;
  v_secret_ref := v_secret_id::text;

  -- canal existente desta clínica com o mesmo external_account_id?
  SELECT id INTO v_channel
    FROM public.channel_accounts
   WHERE clinic_id = p_clinic_id AND provider = p_provider
     AND external_account_id = p_external_account_id;

  -- (provider, external_account_id) é global (RN-P2-S03-01).
  SELECT id INTO v_dono
    FROM public.channel_accounts
   WHERE provider = p_provider AND external_account_id = p_external_account_id;
  IF v_dono IS NOT NULL AND v_dono <> v_channel THEN
    RAISE EXCEPTION 'ID externo ja usado por outra clinica' USING ERRCODE = 'P0004';
  END IF;

  IF v_channel IS NOT NULL THEN
    UPDATE public.channel_accounts SET
      phone_e164 = v_phone,
      display_name = p_display_name,
      external_business_id = p_external_business_id,
      integration_connection_id = v_conn,
      webhook_secret_ref = 'vault:' || v_secret_ref,
      updated_at = now()
     WHERE id = v_channel;
  ELSE
    INSERT INTO public.channel_accounts (
      organization_id, clinic_id, provider, phone_e164, display_name,
      external_account_id, external_business_id, integration_connection_id,
      webhook_secret_ref, status)
    VALUES (v_org, p_clinic_id, p_provider, v_phone, p_display_name,
            p_external_account_id, p_external_business_id, v_conn,
            'vault:' || v_secret_ref, 'draft')
    RETURNING id INTO v_channel;
  END IF;

  RETURN QUERY SELECT v_channel, (v_conn_existing IS NULL), v_webhook_secret;
END $fn$;

REVOKE ALL ON FUNCTION public.admin_save_channel_account(uuid,text,text,text,text,text,text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_save_channel_account(uuid,text,text,text,text,text,text,text) TO authenticated;