-- ============================================================
-- P2-S02-T03b — _edge_read_secret: leitura do Vault para Edge Functions
--   + sanitização de whitespace (fix da busca "falha de rede")
-- Causa 1: o schema vault NÃO está exposto na API PostgREST — supabase-js com
--   service key não lê vault.secrets direto; a Edge Function search-expert-patient
--   via supabase-js recebia secret vazio → "Token da API não configurado".
-- Causa 2: token colado com quebra de linha (\n na posição 77) → header HTTP
--   inválido → TypeError no fetch → "falha de rede ao contatar a API".
-- Fix: RPC SECURITY DEFINER que lê o segredo e remove TODO whitespace
--   (regexp_replace '\s'). Proteção por GRANTS (só service_role tem EXECUTE).
-- Idempotente; replay seguro. Data: 2026-10-24.
-- ============================================================

CREATE OR REPLACE FUNCTION public._edge_read_secret(p_secret_ref text)
RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_id uuid;
  v_valor text;
BEGIN
  -- proteção por GRANTS: só service_role tem EXECUTE (PUBLIC/anon/authenticated revogados).
  IF p_secret_ref IS NULL OR NOT p_secret_ref LIKE 'vault:%' THEN
    RETURN NULL;
  END IF;
  v_id := replace(p_secret_ref, 'vault:', '')::uuid;
  SELECT regexp_replace(secret, '\s', '', 'g') INTO v_valor FROM vault.secrets WHERE id = v_id;
  RETURN NULLIF(v_valor, '');
END $fn$;

REVOKE ALL ON FUNCTION public._edge_read_secret(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public._edge_read_secret(text) TO service_role;