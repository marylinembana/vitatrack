-- VITATRACK — schéma Postgres (Supabase). Design hybride : colonnes relationnelles
-- pour le filtrage + une colonne JSONB contenant la représentation exacte du modèle
-- Dart (toMap()). Auth gérée par Supabase Auth (auth.users) ; `profiles.id` = auth uid.
-- Dates en UTC (timestamptz).

create table if not exists public.profiles (
  id              text primary key,               -- = auth.users.id (uuid en texte)
  email           text not null unique,
  role            text not null default 'user',   -- user | nutritionist | admin
  full_name       text not null default '',
  photo_url       text,
  nutritionist_id text,
  is_onboarded    boolean not null default false,
  profile         jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists idx_profiles_role on public.profiles (role);
create index if not exists idx_profiles_nutritionist on public.profiles (nutritionist_id);

create table if not exists public.categories (
  id    text primary key,
  name  text not null,
  emoji text not null default '',
  data  jsonb not null default '{}'::jsonb
);

create table if not exists public.foods (
  id          text primary key,
  name        text not null,
  category_id text not null,
  is_active   boolean not null default true,
  image_url   text,
  data        jsonb not null default '{}'::jsonb
);
create index if not exists idx_foods_category on public.foods (category_id);
create index if not exists idx_foods_active on public.foods (is_active);

create table if not exists public.meals (
  id        text primary key,
  user_id   text not null,
  meal_type text not null default '',
  meal_date timestamptz not null,
  data      jsonb not null default '{}'::jsonb
);
create index if not exists idx_meals_user_date on public.meals (user_id, meal_date);

create table if not exists public.weight_entries (
  id         text primary key,
  user_id    text not null,
  entry_date timestamptz not null,
  data       jsonb not null default '{}'::jsonb
);
create index if not exists idx_weight_user_date on public.weight_entries (user_id, entry_date);

create table if not exists public.nutrition_goals (
  id         text primary key,
  user_id    text not null,
  is_active  boolean not null default true,
  start_date timestamptz not null,
  data       jsonb not null default '{}'::jsonb
);
create index if not exists idx_goal_user_active on public.nutrition_goals (user_id, is_active, start_date);

create table if not exists public.nutrition_plans (
  id              text primary key,
  nutritionist_id text not null,
  patient_id      text not null,
  created_at      timestamptz not null default now(),
  data            jsonb not null default '{}'::jsonb
);
create index if not exists idx_plan_nutritionist on public.nutrition_plans (nutritionist_id);
create index if not exists idx_plan_patient on public.nutrition_plans (patient_id);

create table if not exists public.recommendations (
  id              text primary key,
  user_id         text not null,
  nutritionist_id text,
  is_read         boolean not null default false,
  created_at      timestamptz not null default now(),
  data            jsonb not null default '{}'::jsonb
);
create index if not exists idx_rec_user on public.recommendations (user_id, created_at);

create table if not exists public.notifications (
  id         text primary key,
  user_id    text not null,
  is_read    boolean not null default false,
  created_at timestamptz not null default now(),
  data       jsonb not null default '{}'::jsonb
);
create index if not exists idx_notif_user on public.notifications (user_id, created_at);

create table if not exists public.conversations (
  id              text primary key,
  user_id         text not null,
  nutritionist_id text not null,
  updated_at      timestamptz not null default now(),
  data            jsonb not null default '{}'::jsonb
);
create index if not exists idx_conv_user on public.conversations (user_id);
create index if not exists idx_conv_nutritionist on public.conversations (nutritionist_id);
create unique index if not exists uq_conv_pair on public.conversations (user_id, nutritionist_id);

create table if not exists public.messages (
  id              text primary key,
  conversation_id text not null,
  sender_id       text not null,
  sender_role     text not null default 'user',
  body            text not null,
  image_url       text,
  is_read         boolean not null default false,
  sent_at         timestamptz not null default now()
);
create index if not exists idx_msg_conv on public.messages (conversation_id, sent_at);

create table if not exists public.activity_logs (
  id         text primary key,
  actor_id   text not null,
  actor_role text not null default '',
  action     text not null,
  target     text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists idx_log_created on public.activity_logs (created_at);

-- Trigger updated_at pour profiles.
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated before update on public.profiles
for each row execute function public.touch_updated_at();
