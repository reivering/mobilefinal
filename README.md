# mobilefinal
## Budget tracker backend

The app uses Clerk for authentication and Supabase for Postgres, Storage,
Realtime, and Edge Functions. The Clerk Flutter SDK is currently beta; the
web build works, while native OAuth/deep-link flows should be tested on the
target Android/iOS device.

### Run with backend configuration

Never put a Clerk secret key or a Supabase service-role key in this app.
Publishable client keys are safe to ship when Supabase Row Level Security is
enabled.

```bash
flutter run -d chrome --dart-define-from-file=config/backend.json
```

`config/backend.json` is local-only and git-ignored. Copy
`config/backend.example.json` to create it on another machine.

The Supabase JWT template in Clerk must be named `supabase` (or pass a
different name with `SUPABASE_JWT_TEMPLATE`). Configure that template to sign
tokens with the Supabase JWT secret, then run `supabase/schema.sql` in the
Supabase SQL editor.

### What is wired

- Clerk sign-in/sign-up is shown before the budget shell.
- Clerk session tokens are attached to the Supabase client as bearer tokens.
- The SQL schema uses Clerk's `sub` claim for per-user Row Level Security.
- Hive remains as a local cache until the transaction repository is migrated
  to the Supabase tables.
