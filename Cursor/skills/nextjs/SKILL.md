---
name: nextjs
description: Next.js App Router performance + correctness rules — Server Components vs Client, Server Actions vs Route Handlers, RSC props serialization, server-side caching (React.cache, unstable_cache, LRU), server-side waterfalls, next/dynamic + next/image + next/font, hydration patterns, force-static / force-dynamic, revalidation. Trigger on "next.js", "nextjs", "app router", "server component", "server action", "RSC", "route handler", "force-static", "force-dynamic", "next/image", "next/font", "next/dynamic", "revalidate", "unstable_cache", "react.cache", "after()", or whenever building/diagnosing/refactoring a Next.js App Router project. Mirrors the Next.js / server-side parts of the Vercel agent-skills react-best-practices guide; for pure React perf (re-renders, client bundle, JS hot paths) use the `react` skill instead.
---

# Next.js (App Router) Performance & Patterns

Server-first rules for Next.js App Router. Use the **mini decision flow** to pick a category before applying. Server-side rules dominate Next.js perf — most "the page is slow" complaints are server waterfalls, not React rendering.

**Source:** [vercel-labs/agent-skills — react-best-practices](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices) (server-side subset). Detailed rule reference lives in `references/rules.md`; concrete spot-and-fix recipes in `references/recipes.md`.

## Mindset

- **Server Components by default.** `'use client'` is opt-in, deepest in the tree, only when interactivity / hooks / browser APIs require it. A client boundary high in the tree pulls everything below into the client bundle.
- **Network beats CPU.** A waterfall of three 200ms fetches is 600ms; the same three in parallel is 200ms. Fix waterfalls before tuning anything else.
- **Cache shape matters more than cache hit rate.** `React.cache` for per-request dedup, `unstable_cache` / external LRU for cross-request, `cache: 'force-cache'` / `'no-store'` per fetch — pick the right tier for the freshness you need.
- **Server Actions are public endpoints.** Auth them. Validate inputs. They're closer to RPC than to internal function calls.
- **Don't ship the database to the client.** RSC props get serialized; an entire user record where the client needs `{ name, avatar }` wastes bandwidth and creates leak risk.

## Mini decision flow

1. Page is slow on first request, fast on second?
   → **Server-Side Caching** (per-request `React.cache`, cross-request `unstable_cache` / LRU).
2. Slowness from many sequential awaits in an RSC, page, or server action?
   → **Eliminating Server Waterfalls**.
3. Adding a tiny client component bloats the client bundle?
   → **Bundle (Next-specific)** — `'use client'` placement, `next/dynamic`.
4. Hydration mismatch / flash of incorrect content?
   → **Hydration**.
5. "Should this be a Server Action or a Route Handler?" / "Where do I put `'use client'`?"
   → **App Router Patterns** below.
6. "Why does my data refresh inconsistently?"
   → **Routing & Revalidation**.

## Categories

| # | Category | Impact | Prefix | When |
|---|---|---|---|---|
| 1 | Server-Side Performance | CRITICAL | `server-` | Slow server response, repeated work, expensive I/O |
| 2 | Eliminating Server Waterfalls | CRITICAL | `async-` | Sequential awaits in RSC, server actions, API routes |
| 3 | Bundle (Next-specific) | HIGH | `bundle-` | Large client bundle, slow hydration, heavy widgets |
| 4 | Hydration & Streaming | MEDIUM | `rendering-` | Hydration mismatch, blank screen, FOUC |

**MANDATORY** when targeting a specific category: load `references/rules.md` and read the matching prefix block. Category labels alone don't tell you *what to change*.

**MANDATORY** when applying any fix: load `references/recipes.md` for the canonical patch shape. Server-side caching APIs change between Next versions — copy the recipe rather than recall from training.

**Do NOT load** the upstream AGENTS.md unless doing a full audit against all 58 rules.

## App Router patterns (no rule prefix — these are conventions, not perf rules)

These aren't Vercel rules; they're Next.js correctness defaults that prevent the most common bugs.

