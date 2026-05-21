create or replace function public.current_user_role()
returns public.app_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select role = 'admin' from public.profiles where id = auth.uid()), false)
$$;

create or replace function public.is_active_user(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select not is_blocked from public.profiles where id = p_user_id), false)
$$;

create or replace function public.is_conversation_participant(p_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.conversations c
    where c.id = p_conversation_id
      and (c.requester_id = auth.uid() or c.helper_id = auth.uid())
  )
$$;

create or replace function public.can_view_task(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.tasks t
    where t.id = p_task_id
      and (
        t.status in ('open', 'offered', 'assigned', 'in_progress', 'completed')
        or t.creator_id = auth.uid()
        or t.assigned_helper_id = auth.uid()
        or public.is_admin()
      )
  )
$$;

create or replace function public.is_task_party(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.tasks t
    where t.id = p_task_id
      and (t.creator_id = auth.uid() or t.assigned_helper_id = auth.uid())
  )
$$;

create or replace function public.is_service_role()
returns boolean
language sql
stable
as $$
  select coalesce(current_setting('request.jwt.claim.role', true), '') = 'service_role'
$$;

create or replace function public.guard_profile_user_updates()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_service_role() or public.is_admin() then
    return new;
  end if;

  if (new.role <> old.role and (new.role = 'admin' or old.role = 'admin'))
    or new.is_blocked <> old.is_blocked
    or new.blocked_reason is distinct from old.blocked_reason
    or new.blocked_at is distinct from old.blocked_at
    or new.verification_status <> old.verification_status
    or new.rating_average <> old.rating_average
    or new.rating_count <> old.rating_count then
    raise exception 'Protected profile fields can only be changed by admin.';
  end if;

  return new;
end;
$$;

create trigger profiles_guard_user_updates
before update on public.profiles
for each row execute function public.guard_profile_user_updates();

create or replace function public.guard_helper_profile_user_updates()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_service_role() or public.is_admin() then
    return new;
  end if;

  if current_setting('app.bypass_helper_guard', true) = 'on' then
    return new;
  end if;

  if new.user_id <> old.user_id
    or new.verification_status <> old.verification_status
    or new.verification_note is distinct from old.verification_note
    or new.completed_tasks <> old.completed_tasks
    or new.rating_average <> old.rating_average
    or new.rating_count <> old.rating_count then
    raise exception 'Protected helper fields can only be changed by admin.';
  end if;

  return new;
end;
$$;

create trigger helper_profiles_guard_user_updates
before update on public.helper_profiles
for each row execute function public.guard_helper_profile_user_updates();

create or replace function public.guard_task_user_updates()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_service_role()
    or public.is_admin()
    or current_setting('app.bypass_task_guard', true) = 'on' then
    return new;
  end if;

  if new.creator_id <> old.creator_id
    or new.assigned_helper_id is distinct from old.assigned_helper_id
    or new.selected_offer_id is distinct from old.selected_offer_id then
    raise exception 'Task assignment fields can only be changed through platform actions.';
  end if;

  if new.status = 'assigned' and old.status <> 'assigned' then
    raise exception 'Accept an offer to assign a helper.';
  end if;

  if new.status in ('hidden', 'rejected') and old.status <> new.status then
    raise exception 'Moderation status can only be changed by admin.';
  end if;

  if new.status = 'completed' and old.assigned_helper_id is null then
    raise exception 'Only assigned tasks can be completed.';
  end if;

  return new;
end;
$$;

create trigger tasks_guard_user_updates
before update on public.tasks
for each row execute function public.guard_task_user_updates();

create or replace function public.guard_offer_user_updates()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_service_role()
    or public.is_admin()
    or current_setting('app.bypass_offer_guard', true) = 'on' then
    return new;
  end if;

  if new.task_id <> old.task_id or new.helper_id <> old.helper_id then
    raise exception 'Offer ownership cannot be changed.';
  end if;

  if new.status = 'accepted' and old.status <> 'accepted' then
    raise exception 'Accept offers through platform action.';
  end if;

  return new;
end;
$$;

create trigger task_offers_guard_user_updates
before update on public.task_offers
for each row execute function public.guard_offer_user_updates();

