# Session Log — ALLOK8R — 2026-04-10

**Focus:** Feature additions + HTML parity fixes across events, onboarding, blacklist, free submissions, finance, payments, activity log, auth flows, and URL routing.

## Work Completed (Uncommitted)

### 1. Events / Modals
- **"NSE event" checkbox → dynamic org name** in 3 modals (add-event, add-event-stepper, edit-event). Now uses `useOrg()` to display `{org.name} event` instead of hardcoded "NSE event".
- **event-detail-header stripped to match `ALLOK8R.html`** — removed archived badge, venue in meta, cumulative frees indicator, pool/allocated/sold aggregate stats, and release summary chips.

### 2. Online Sales
- **Per-release "Enable online sales" toggle** in `online-sales-table.tsx`. Partners can now toggle `onlineEnabled` per release from the UI. Wired via new `handleToggleOnline` handler in `event-detail-inline.tsx` that PATCHes `/api/events/{id}/releases/{releaseId}`.

### 3. Trackers
- **Ticket log status dropdown** — `TicketLogRow.status` expanded from `"pending" | "sent"` to `"pending" | "paid" | "complete" | "awaiting-batch" | "to-hand-out"`. Added a Status column to the ticket log table with a per-row dropdown (editable for partners, read-only label for others).

### 4. Free Form (public submissions)
- **Public `/free-form` page** built to match the HTML preview design (dark gradient bg, star field, org branding card, white form card with purple asterisks).
- **Public `/api/public/free-form` endpoint** — no auth, validates with Zod, inserts into `free_subs` via admin client.
- **Public `/api/public/org/[orgId]` endpoint** — serves minimal org data (name, initials, color, branding) for rendering the form.
- **Back button** fixed top-left with frosted glass effect.
- **10-second polling + focus/reconnect refetch** added to `useFreeSubs` hook so new public submissions appear automatically on the dashboard.

### 5. Onboarding Form (public signup)
- **Public `/onboard-form` page** — two-screen flow matching the HTML preview: role picker (Manager/TL/Promoter) → form with supervisor dropdown, custom fields, account section.
- **Public `/api/public/onboard-form` endpoint** — inserts into `onboard_submissions`.
- **Approved onboarding → people table** — the PATCH handler on `/api/onboard-submissions` now creates a `people` row for each approved submission (resolves reports_to name → supervisor id, sets `pending_registration: true`, `status: active`).

### 6. Blacklist
- **Modal redesigned to match HTML** — danger banner, required Full name, Phone, Reason dropdown (5 options), Notes, red "Add" button.
- **Edit mode** — same modal now handles edit via optional `data` prop; new PATCH endpoint `/api/blacklist/[id]` added.
- **Edit button on blacklist page** next to Remove for each row.
- **Blacklist matching in onboarding wizard** — fetches blacklist, flags submissions where name or phone matches with a red warning banner: *"⛔ Blacklisted — matches [entry name] by [name/phone/name & phone] · [reason]"*.
- **Blacklist matching in free submissions** — same matcher applied; flagged rows get red-tinted background, "⛔ Blacklisted" badge, sub-text with match details, hover tooltip.

### 7. Finance / Payments
- **Record payment modal redesigned to match HTML** — title changed from "Record payment" to "Make payment", added info banner showing Event · Release · Total/Paid/Remaining (amber), amount prefilled with remaining + max validation, proof upload zone ("📎 Tap to attach receipt or screenshot"), optional note field.
- **Proof file upload wired up** — converts file to base64 data URL and sends as `proofUrl` (backend already supported it, just needed client plumbing). Works in both finance/payments and finance/chase (shared modal).

### 8. Nav / Sidebar
- **Fixed Payment Chase highlighting bug** — sidebar + mobile drawer no longer keep `Payments` active when on `/finance/chase`. `isActive` now checks for more-specific matching nav entries.

### 9. People
- **Added Email field** to edit-person modal. API already supported it (Supabase Auth email sync included).

### 10. Activity Log
- **New `logActivity()` service** at `lib/services/activity-log.service.ts` matching HTML prototype categories (event, release, alloc, payment, person, codes, announce, tracker, settings, sale). Wired into:
  - Onboarding approve/decline/restore/delete
  - Blacklist add/edit/delete
  - Payment transactions (with proof indicator)

### 11. Settings
- **Page header wrapped in `.page-header` card** to match all other pages. Was previously a bare inline-flex row.

### 12. Auth — Password Reset Flow (NEW — previously broken)
- **`/forgot-password` page** — email input, success state, back to login link. Uses same `login-card` styling.
- **`/reset-password/[token]` page** — new password + confirm with matching validation, show/hide toggle, success screen with auto-redirect to login.
- **Login form** — "Forgot password?" span converted to a Next.js Link.
- **Bug fix in `/api/auth/forgot-password`** — token insert was failing on a FK constraint because it used a sentinel `org_id=0000...`. Now uses the person's actual `org_id` (tokens still distinguishable via `role="__password_reset__"`).
- **Fresh-password-check in `/api/auth/reset-password`** — attempts a sign-in with the proposed new password; if it succeeds, rejects with "New password cannot be the same as your current password". Uses isolated anon client so the check doesn't affect the user's active session.
- **Env migration: `RESEND_API_KEY` + `EMAIL_FROM`** updated — old key was a test sandbox (sends only to signup email). New sending key attached to `allok8r.com` domain. `EMAIL_FROM` changed from `onboarding@resend.dev` → `noreply@allok8r.com`. Resend DNS (DKIM/SPF/MX) all verified.
- **Confirmed working** — `[email] Sent "Reset your ALLOK8R password" to yujinojima@gmail.com` logged successfully.

