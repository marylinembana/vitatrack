-- VITATRACK — RLS (Row Level Security) miroir des anciennes règles Firestore.
-- Fonctions utilitaires SECURITY DEFINER (lisent profiles sans récursion RLS).

create or replace function public.auth_uid() returns text language sql stable as
$$ select coalesce(auth.uid()::text, '') $$;

create or replace function public.auth_role() returns text
language sql stable security definer set search_path = public as
$$ select role from profiles where id = auth.uid()::text $$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select coalesce(public.auth_role() = 'admin', false) $$;

create or replace function public.is_nutritionist() returns boolean
language sql stable security definer set search_path = public as
$$ select coalesce(public.auth_role() = 'nutritionist', false) $$;

-- Le compte cible est-il assigné au nutritionniste connecté ?
create or replace function public.assigned_to_me(target text) returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from profiles p where p.id = target and p.nutritionist_id = auth.uid()::text) $$;

-- Activer RLS partout.
alter table public.profiles         enable row level security;
alter table public.categories       enable row level security;
alter table public.foods            enable row level security;
alter table public.meals            enable row level security;
alter table public.weight_entries   enable row level security;
alter table public.nutrition_goals  enable row level security;
alter table public.nutrition_plans  enable row level security;
alter table public.recommendations  enable row level security;
alter table public.notifications    enable row level security;
alter table public.conversations    enable row level security;
alter table public.messages         enable row level security;
alter table public.activity_logs    enable row level security;

-- ── profiles ── (create: soi-même ; read: soi/admin/patient assigné ; update: soi/admin ; delete: admin)
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated
  using (id = public.auth_uid() or public.is_admin() or public.assigned_to_me(id));
drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles for insert to authenticated
  with check (id = public.auth_uid());
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update to authenticated
  using (id = public.auth_uid() or public.is_admin())
  with check (id = public.auth_uid() or public.is_admin());
drop policy if exists profiles_delete on public.profiles;
create policy profiles_delete on public.profiles for delete to authenticated
  using (public.is_admin());

-- ── foods / categories ── (read: connecté ; write: admin)
drop policy if exists foods_read on public.foods;
create policy foods_read on public.foods for select to authenticated using (true);
drop policy if exists foods_write on public.foods;
create policy foods_write on public.foods for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists categories_read on public.categories;
create policy categories_read on public.categories for select to authenticated using (true);
drop policy if exists categories_write on public.categories;
create policy categories_write on public.categories for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ── meals ── (create: son user_id ; rw: soi/admin/patient assigné)
drop policy if exists meals_select on public.meals;
create policy meals_select on public.meals for select to authenticated
  using (user_id = public.auth_uid() or public.is_admin() or public.assigned_to_me(user_id));
drop policy if exists meals_insert on public.meals;
create policy meals_insert on public.meals for insert to authenticated
  with check (user_id = public.auth_uid());
drop policy if exists meals_update on public.meals;
create policy meals_update on public.meals for update to authenticated
  using (user_id = public.auth_uid() or public.is_admin() or public.assigned_to_me(user_id))
  with check (user_id = public.auth_uid());
drop policy if exists meals_delete on public.meals;
create policy meals_delete on public.meals for delete to authenticated
  using (user_id = public.auth_uid() or public.is_admin() or public.assigned_to_me(user_id));

-- ── weight_entries ── (même logique que meals)
drop policy if exists weight_select on public.weight_entries;
create policy weight_select on public.weight_entries for select to authenticated
  using (user_id = public.auth_uid() or public.is_admin() or public.assigned_to_me(user_id));
drop policy if exists weight_insert on public.weight_entries;
create policy weight_insert on public.weight_entries for insert to authenticated
  with check (user_id = public.auth_uid());
drop policy if exists weight_update on public.weight_entries;
create policy weight_update on public.weight_entries for update to authenticated
  using (user_id = public.auth_uid() or public.is_admin() or public.assigned_to_me(user_id))
  with check (user_id = public.auth_uid());
drop policy if exists weight_delete on public.weight_entries;
create policy weight_delete on public.weight_entries for delete to authenticated
  using (user_id = public.auth_uid() or public.is_admin() or public.assigned_to_me(user_id));

-- ── nutrition_goals ── (rw: soi/admin/assigné ; create/update: son user_id)
drop policy if exists goals_select on public.nutrition_goals;
create policy goals_select on public.nutrition_goals for select to authenticated
  using (user_id = public.auth_uid() or public.is_admin() or public.assigned_to_me(user_id));
