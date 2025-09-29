# Supabase setup

This app can run without Supabase (local-only mode), or with Supabase enabled for auth + cloud sync.

## 0) Default embedded config
By default, the app is configured to use a Supabase project via constants in `lib/common/supabase_config.dart`.
This enables cloud mode automatically (AuthGate, login, and sync) without passing any run-time flags.

You can still override these at run time (see next section), which will take precedence over the defaults.

## 1) Provision Supabase and get keys
- Create a Supabase project
- Get Project URL and anon public key

## 2) Override keys at runtime (dart-define)
If you want to use another Supabase environment (staging/production), pass keys on run/build. For example:

flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

If these are omitted, the app will use the defaults embedded in `SupabaseConfig`.

## 3) Tables and minimal schema
Create tables with `user_id` column and RLS enabled.

- expenses(id, user_id, title, amount, category, created_at)
- transactions(id, user_id, wallet_name, amount, type, created_at)
- wallets(id, user_id, name, balance, updated_at)
- budgets(id, user_id, name, limit, period, updated_at)
- subscriptions(id, user_id, name, price, cycle, next_billing_at)

Enable Row Level Security and add policies such as:

- SELECT/INSERT/UPDATE WHERE user_id = auth.uid()

## 4) Auth
Email/password is supported via the Login screen. Session is persisted by supabase_flutter.

## 5) Sync behavior
- All local writes are queued in a Hive box (`syncQueue`).
- When connectivity is available and a session exists, queued writes push to Supabase.
- After pushing, a pull refresh updates local Hive boxes.

## 6) Troubleshooting
- Ensure keys are correct and policies allow your user.
- If assets fail to load after pruning, run a clean build to regenerate assets.

## 7) Security notes
- The anon public key is intended for client-side usage with the `anon` role. Keep Row Level Security (RLS) enabled and restrict access using policies such as `user_id = auth.uid()`.
- If you plan to make this repository public, remove or replace the embedded keys before publishing, and use environment overrides instead.

