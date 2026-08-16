-- Repair script for the live Supabase students table.
-- Run this in Supabase Dashboard -> SQL Editor.
--
-- This drops the current broken table shape and recreates the schema that the
-- Flutter app expects. Use only if the table is empty or you have backed up any
-- existing rows first.

begin;

drop table if exists public.students cascade;

create table public.students (
    id uuid primary key default gen_random_uuid(),
    pass_id text unique not null,
    name text not null,
    class_name text not null,
    roll_number text,
    department text,
    status text not null default 'pending'
        check (status in ('pending', 'approved')),
    created_at timestamptz not null default now(),
    approved_at timestamptz,
    approved_by uuid references auth.users(id)
);

create index if not exists idx_students_pass_id on public.students(pass_id);
create index if not exists idx_students_status on public.students(status);

alter table public.students enable row level security;

create policy "Authenticated staff can read passes"
    on public.students
    for select
    to authenticated
    using (true);

create policy "Authenticated staff can create pending passes"
    on public.students
    for insert
    to authenticated
    with check (
        status = 'pending'
        and approved_at is null
        and approved_by is null
    );

create or replace function public.approve_pass(
    p_pass_id text,
    p_approved_by uuid
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_status text;
begin
    select status
    into v_status
    from public.students
    where pass_id = p_pass_id
    for update;

    if not found then
        return 'not_found';
    end if;

    if v_status = 'approved' then
        return 'already_approved';
    end if;

    update public.students
    set
        status = 'approved',
        approved_at = now(),
        approved_by = p_approved_by
    where pass_id = p_pass_id
      and status = 'pending';

    return 'approved';
end;
$$;

grant execute on function public.approve_pass(text, uuid) to authenticated;

commit;