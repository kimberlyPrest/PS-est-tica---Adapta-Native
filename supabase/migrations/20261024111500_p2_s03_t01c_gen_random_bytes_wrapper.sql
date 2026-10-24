-- ============================================================
-- P2-S03-T01c — wrapper gen_random_bytes em public (correção do
--   cadastro de canal: "function gen_random_bytes(integer) does not exist")
-- Causa: pgcrypto no Supabase real expõe gen_random_bytes no schema
--   extensions; a RPC admin_save_channel_account (search_path=public)
--   chamava o nome sem qualificar e não o encontrava.
-- Fix: wrapper em public que delega para extensions.gen_random_bytes.
-- Idempotente; replay seguro. Data: 2026-10-24.
-- ============================================================

CREATE OR REPLACE FUNCTION public.gen_random_bytes(n integer)
RETURNS bytea LANGUAGE sql VOLATILE
AS $$
  SELECT extensions.gen_random_bytes(n);
$$;

REVOKE ALL ON FUNCTION public.gen_random_bytes(integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.gen_random_bytes(integer) TO authenticated;

-- Verificação
DO $$
BEGIN
  IF (SELECT encode(public.gen_random_bytes(4), 'hex')) IS NULL THEN
    RAISE EXCEPTION 'wrapper gen_random_bytes não funcional';
  END IF;
END $$;