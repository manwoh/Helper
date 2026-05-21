create extension if not exists pgcrypto;

create type public.app_role as enum ('user', 'helper', 'merchant', 'admin');
create type public.verification_status as enum ('none', 'pending', 'approved', 'rejected');
create type public.task_type as enum ('help', 'answer', 'find_item', 'resource');
create type public.task_status as enum ('draft', 'open', 'offered', 'assigned', 'in_progress', 'completed', 'cancelled', 'rejected', 'hidden');
create type public.offer_status as enum ('pending', 'accepted', 'rejected', 'withdrawn');
create type public.conversation_status as enum ('open', 'closed');
create type public.message_type as enum ('text', 'image', 'system');
create type public.report_status as enum ('open', 'reviewing', 'resolved', 'rejected');
create type public.payment_status as enum ('pending', 'paid', 'failed', 'refunded');
create type public.notification_type as enum ('task', 'offer', 'chat', 'review', 'report', 'payment', 'system');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '新用户',
  phone text,
  avatar_url text,
  role public.app_role not null default 'user',
  city text,
  district text,
  bio text,
  rating_average numeric(3,2) not null default 0 check (rating_average >= 0 and rating_average <= 5),
  rating_count integer not null default 0 check (rating_count >= 0),
  is_blocked boolean not null default false,
  blocked_reason text,
  blocked_at timestamptz,
  verification_status public.verification_status not null default 'none',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.helper_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  headline text,
  bio text,
  skills text[] not null default '{}',
  service_areas text[] not null default '{}',
  hourly_rate numeric(12,2) check (hourly_rate is null or hourly_rate >= 0),
  verification_status public.verification_status not null default 'none',
  verification_note text,
  completed_tasks integer not null default 0 check (completed_tasks >= 0),
  rating_average numeric(3,2) not null default 0 check (rating_average >= 0 and rating_average <= 5),
  rating_count integer not null default 0 check (rating_count >= 0),
  is_available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories(id) on delete cascade,
  task_type public.task_type,
  name text not null,
  slug text not null,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(parent_id, slug)
);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles(id) on delete cascade,
  assigned_helper_id uuid references public.profiles(id) on delete set null,
  category_id uuid references public.categories(id) on delete set null,
  subcategory_id uuid references public.categories(id) on delete set null,
  task_type public.task_type not null default 'help',
  title text not null check (char_length(title) between 4 and 80),
  description text not null check (char_length(description) between 10 and 2000),
  location_text text not null check (char_length(location_text) between 2 and 160),
  city text,
  district text,
  budget_min numeric(12,2) check (budget_min is null or budget_min >= 0),
  budget_max numeric(12,2) check (budget_max is null or budget_max >= 0),
  is_urgent boolean not null default false,
  urgent_fee numeric(12,2) not null default 0 check (urgent_fee >= 0),
  status public.task_status not null default 'open',
  moderation_note text,
  selected_offer_id uuid,
  completion_note text,
  completion_proof_url text,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (budget_max is null or budget_min is null or budget_max >= budget_min)
);

create table public.task_images (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  uploader_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null,
  public_url text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.task_offers (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  helper_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric(12,2) not null check (amount >= 0),
  message text check (message is null or char_length(message) <= 600),
  estimated_minutes integer check (estimated_minutes is null or estimated_minutes > 0),
  status public.offer_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(task_id, helper_id)
);

alter table public.tasks
  add constraint tasks_selected_offer_id_fkey
  foreign key (selected_offer_id) references public.task_offers(id) on delete set null;

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  requester_id uuid not null references public.profiles(id) on delete cascade,
  helper_id uuid not null references public.profiles(id) on delete cascade,
  offer_id uuid references public.task_offers(id) on delete set null,
  status public.conversation_status not null default 'open',
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(task_id, helper_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  message_type public.message_type not null default 'text',
  body text,
  attachment_url text,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  check (body is not null or attachment_url is not null)
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id) on delete cascade,
  reviewee_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text check (comment is null or char_length(comment) <= 800),
  created_at timestamptz not null default now(),
  unique(task_id, reviewer_id, reviewee_id),
  check (reviewer_id <> reviewee_id)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('user', 'task', 'offer', 'message', 'review')),
  target_id uuid not null,
  reason text not null check (char_length(reason) between 2 and 80),
  details text check (details is null or char_length(details) <= 1200),
  status public.report_status not null default 'open',
  admin_id uuid references public.profiles(id) on delete set null,
  resolution text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  task_id uuid references public.tasks(id) on delete set null,
  amount numeric(12,2) not null check (amount >= 0),
  currency char(3) not null default 'MYR',
  payment_type text not null default 'reserved',
  status public.payment_status not null default 'pending',
  provider text,
  provider_reference text,
  provider_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  notification_type public.notification_type not null default 'system',
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.admin_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  details jsonb not null default '{}'::jsonb,
  ip_address inet,
  created_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

