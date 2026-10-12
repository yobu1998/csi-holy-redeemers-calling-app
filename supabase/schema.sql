-- Run once in Supabase SQL Editor. Admins must be explicitly added to call_app_admins.
create extension if not exists pgcrypto;
create table if not exists public.call_app_admins (user_id uuid primary key references auth.users(id) on delete cascade, created_at timestamptz not null default now());
create or replace function public.is_call_app_admin() returns boolean language sql stable security definer set search_path = '' as $$ select exists(select 1 from public.call_app_admins where user_id = (select auth.uid())) $$;
revoke all on function public.is_call_app_admin() from public;
grant execute on function public.is_call_app_admin() to authenticated;
create table if not exists public.call_members (id uuid primary key default gen_random_uuid(),name text not null check(length(trim(name)) between 1 and 160),phone text not null unique check(phone ~ '^\+?[0-9]{10,15}$'),language text not null default 'ta' check(language in ('ta','en')),consent boolean not null default false,consent_at timestamptz,created_at timestamptz not null default now(),constraint consent_recorded check(not consent or consent_at is not null));
create table if not exists public.call_recordings (id uuid primary key default gen_random_uuid(),title text not null,storage_path text not null unique,file_name text,created_at timestamptz not null default now());
create table if not exists public.call_campaigns (id uuid primary key default gen_random_uuid(),name text not null,recording_id uuid not null references public.call_recordings(id),scheduled_at timestamptz not null,status text not null default 'draft' check(status in ('draft','simulated')),created_at timestamptz not null default now());
create table if not exists public.call_logs (id uuid primary key default gen_random_uuid(),campaign_id uuid not null references public.call_campaigns(id) on delete cascade,member_id uuid not null references public.call_members(id) on delete cascade,status text not null default 'simulated' check(status='simulated'),details text,created_at timestamptz not null default now(),unique(campaign_id,member_id));
alter table public.call_app_admins enable row level security;
alter table public.call_members enable row level security;
alter table public.call_recordings enable row level security;
alter table public.call_campaigns enable row level security;
alter table public.call_logs enable row level security;
-- No anonymous policies. Admins can read/write app records only.
do $$ declare t text; begin foreach t in array array['call_members','call_recordings','call_campaigns','call_logs'] loop execute format('drop policy if exists admin_only on public.%I',t); execute format('create policy admin_only on public.%I for all to authenticated using ((select public.is_call_app_admin())) with check ((select public.is_call_app_admin()))',t); end loop; end $$;
drop policy if exists admin_self_read on public.call_app_admins;
create policy admin_self_read on public.call_app_admins for select to authenticated using (user_id=(select auth.uid()));
-- Storage: private bucket, signed URL preview for admins only.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types) values ('prayer-audio','prayer-audio',false,26214400,array['audio/mpeg','audio/mp3','audio/wav','audio/x-wav','audio/ogg','audio/mp4','audio/aac']) on conflict(id) do update set public=false;
drop policy if exists call_audio_admin_select on storage.objects;
drop policy if exists call_audio_admin_insert on storage.objects;
create policy call_audio_admin_select on storage.objects for select to authenticated using (bucket_id='prayer-audio' and (select public.is_call_app_admin()));
create policy call_audio_admin_insert on storage.objects for insert to authenticated with check (bucket_id='prayer-audio' and (select public.is_call_app_admin()) and (storage.foldername(name))[1]=(select auth.uid())::text);
-- After creating the admin user in Supabase Authentication, run separately:
-- insert into public.call_app_admins(user_id) values ('PASTE_AUTH_USER_UUID_HERE');
