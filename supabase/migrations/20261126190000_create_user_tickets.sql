create table if not exists public.user_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  local_ticket_id text not null,
  ticket_json jsonb not null,
  departure_time timestamptz,
  updated_at timestamptz not null default now(),
  unique (user_id, local_ticket_id)
);

alter table public.user_tickets enable row level security;

create policy "Users can select their own tickets"
  on public.user_tickets
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert their own tickets"
  on public.user_tickets
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their own tickets"
  on public.user_tickets
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own tickets"
  on public.user_tickets
  for delete
  to authenticated
  using (auth.uid() = user_id);
