-- Migration 004 : table waitlist pour la landing teaser AllocCheck pendant la maintenance moteur.
-- Objectif : capturer les emails des visiteurs intéressés pour les prévenir à la réouverture.
-- RLS write-only : anon peut INSERT uniquement, pas de SELECT/UPDATE/DELETE public.

create table if not exists public.waitlist (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  source text not null default 'landing',
  user_agent text,
  ip text,
  created_at timestamptz not null default now()
);

create unique index if not exists waitlist_email_unique
  on public.waitlist (lower(email));

alter table public.waitlist enable row level security;

drop policy if exists "anon can insert waitlist" on public.waitlist;
create policy "anon can insert waitlist"
  on public.waitlist
  for insert
  to anon
  with check (true);
