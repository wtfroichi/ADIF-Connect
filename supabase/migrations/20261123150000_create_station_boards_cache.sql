drop table if exists public.station_boards_cache cascade;
create table public.station_boards_cache (
  station_code text not null,
  board_type text not null check (board_type in ('departures', 'arrivals')),
  items jsonb not null default '[]'::jsonb check (jsonb_typeof(items) = 'array'),
  error text,
  source text not null,
  updated_at timestamptz not null,
  expires_at timestamptz not null,
  primary key (station_code, board_type)
);

alter table public.station_boards_cache enable row level security;
revoke all on table public.station_boards_cache from anon, authenticated;
grant all on table public.station_boards_cache to service_role;

create index if not exists station_boards_cache_expires_at_idx
  on public.station_boards_cache (expires_at);