drop policy if exists goals_insert on public.nutrition_goals;
create policy goals_insert on public.nutrition_goals for insert to authenticated
  with check (user_id = public.auth_uid());
drop policy if exists goals_update on public.nutrition_goals;
create policy goals_update on public.nutrition_goals for update to authenticated
  using (user_id = public.auth_uid() or public.is_admin() or public.assigned_to_me(user_id))
  with check (user_id = public.auth_uid());
drop policy if exists goals_delete on public.nutrition_goals;
create policy goals_delete on public.nutrition_goals for delete to authenticated
  using (user_id = public.auth_uid() or public.is_admin() or public.assigned_to_me(user_id));

-- ── nutrition_plans ── (read: impliqué ou admin ; write: nutritionniste/admin)
drop policy if exists plans_select on public.nutrition_plans;
create policy plans_select on public.nutrition_plans for select to authenticated
  using (patient_id = public.auth_uid() or nutritionist_id = public.auth_uid() or public.is_admin());
drop policy if exists plans_write on public.nutrition_plans;
create policy plans_write on public.nutrition_plans for all to authenticated
  using (public.is_nutritionist() or public.is_admin())
  with check (public.is_nutritionist() or public.is_admin());

-- ── recommendations ── (read: concerné ou admin ; write: nutritionniste/admin)
drop policy if exists rec_select on public.recommendations;
create policy rec_select on public.recommendations for select to authenticated
  using (user_id = public.auth_uid() or nutritionist_id = public.auth_uid() or public.is_admin());
drop policy if exists rec_write on public.recommendations;
create policy rec_write on public.recommendations for all to authenticated
  using (public.is_nutritionist() or public.is_admin())
  with check (public.is_nutritionist() or public.is_admin());

-- ── notifications ── (read/update: concerné ou admin ; create: connecté ; delete: concerné ou admin)
drop policy if exists notif_select on public.notifications;
create policy notif_select on public.notifications for select to authenticated
  using (user_id = public.auth_uid() or public.is_admin());
drop policy if exists notif_insert on public.notifications;
create policy notif_insert on public.notifications for insert to authenticated
  with check (true);
drop policy if exists notif_update on public.notifications;
create policy notif_update on public.notifications for update to authenticated
  using (user_id = public.auth_uid() or public.is_admin())
  with check (user_id = public.auth_uid() or public.is_admin());
drop policy if exists notif_delete on public.notifications;
create policy notif_delete on public.notifications for delete to authenticated
  using (user_id = public.auth_uid() or public.is_admin());

-- ── conversations + messages ── (participants ou admin)
drop policy if exists conv_select on public.conversations;
create policy conv_select on public.conversations for select to authenticated
  using (user_id = public.auth_uid() or nutritionist_id = public.auth_uid() or public.is_admin());
drop policy if exists conv_insert on public.conversations;
create policy conv_insert on public.conversations for insert to authenticated
  with check (user_id = public.auth_uid() or nutritionist_id = public.auth_uid());
drop policy if exists conv_update on public.conversations;
create policy conv_update on public.conversations for update to authenticated
  using (user_id = public.auth_uid() or nutritionist_id = public.auth_uid() or public.is_admin())
  with check (user_id = public.auth_uid() or nutritionist_id = public.auth_uid());
drop policy if exists conv_delete on public.conversations;
create policy conv_delete on public.conversations for delete to authenticated
  using (user_id = public.auth_uid() or nutritionist_id = public.auth_uid() or public.is_admin());

drop policy if exists msg_select on public.messages;
create policy msg_select on public.messages for select to authenticated
  using (exists (select 1 from conversations c where c.id = conversation_id
    and (c.user_id = public.auth_uid() or c.nutritionist_id = public.auth_uid() or public.is_admin())));
drop policy if exists msg_insert on public.messages;
create policy msg_insert on public.messages for insert to authenticated
  with check (sender_id = public.auth_uid());
drop policy if exists msg_update on public.messages;
create policy msg_update on public.messages for update to authenticated
  using (true) with check (true);

-- ── activity_logs ── (read: admin ; create: connecté)
drop policy if exists logs_select on public.activity_logs;
create policy logs_select on public.activity_logs for select to authenticated
  using (public.is_admin());
drop policy if exists logs_insert on public.activity_logs;
create policy logs_insert on public.activity_logs for insert to authenticated
  with check (actor_id = public.auth_uid());