alter table public.profiles enable row level security;
alter table public.helper_profiles enable row level security;
alter table public.categories enable row level security;
alter table public.tasks enable row level security;
alter table public.task_images enable row level security;
alter table public.task_offers enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.reviews enable row level security;
alter table public.reports enable row level security;
alter table public.payments enable row level security;
alter table public.notifications enable row level security;
alter table public.admin_logs enable row level security;

create policy "Authenticated users can view non-blocked profiles"
on public.profiles for select
to authenticated
using (not is_blocked or id = auth.uid() or public.is_admin());

create policy "Users can insert own profile"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

create policy "Users can update own profile"
on public.profiles for update
to authenticated
using (id = auth.uid() and not is_blocked)
with check (id = auth.uid());

create policy "Admins can manage profiles"
on public.profiles for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Users can view active helpers"
on public.helper_profiles for select
to authenticated
using (is_available or user_id = auth.uid() or public.is_admin());

create policy "Users can create own helper profile"
on public.helper_profiles for insert
to authenticated
with check (user_id = auth.uid() and public.is_active_user(auth.uid()));

create policy "Users can update own helper profile"
on public.helper_profiles for update
to authenticated
using (user_id = auth.uid() and public.is_active_user(auth.uid()))
with check (user_id = auth.uid());

create policy "Admins can manage helper profiles"
on public.helper_profiles for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Users can view active categories"
on public.categories for select
to authenticated
using (is_active or public.is_admin());

create policy "Admins can manage categories"
on public.categories for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Users can view allowed tasks"
on public.tasks for select
to authenticated
using (
  status in ('open', 'offered', 'assigned', 'in_progress', 'completed')
  or creator_id = auth.uid()
  or assigned_helper_id = auth.uid()
  or public.is_admin()
);

create policy "Users can create tasks"
on public.tasks for insert
to authenticated
with check (creator_id = auth.uid() and public.is_active_user(auth.uid()));

create policy "Task owners can update tasks"
on public.tasks for update
to authenticated
using (
  public.is_admin()
  or (creator_id = auth.uid() and public.is_active_user(auth.uid()))
)
with check (
  public.is_admin()
  or creator_id = auth.uid()
);

create policy "Task owners can delete own draft or open tasks"
on public.tasks for delete
to authenticated
using (
  public.is_admin()
  or (creator_id = auth.uid() and status in ('draft', 'open', 'cancelled'))
);

create policy "Users can view images for visible tasks"
on public.task_images for select
to authenticated
using (public.can_view_task(task_id));

create policy "Task owners can upload task images"
on public.task_images for insert
to authenticated
with check (
  uploader_id = auth.uid()
  and exists (
    select 1 from public.tasks t
    where t.id = task_id and t.creator_id = auth.uid()
  )
);

create policy "Task owners can manage task images"
on public.task_images for update
to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.tasks t
    where t.id = task_id and t.creator_id = auth.uid()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1 from public.tasks t
    where t.id = task_id and t.creator_id = auth.uid()
  )
);

create policy "Task owners can delete task images"
on public.task_images for delete
to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.tasks t
    where t.id = task_id and t.creator_id = auth.uid()
  )
);

create policy "Users can view relevant offers"
on public.task_offers for select
to authenticated
using (
  helper_id = auth.uid()
  or public.is_admin()
  or exists (
    select 1 from public.tasks t
    where t.id = task_id and t.creator_id = auth.uid()
  )
);

create policy "Helpers can quote open tasks"
on public.task_offers for insert
to authenticated
with check (
  helper_id = auth.uid()
  and public.is_active_user(auth.uid())
  and exists (select 1 from public.helper_profiles hp where hp.user_id = auth.uid() and hp.is_available)
  and exists (
    select 1
    from public.tasks t
    where t.id = task_id
      and t.creator_id <> auth.uid()
      and t.status in ('open', 'offered')
  )
);

create policy "Offer owners and task owners can update offers"
on public.task_offers for update
to authenticated
using (
  public.is_admin()
  or helper_id = auth.uid()
  or exists (
    select 1 from public.tasks t
    where t.id = task_id and t.creator_id = auth.uid()
  )
)
with check (
  public.is_admin()
  or helper_id = auth.uid()
  or exists (
    select 1 from public.tasks t
    where t.id = task_id and t.creator_id = auth.uid()
  )
);

