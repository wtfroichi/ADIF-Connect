create table if not exists public.train_track_history (
  station_code text not null,
  train_number text not null,
  service_brand text not null,
  direction text not null check (direction in ('departures', 'arrivals')),
  assigned_platform text not null check (assigned_platform !~ '^0+(\.0+)?$'),
  service_date date not null,
  recorded_at timestamptz not null default now(),
  primary key (station_code, train_number, direction, service_date)
);

create index if not exists train_track_history_prediction_idx
  on public.train_track_history
  (station_code, train_number, direction, recorded_at desc);

alter table public.train_track_history enable row level security;
revoke all on public.train_track_history from anon, authenticated;
grant select, insert, update on public.train_track_history to service_role;
