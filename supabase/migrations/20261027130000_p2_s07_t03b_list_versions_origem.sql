-- P2-S07-T03b — Histórico de versões do prompt com a ORIGEM de cada linha
-- (própria da clínica × herdada da organização).
-- Correção do aceite: o set criado na T01 usa agent_key 'AG-01' (não 'AG-14');
-- a tela passou a usar AG-01 e o histórico distingue a linha herdada da própria.
DROP FUNCTION IF EXISTS public.admin_list_prompt_versions(uuid, text);

CREATE OR REPLACE FUNCTION public.admin_list_prompt_versions(p_clinic uuid, p_agent_key text)
RETURNS TABLE (id uuid, version int, status text, sandbox_ok boolean, published_at timestamptz,
               created_by uuid, created_at timestamptz, origem text)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_user uuid := auth.uid();
BEGIN
  IF v_user IS NULL OR NOT public.is_clinic_member(p_clinic) THEN
    RAISE EXCEPTION 'sem_vinculo' USING ERRCODE='42501';
  END IF;
  RETURN QUERY
    SELECT pv.id, pv.version, pv.status, COALESCE((pv.sandbox_result->>'ok')::boolean, false),
           pv.published_at, pv.created_by, pv.created_at,
           CASE WHEN ps.clinic_id IS NULL THEN 'organizacao' ELSE 'propria' END
    FROM public.prompt_versions pv
    JOIN public.prompt_sets ps ON ps.id = pv.prompt_set_id
    WHERE ps.agent_key = p_agent_key
      AND ( ps.clinic_id = p_clinic OR ps.clinic_id IS NULL )
    ORDER BY (ps.clinic_id IS NULL), pv.version DESC;
END $$;

GRANT EXECUTE ON FUNCTION public.admin_list_prompt_versions(uuid, text) TO authenticated;
