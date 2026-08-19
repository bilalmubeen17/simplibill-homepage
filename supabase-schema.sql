-- Run this once in the Supabase SQL editor (Project -> SQL Editor -> New query)
-- for the project backing blog.html and admin.html.

create table if not exists articles (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title text not null,
  excerpt text,
  body text not null,
  cover_image_url text,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table articles enable row level security;

-- Public (anon) visitors can only read published posts.
create policy "Public can read published articles"
  on articles for select
  to anon
  using (published = true);

-- Signed-in admins can read everything, including drafts.
create policy "Authenticated users can read all articles"
  on articles for select
  to authenticated
  using (true);

create policy "Authenticated users can insert articles"
  on articles for insert
  to authenticated
  with check (true);

create policy "Authenticated users can update articles"
  on articles for update
  to authenticated
  using (true);

create policy "Authenticated users can delete articles"
  on articles for delete
  to authenticated
  using (true);