create policy "Users can view own conversations"
on public.conversations for select
to authenticated
using (requester_id = auth.uid() or helper_id = auth.uid() or public.is_admin());

create policy "Task parties can create conversations"
on public.conversations for insert
to authenticated
with check (
  public.is_admin()
  or (
    (requester_id = auth.uid() or helper_id = auth.uid())
    and exists (
      select 1 from public.tasks t
      where t.id = task_id
        and t.creator_id = requester_id
        and (t.assigned_helper_id = helper_id or t.status in ('open', 'offered', 'assigned'))
    )
  )
);

create policy "Conversation parties can update conversations"
on public.conversations for update
to authenticated
using (requester_id = auth.uid() or helper_id = auth.uid() or public.is_admin())
with check (requester_id = auth.uid() or helper_id = auth.uid() or public.is_admin());

create policy "Conversation parties can view messages"
on public.messages for select
to authenticated
using (public.is_conversation_participant(conversation_id) or public.is_admin());

create policy "Conversation parties can send messages"
on public.messages for insert
to authenticated
with check (
  sender_id = auth.uid()
  and public.is_active_user(auth.uid())
  and (public.is_conversation_participant(conversation_id) or public.is_admin())
);

create policy "Task parties can view reviews"
on public.reviews for select
to authenticated
using (public.can_view_task(task_id) or reviewer_id = auth.uid() or reviewee_id = auth.uid() or public.is_admin());

create policy "Task parties can create reviews after completion"
on public.reviews for insert
to authenticated
with check (
  reviewer_id = auth.uid()
  and exists (
    select 1 from public.tasks t
    where t.id = task_id
      and t.status = 'completed'
      and (
        (t.creator_id = reviewer_id and t.assigned_helper_id = reviewee_id)
        or (t.assigned_helper_id = reviewer_id and t.creator_id = reviewee_id)
      )
  )
);

create policy "Users can view own reports"
on public.reports for select
to authenticated
using (reporter_id = auth.uid() or public.is_admin());

create policy "Users can create reports"
on public.reports for insert
to authenticated
with check (reporter_id = auth.uid() and public.is_active_user(auth.uid()));

create policy "Admins can update reports"
on public.reports for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Users can view own payments"
on public.payments for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy "Users can create own pending payment records"
on public.payments for insert
to authenticated
with check (user_id = auth.uid() and status = 'pending');

create policy "Admins can manage payments"
on public.payments for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Users can view own notifications"
on public.notifications for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy "Users can mark own notifications read"
on public.notifications for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Admins can manage notifications"
on public.notifications for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Admins can view admin logs"
on public.admin_logs for select
to authenticated
using (public.is_admin());

create policy "Admins can create admin logs"
on public.admin_logs for insert
to authenticated
with check (public.is_admin());

create policy "Authenticated users can read task image files"
on storage.objects for select
to authenticated
using (bucket_id = 'task-images');

