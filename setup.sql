-- Message Myself: one-time setup. Paste into Supabase > SQL Editor > Run.
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  caption text,
  path text,
  name text,
  mime text,
  size bigint default 0,
  created_at timestamptz not null default now()
);
alter table public.messages enable row level security;
drop policy if exists "own messages" on public.messages;
create policy "own messages" on public.messages for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- private bucket, 50 MB per file (free plan limit), no compression
insert into storage.buckets (id, name, public, file_size_limit)
values ('mm', 'mm', false, 52428800)
on conflict (id) do update set public = false, file_size_limit = 52428800;

drop policy if exists "mm own read" on storage.objects;
drop policy if exists "mm own insert" on storage.objects;
drop policy if exists "mm own delete" on storage.objects;
create policy "mm own read" on storage.objects for select to authenticated
  using (bucket_id = 'mm' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "mm own insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'mm' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "mm own delete" on storage.objects for delete to authenticated
  using (bucket_id = 'mm' and (storage.foldername(name))[1] = auth.uid()::text);
