# Zion Tech — Church Prayer Calling (Phase 1)

A working React + Supabase admin dashboard for CSI Holy Redeemer's Church. **Simulation only:** no actual outbound calls, automatic jobs, telephony provider integration, or SMS are included. The scheduler saves draft dates; it does not execute jobs. This intentionally prevents accidental calls or costs.

## Setup

1. Create a Supabase project (or use an existing project). Open SQL Editor and execute `supabase/schema.sql`.
2. Supabase Authentication → Users: create an admin email/password account. Copy the user's UUID.
3. SQL Editor: `insert into public.call_app_admins(user_id) values ('YOUR-USER-UUID');` (replace placeholder).
4. Copy `.env.example` to `.env.local`; set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`. The publishable/anon key is safe in frontend; **never put the service_role/secret key in Vite variables**.
5. Run `npm install`, `npm run dev`, and visit the printed local URL.
6. Sign in; add consenting members; upload audio; create a draft; click **Simulate calls**; inspect Call Reports.
7. To deploy on Vercel, push this project to GitHub, import it in Vercel, and add the same two `VITE_` variables. Build command `npm run build`, output `dist`.

## CSV example

```csv
name,phone,language,consent
Example Member,+919876543210,ta,yes
```

Use only consented members; do not upload real church-member data until access/security testing is complete. CSV parser is intentionally basic: it does not support quoted fields containing commas. Duplicate phone numbers will be rejected by the database.

## Privacy and security

- The Supabase database has RLS and no anonymous member-read policy. Only explicit `call_app_admins` users can manage records.
- Prayer audio is stored in a **private** storage bucket and previewed through short-lived signed URLs.
- Removing consent excludes a member from **future simulations**. Phase 2 must recheck consent immediately before every real call.
- No automatic monthly recurrence is implemented yet. Date/time is a draft plan only.
- For production telephony, confirm provider availability, Indian telecom/consent requirements, permitted calling hours, opt-out mechanisms, secure server-side scheduling, provider webhooks, retries, throttling, and audit logs.
- CSV import, admin deletion, and other changes modify the configured Supabase database; test with a disposable project first.

## Known Phase 1 limitations

- Simulations insert call log records, but no calls are placed.
- CSV import is not a complete RFC 4180 parser; use simple unquoted comma-separated fields.
- Recording deletion/editing, campaign cancellation/editing, recurring scheduling, role management, password reset and detailed audit logs are future work.
- No automated tests or build validation are claimed unless separately run.
