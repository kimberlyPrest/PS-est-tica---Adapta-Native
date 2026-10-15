-- =====================================================================
-- P2-S01-T02 (complemento) — profiles.role passa a permitir nulo
-- Motivo: handle_new_user corrigido cria perfil SEM papel (SPEC P2-S01:
-- "cria profiles com role nulo; nunca concede papel"). A coluna era
-- NOT NULL DEFAULT 'admin' — o INSERT com NULL violaria a constraint.
-- DROP NOT NULL é aditivo e não destrutivo: dados existentes intactos.
-- =====================================================================
ALTER TABLE public.profiles ALTER COLUMN role DROP NOT NULL;

-- guarda: a coluna precisa aceitar nulo agora
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='profiles'
      AND column_name='role' AND is_nullable='NO'
  ) THEN
    RAISE EXCEPTION 'profiles.role ainda é NOT NULL — hardening incompleto';
  END IF;
END $$;
