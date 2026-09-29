-- VITATRACK — Annuaire des coachs : permettre à un patient de découvrir les
-- nutritionnistes VÉRIFIÉS pour la fonction « Mon coach ».
--
-- Ajout à la politique profiles_read : tout utilisateur connecté peut lire les
-- profils de role 'nutritionist' dont la vérification est approuvée. Les autres
-- lignes (profils privés d'autres utilisateurs) restent protégées.
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated
  using (
    id = public.auth_uid()
    or public.is_admin()
    or public.assigned_to_me(id)
    or (
      role = 'nutritionist'
      and (
        profile->>'verificationStatus' = 'verified'
        or coalesce((profile->>'isVerified')::boolean, false)
      )
    )
  );