- **Server Component by default.** Add `'use client'` at the deepest leaf that *needs* interactivity. Wrong placement: top-level page becomes client → entire tree client-rendered. Right placement: a single `<Counter>` becomes client; everything else stays server.
- **Server Actions for mutations from your own UI.** Auth, validate input, return typed errors via `useActionState`. Don't put business logic in `<form action={'/api/x'}>` — that bypasses the React-integrated action lifecycle.
- **Route Handlers (`app/api/route.ts`) for external clients.** Webhooks, mobile apps, third-party callbacks, anything not driven by *your* React tree. Match HTTP verbs explicitly (`export async function POST`).
- **`error.tsx` and `loading.tsx`** instead of hand-rolled error/loading flags. Next wraps your segment in error/Suspense boundaries automatically.
- **Mark dynamic mode explicitly** when behavior matters: `export const dynamic = 'force-static' | 'force-dynamic' | 'auto'`. Implicit auto-detection has surprised many people; an explicit value documents intent.
- **`revalidatePath` / `revalidateTag` after mutations** in Server Actions. Without it, the page keeps showing stale data until the next deploy or fetch.

## Common false alarms

- **"Server Components are slow"** — almost always a waterfall (sequential awaits inside an RSC), not RSC overhead. Profile with `next build --profile` or check the Server Components flame graph in Next devtools.
- **"I need `'use client'` on this whole page"** — almost never. Only the interactive leaf needs it. Pull the boundary down; pass server data in as props.
- **"`force-dynamic` will fix the stale data"** — usually it just hides the real cache key bug. Find the fetch with wrong revalidation or the missing `revalidatePath` call.
- **"Server Actions are like internal helper functions"** — they're public endpoints exposed at a generated URL. Auth + validate every one.
- **"`React.cache` will fix cross-request duplication"** — no, `React.cache` is per-request only. Use `unstable_cache` or an external store (Redis / LRU) for cross-request.
- **"Adding `cache: 'no-store'` is the safe default"** — that opts every fetch into dynamic rendering and disables ISR. Pick freshness intentionally.

## NEVER

- **NEVER** fetch the same data twice in a single request without `React.cache` wrapping the fetch. Two RSCs that need the user → both call `getUser()` → 2× DB hits per request. → `server-cache-react`.
- **NEVER** serialize entire DB records into client component props. The client gets `{ name, avatar }` but you ship `{ id, name, email, password_hash, created_at, ...30 fields }`. Bandwidth + leak risk. → `server-serialization`, `server-dedup-props`.
- **NEVER** add `'use client'` at the page level "to be safe". You silently move the entire tree into the client bundle. → keep boundaries deep; pass server data as props.
- **NEVER** use `cache: 'no-store'` as a project default. Every fetch turns the route dynamic, defeats ISR, and slows cold loads. → pick freshness per fetch.
- **NEVER** skip auth in a Server Action because "the form is internal". Server Actions are reachable as POST requests by anyone with the URL. → `server-auth-actions`.
- **NEVER** block the response on non-critical work (logging, analytics, secondary writes). → wrap in `after()` so it runs after the response is sent.
- **NEVER** hand-roll fetch dedup with `Map` / module-level cache in RSC. `React.cache` already does it correctly with the right scope. → `server-cache-react`.
- **NEVER** fetch in a parent RSC then `await` again in a child RSC for related data when both could fetch in parallel. Restructure the tree to colocate parallel fetches. → `server-parallel-fetching`.
- **NEVER** import a heavy client widget (chart, editor, map) at the top of a page that doesn't always render it. → `bundle-dynamic-imports` with `next/dynamic({ ssr: false })`.
- **NEVER** mutate without `revalidatePath` / `revalidateTag` in Server Actions — UI shows stale data until the cache happens to expire.

## Scenario → Rules

- **RSC page does 5 sequential database calls:**
  Server Performance + Server Waterfalls — `server-cache-react`, `server-parallel-fetching`, `async-parallel`.

- **First-byte time fast, but page hydrates slowly:**
  Bundle + Hydration — `bundle-dynamic-imports`, `bundle-defer-third-party`, `'use client'` placement audit.

- **Form mutation succeeds but UI doesn't update:**
  App Router Patterns — `revalidatePath` / `revalidateTag` after the mutation; or use `useOptimistic` for instant feedback.

- **Logging delays response by 200ms after every request:**
  `server-after-nonblocking` — wrap in `after(() => log(...))`.

- **Same `getCurrentUser()` runs 3× per request (header, sidebar, page):**
  `server-cache-react` — wrap the function in `cache()` from React.

- **Hydration warning about timestamp mismatch:**
  Hydration — `rendering-hydration-suppress-warning` on the affected element only; or render the timestamp client-only via a `useEffect` after mount.
