-- VITATRACK — Bucket Storage `images` pour les images importées depuis l'appareil.
-- Convention de chemin : {auth.uid()}/<fichier> → chaque utilisateur gère son dossier.
-- Lecture publique (affinage/avatars), écriture réservée aux utilisateurs authentifiés.

insert into storage.buckets (id, name, public)
values ('images', 'images', true)
on conflict (id) do nothing;

-- Lecture publique des objets du bucket.
drop policy if exists images_public_read on storage.objects;
create policy images_public_read on storage.objects for select
  using (bucket_id = 'images');

-- Upload (insert) par un utilisateur connecté dans son propre dossier.
drop policy if exists images_owner_insert on storage.objects;
create policy images_owner_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'images' and (storage.foldername(name))[1] = public.auth_uid());

-- Mise à jour / remplacement par le propriétaire du dossier.
drop policy if exists images_owner_update on storage.objects;
create policy images_owner_update on storage.objects for update to authenticated
  using (bucket_id = 'images' and (storage.foldername(name))[1] = public.auth_uid())
  with check (bucket_id = 'images' and (storage.foldername(name))[1] = public.auth_uid());

-- Suppression par le propriétaire ou un admin.
drop policy if exists images_owner_delete on storage.objects;
create policy images_owner_delete on storage.objects for delete to authenticated
  using (bucket_id = 'images' and ((storage.foldername(name))[1] = public.auth_uid() or public.is_admin()));
