# Repo Checks

Task 1 defines the checks that every feature PR should pass before merge.

## Admin

```powershell
npm --prefix apps/admin ci
npm --prefix apps/admin run lint
npm --prefix apps/admin run build
npm --prefix apps/admin audit --omit=dev
```

Shortcut:

```powershell
npm run check:admin
```

## Flutter

```powershell
cd apps/mobile
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

Shortcut:

```powershell
npm run check:mobile
```

## Supabase SQL

Requires Docker and Supabase CLI.

```powershell
supabase start
supabase db reset --local
supabase db lint --local
supabase stop --no-backup
```

Shortcut:

```powershell
npm run check:supabase
```

## GitHub Actions

`.github/workflows/ci.yml` runs three independent jobs:

- `Next.js Admin`: install, lint, build, audit
- `Flutter App`: pub get, format, analyze, test
- `Supabase SQL`: local Supabase start, migration replay, database lint
