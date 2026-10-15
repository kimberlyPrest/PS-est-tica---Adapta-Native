-- =====================================================================
-- P2-S01-T02 — Hardening: profiles, seed, papel legado e trilha de convite
-- SPEC: P2-S01-base-versionada-e-protegida · CA-P2-S01-03/04/07 (parte SQL)
-- Data: 2026-10-14 · Autorizada por Felipe ("proxima task")
-- ---------------------------------------------------------------------
-- Escopo desta migration (aditiva, idempotente):
--   1. handle_new_user: cria profile SEM conceder papel (role fica NULL).
--   2. profiles.role: deprecada como fonte de permissão (comentário);
--      coluna mantida (não destrutivo). Novos usuários nascem NULL.
--   3. profiles SELECT: reafirma escopo (próprio perfil OU colegas de
--      organização) — substitui a antiga USING (true) do baseline.
--   4. Nada destrutivo; nenhum dado alterado além do default de novos.
-- Itens NÃO-SQL da task (Auth dashboard, dono do projeto):
--   - desligar "Allow new users to sign up" (cadastro público);
--   - ativar TOTP (second factor) para owner/clinic_admin.
-- =====================================================================

-- 1) handle_new_user: nunca concede papel; profile nasce sem role
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
BEGIN
  INSERT INTO public.profiles (id, email, name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', ''),
    NULL
  )
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email,
      name = CASE WHEN profiles.name = '' THEN EXCLUDED.name ELSE profiles.name END;
  RETURN NEW;
END;
$fn$;

-- 2) profiles.role deprecada como fonte de permissão (coluna mantida)
COMMENT ON COLUMN public.profiles.role IS 'deprecated: usar memberships (P2-S01); novos perfis nascem com role nulo';

-- 3) Leitura de perfis: próprio perfil OU colegas de organização
-- (reafirma rls_profiles_select da P1-S02-T02; substitui qualquer USING (true) legado)
DROP POLICY IF EXISTS authenticated_select_profiles ON public.profiles;
DROP POLICY IF EXISTS rls_profiles_select ON public.profiles;
CREATE POLICY rls_profiles_select ON public.profiles
  FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR public.is_colleague(id)
  );

-- 4) Verificações (falha clara se algo não ficou como a SPEC pede)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policy pol
    JOIN pg_class c ON c.oid = pol.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='public' AND c.relname='profiles' AND pol.polname='rls_profiles_select'
  ) THEN
    RAISE EXCEPTION 'policy rls_profiles_select ausente após hardening';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_policy pol
    JOIN pg_class c ON c.oid = pol.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='public' AND c.relname='profiles' AND pol.polname='authenticated_select_profiles'
  ) THEN
    RAISE EXCEPTION 'policy legada authenticated_select_profiles ainda presente';
  END IF;
END $$;
