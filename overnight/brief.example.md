# Overnight Brief — Example

> Copy this to brief.md and edit before launching.

## Projects

- ALLOK8R: "Fix all TypeScript build errors and get the build green"
- TLE: "Add error handling to all API routes in server/api/"

## Do NOT Touch

- ALLOK8R: "Don't modify auth, don't touch the events page — it's mid-redesign"
- TLE: "Leave the PWA manifest and service worker alone"
- ALL: "Don't add new npm dependencies"

## Constraints

- Keep commits small and atomic — one logical change per commit
- Don't refactor surrounding code — fix only what's asked
- If a test file exists for a modified file, ensure tests still pass
- No UI changes — backend and build fixes only

## Context

- ALLOK8R uses Next.js 15 app router with Drizzle ORM and Supabase
- TLE uses Nuxt 4 with Vue 3 and Drizzle ORM
- Both projects have Supabase RLS policies already configured — don't recreate them
- ALLOK8R's events page is being redesigned — files in app/(main)/events/ are volatile

## Success Looks Like

- ALLOK8R: `npm run build` passes with zero errors
- TLE: Every file in `server/api/` has try/catch with proper error responses
- Both projects: clean git log with descriptive commit messages
