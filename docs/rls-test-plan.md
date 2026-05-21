# Supabase RLS Test Plan

This project uses Supabase database tests to protect the core MVP security rules.

## Scope

The first RLS test suite covers these flows:

- Users can update only their own profile.
- Non-admin users cannot promote themselves or change another profile.
- Admin users can block users, resolve reports, and write admin logs.
- Active users can create tasks.
- Helpers can view open tasks, create helper profiles, and quote tasks.
- Helpers cannot directly accept their own offers.
- Task owners accept offers through `accept_task_offer`.
- Offer acceptance assigns the task and creates a conversation.
- Only task parties can access conversations and messages.
- Users can create reports, while only admins can resolve them.
- Only the assigned helper can upload completion proof.
- Task owners can confirm completion.
- Task parties can review each other after completion.

## Commands

Run the database checks locally after the Supabase stack is started:

```bash
supabase db reset --local
supabase test db
supabase db lint --local
```

From the repository root, the combined command is:

```bash
npm run check:supabase
```

## CI

GitHub Actions runs the same database test step in `.github/workflows/ci.yml` after applying migrations and before linting the local database.

## Next Coverage

Future RLS tests should add:

- Supabase Storage bucket policies for task images and completion proof.
- Payment table access once a payment gateway is connected.
- Notification read/update permissions.
- Category admin management.
- Extra moderation checks for rejected, hidden, cancelled, and disputed tasks.