create trigger helper_profiles_set_updated_at before update on public.helper_profiles
for each row execute function public.set_updated_at();

create trigger categories_set_updated_at before update on public.categories
for each row execute function public.set_updated_at();

create trigger tasks_set_updated_at before update on public.tasks
for each row execute function public.set_updated_at();

create trigger task_offers_set_updated_at before update on public.task_offers
for each row execute function public.set_updated_at();

create trigger conversations_set_updated_at before update on public.conversations
for each row execute function public.set_updated_at();

create trigger reports_set_updated_at before update on public.reports
for each row execute function public.set_updated_at();

create trigger payments_set_updated_at before update on public.payments
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1), '新用户'),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.reject_unsafe_task_content()
returns trigger
language plpgsql
as $$
declare
  combined text;
  blocked_terms text[] := array[
    '色情', '卖淫', '裸聊', '诈骗', '洗钱', '赌博', '毒品', '暴力', '打人',
    '人肉', '偷拍', '侵犯隐私', '身份证买卖', '银行卡买卖', '假证',
    'porn', 'sex service', 'scam', 'fraud', 'money laundering', 'weapon', 'drugs'
  ];
  term text;
begin
  combined := lower(coalesce(new.title, '') || ' ' || coalesce(new.description, ''));

  foreach term in array blocked_terms loop
    if position(lower(term) in combined) > 0 then
      raise exception 'Task content is not allowed by platform safety rules.';
    end if;
  end loop;

  return new;
end;
$$;

create trigger tasks_reject_unsafe_content
before insert or update of title, description on public.tasks
for each row execute function public.reject_unsafe_task_content();

create or replace function public.touch_conversation_last_message()
returns trigger
language plpgsql
as $$
begin
  update public.conversations
  set last_message_at = new.created_at
  where id = new.conversation_id;
  return new;
end;
$$;

create trigger messages_touch_conversation
after insert on public.messages
for each row execute function public.touch_conversation_last_message();

create or replace function public.mark_task_offered()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform set_config('app.bypass_task_guard', 'on', true);

  update public.tasks
  set status = 'offered'
  where id = new.task_id
    and status = 'open';

  return new;
end;
$$;

create trigger task_offers_mark_task_offered
after insert on public.task_offers
for each row execute function public.mark_task_offered();

create index profiles_role_idx on public.profiles(role);
create index profiles_blocked_idx on public.profiles(is_blocked);
create index helper_profiles_user_idx on public.helper_profiles(user_id);
create index helper_profiles_skills_idx on public.helper_profiles using gin(skills);
create index helper_profiles_service_areas_idx on public.helper_profiles using gin(service_areas);
create index categories_parent_idx on public.categories(parent_id);
create index tasks_creator_idx on public.tasks(creator_id);
create index tasks_assigned_helper_idx on public.tasks(assigned_helper_id);
create index tasks_status_idx on public.tasks(status);
create index tasks_type_idx on public.tasks(task_type);
create index tasks_category_idx on public.tasks(category_id, subcategory_id);
create index tasks_city_district_idx on public.tasks(city, district);
create index tasks_urgent_created_idx on public.tasks(is_urgent desc, created_at desc);
create index task_images_task_idx on public.task_images(task_id);
create index task_offers_task_idx on public.task_offers(task_id);
create index task_offers_helper_idx on public.task_offers(helper_id);
create index conversations_task_idx on public.conversations(task_id);
create index conversations_participants_idx on public.conversations(requester_id, helper_id);
create index messages_conversation_created_idx on public.messages(conversation_id, created_at);
create index reviews_reviewee_idx on public.reviews(reviewee_id);
create index reports_status_idx on public.reports(status);
create index payments_user_idx on public.payments(user_id);
create index notifications_user_created_idx on public.notifications(user_id, created_at desc);
create index admin_logs_created_idx on public.admin_logs(created_at desc);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('task-images', 'task-images', true, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('completion-proofs', 'completion-proofs', false, 10485760, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

do $$
begin
  alter publication supabase_realtime add table public.tasks;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.task_offers;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.conversations;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null;
end $$;