### 13. URL Routing (production → allok8r.com)
- **New `getPublicUrl()` helper** at `lib/utils/public-url.ts`. Prefers `process.env.NEXT_PUBLIC_APP_URL`, falls back to `window.location.origin`.
- **`.env` updated** — `NEXT_PUBLIC_APP_URL=https://allok8r.com` (production default).
- **`.env.local` override** — `NEXT_PUBLIC_APP_URL=http://localhost:3000` for local dev.
- **free-subs page** — form link builder uses `getPublicUrl()`.
- **onboarding-wizard page** — invite link builder uses `getPublicUrl()`.
- **Email templates & reset-password route** — already use `NEXT_PUBLIC_APP_URL`, no changes needed.

## Files Modified

### API (11 files)
```
allok8r/src/app/api/auth/forgot-password/route.ts
allok8r/src/app/api/auth/reset-password/route.ts
allok8r/src/app/api/blacklist/[id]/route.ts
allok8r/src/app/api/blacklist/route.ts
allok8r/src/app/api/onboard-submissions/route.ts
allok8r/src/app/api/payments/[id]/transactions/route.ts
allok8r/src/app/api/public/free-form/route.ts             [NEW]
allok8r/src/app/api/public/onboard-form/route.ts          [NEW]
allok8r/src/app/api/public/org/[orgId]/route.ts           [NEW]
```

### Pages (8 files)
```
allok8r/src/app/(app)/blacklist/page.tsx
allok8r/src/app/(app)/free-subs/page.tsx
allok8r/src/app/(app)/onboarding-wizard/page.tsx
allok8r/src/app/(app)/settings/page.tsx
allok8r/src/app/(app)/trackers/page.tsx
allok8r/src/app/(auth)/forgot-password/page.tsx           [NEW]
allok8r/src/app/(auth)/login/login-form.tsx
allok8r/src/app/(auth)/reset-password/[token]/page.tsx    [NEW]
allok8r/src/app/(public)/free-form/page.tsx               [NEW]
allok8r/src/app/(public)/free-form.css                    [NEW]
allok8r/src/app/(public)/layout.tsx                       [NEW]
allok8r/src/app/(public)/onboard-form/page.tsx            [NEW]
```

### Components (9 files)
```
allok8r/src/components/events/event-detail-header.tsx
allok8r/src/components/events/event-detail-inline.tsx
allok8r/src/components/events/online-sales-table.tsx
allok8r/src/components/layout/mobile-drawer.tsx
allok8r/src/components/layout/sidebar.tsx
allok8r/src/components/modals/add-blacklist-modal.tsx
allok8r/src/components/modals/add-event-modal.tsx
allok8r/src/components/modals/add-event-stepper-modal.tsx
allok8r/src/components/modals/edit-event-modal.tsx
allok8r/src/components/modals/edit-person-modal.tsx
allok8r/src/components/modals/modal-manager.tsx
allok8r/src/components/modals/record-payment-modal.tsx
```

### Lib (3 files)
```
allok8r/src/lib/hooks/use-free-subs.ts
allok8r/src/lib/services/activity-log.service.ts         [NEW]
allok8r/src/lib/types/tracker.ts
allok8r/src/lib/utils/public-url.ts                      [NEW]
```

### Config
```
.env                    (NEXT_PUBLIC_APP_URL → allok8r.com)
.env.local              (RESEND key + EMAIL_FROM + local APP_URL override)
```

## Known Issues / Loose Ends

1. **Event-detail-header mention of "profile page match HTML"** — Request was queued but not completed. Needs separate session.
2. **Notification preferences: email vs in-app** — Queued, not started.
3. **Dashboard widget "display order" removal** — Queued, not started.
4. **Global search bar HTML match** — Queued, need clarification on which search bar.
5. **Registration invite emails** — Not manually tested end-to-end in this session (only password reset was confirmed).
6. **Backfill person creation for previously-approved onboarding** — Only new approvals create people. Historical approved submissions without matching people rows would need a one-off migration.
7. **Profile page & edit-profile modal match HTML** — Not started.
8. **Activity log coverage** — Only 3 mutation paths log events (onboard, blacklist, payment tx). Events, releases, allocations, people changes, codes, announcements, trackers, settings changes still don't log — needs broader rollout.

## Revenue Impact (per revenue mindset)

| Change | Tag | Why |
|---|---|---|
| Password reset flow | REVENUE-INDIRECT | Blocks new user activation if broken; now fixed |
| Public free form | REVENUE-INDIRECT | Critical path for client-facing submissions |
| Public onboard form | REVENUE-INDIRECT | Reduces manual partner work onboarding promoters |
| Blacklist matching | REVENUE-DIRECT | Prevents payout leakage to flagged actors |
| Proof file on payments | REVENUE-DIRECT | Reduces dispute friction |
| Nav highlight fix | REVENUE-NEUTRAL | UX polish |
| Settings header wrap | REVENUE-NEUTRAL | Visual consistency |
| URL routing → prod | REVENUE-INDIRECT | Required for production launch |