create policy "Users can upload own task image files"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'task-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can update own task image files"
on storage.objects for update
to authenticated
using (
  bucket_id = 'task-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can delete own task image files"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'task-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Authenticated users can read avatar files"
on storage.objects for select
to authenticated
using (bucket_id = 'avatars');

create policy "Users can manage own avatar files"
on storage.objects for all
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Conversation users can read completion proofs"
on storage.objects for select
to authenticated
using (bucket_id = 'completion-proofs');

create policy "Users can upload own completion proofs"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'completion-proofs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create or replace function public.accept_task_offer(p_offer_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_offer public.task_offers%rowtype;
  v_task public.tasks%rowtype;
  v_conversation_id uuid;
begin
  perform set_config('app.bypass_task_guard', 'on', true);
  perform set_config('app.bypass_offer_guard', 'on', true);

  select * into v_offer
  from public.task_offers
  where id = p_offer_id
  for update;

  if not found then
    raise exception 'Offer not found.';
  end if;

  select * into v_task
  from public.tasks
  where id = v_offer.task_id
  for update;

  if not found then
    raise exception 'Task not found.';
  end if;

  if v_task.creator_id <> auth.uid() and not public.is_admin() then
    raise exception 'Only task owner can accept an offer.';
  end if;

  if v_task.status not in ('open', 'offered') then
    raise exception 'Task is not open for accepting offers.';
  end if;

  update public.task_offers
  set status = 'rejected'
  where task_id = v_task.id
    and id <> v_offer.id
    and status = 'pending';

  update public.task_offers
  set status = 'accepted'
  where id = v_offer.id;

  update public.tasks
  set status = 'assigned',
      assigned_helper_id = v_offer.helper_id,
      selected_offer_id = v_offer.id
  where id = v_task.id;

  insert into public.conversations (task_id, requester_id, helper_id, offer_id, status)
  values (v_task.id, v_task.creator_id, v_offer.helper_id, v_offer.id, 'open')
  on conflict (task_id, helper_id)
  do update set offer_id = excluded.offer_id, status = 'open', updated_at = now()
  returning id into v_conversation_id;

  insert into public.notifications (user_id, notification_type, title, body, data)
  values (
    v_offer.helper_id,
    'offer',
    '报价已被选择',
    '发布者选择了你的报价，请进入聊天确认细节。',
    jsonb_build_object('task_id', v_task.id, 'offer_id', v_offer.id, 'conversation_id', v_conversation_id)
  );

  return v_conversation_id;
end;
$$;

create or replace function public.submit_completion_proof(
  p_task_id uuid,
  p_completion_note text default null,
  p_completion_proof_url text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_task public.tasks%rowtype;
begin
  perform set_config('app.bypass_task_guard', 'on', true);

  select * into v_task
  from public.tasks
  where id = p_task_id
  for update;

  if not found then
    raise exception 'Task not found.';
  end if;

  if v_task.assigned_helper_id <> auth.uid() then
    raise exception 'Only assigned helper can submit completion proof.';
  end if;

  if v_task.status not in ('assigned', 'in_progress') then
    raise exception 'Task is not ready for completion proof.';
  end if;

  update public.tasks
  set status = 'in_progress',
      completion_note = p_completion_note,
      completion_proof_url = p_completion_proof_url
  where id = p_task_id;

  insert into public.notifications (user_id, notification_type, title, body, data)
  values (
    v_task.creator_id,
    'task',
    '帮手提交了完成证明',
    '请查看任务详情并确认是否完成。',
    jsonb_build_object('task_id', p_task_id)
  );
end;
$$;

create or replace function public.confirm_task_completed(p_task_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_task public.tasks%rowtype;
begin
  perform set_config('app.bypass_task_guard', 'on', true);
  perform set_config('app.bypass_helper_guard', 'on', true);

  select * into v_task
  from public.tasks
  where id = p_task_id
  for update;

  if not found then
    raise exception 'Task not found.';
  end if;

  if v_task.creator_id <> auth.uid() then
    raise exception 'Only task owner can confirm completion.';
  end if;

  if v_task.assigned_helper_id is null or v_task.status not in ('assigned', 'in_progress') then
    raise exception 'Task cannot be completed.';
  end if;

  update public.tasks
  set status = 'completed',
      completed_at = now()
  where id = p_task_id;

  update public.helper_profiles
  set completed_tasks = completed_tasks + 1
  where user_id = v_task.assigned_helper_id;

  insert into public.notifications (user_id, notification_type, title, body, data)
  values (
    v_task.assigned_helper_id,
    'task',
    '任务已确认完成',
    '发布者已经确认任务完成。',
    jsonb_build_object('task_id', p_task_id)
  );
end;
$$;

create or replace function public.write_admin_log(
  p_action text,
  p_entity_type text,
  p_entity_id uuid default null,
  p_details jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_log_id uuid;
begin
  if not public.is_admin() then
    raise exception 'Admin only.';
  end if;

  insert into public.admin_logs (admin_id, action, entity_type, entity_id, details)
  values (auth.uid(), p_action, p_entity_type, p_entity_id, p_details)
  returning id into v_log_id;

  return v_log_id;
end;
$$;

grant execute on function public.accept_task_offer(uuid) to authenticated;
grant execute on function public.submit_completion_proof(uuid, text, text) to authenticated;
grant execute on function public.confirm_task_completed(uuid) to authenticated;
grant execute on function public.write_admin_log(text, text, uuid, jsonb) to authenticated;
