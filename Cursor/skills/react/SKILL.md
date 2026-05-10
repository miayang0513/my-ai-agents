---
name: react
description: High-impact React performance rules — eliminate re-render storms, cut bundle size, fix client waterfalls, dedupe client requests, optimize JavaScript hot paths. Trigger on "react performance", "re-render", "memo", "useMemo", "useCallback", "useEffect data fetching", "Suspense", "useTransition", "bundle too big", "code splitting", "jank", "slow component", "long list", "scroll performance", or whenever profiling/diagnosing/refactoring a React app for speed. Mirrors the React parts of the Vercel agent-skills react-best-practices guide; for Next.js App Router specifics (Server Components, Server Actions, server caching, RSC), use the `nextjs` skill instead.
---

# React Performance

Performance optimization rules for React, prioritized by end-to-end impact. Use the **mini decision flow** to pick a category before applying rules — never micro-optimize before fixing higher-priority bottlenecks.

**Source:** [vercel-labs/agent-skills — react-best-practices](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices). Detailed rule reference lives in `references/rules.md`; concrete spot-and-fix recipes in `references/recipes.md`.

## Mindset

Apply rules in this order — reordering wastes effort:

1. **Bundle size** — strip unused client JS *before* tuning rendering. Bundle savings affect every user, every load.
2. **Eliminate waterfalls** — fix sequential awaits *before* memoizing anything. Network beats CPU.
3. **Stabilize client data** — dedupe requests, listeners, storage reads. Cheap fixes, big wins.
4. **Tune re-renders** — only after the higher tiers are clean. Memoization often *hurts* if applied wrong.
5. **Then rendering / JS perf** — long-tail polish.

Identify the **bottleneck type first** — bundle, network, render, hydration, or JS hot path — then pick the matching category. Don't shotgun memoization at every component.

## Mini decision flow

1. Initial load / first paint slow, or hydration time high?
   → **Bundle Size** + **Rendering Performance**.
2. Slowness from many client API calls or repeated subscriptions?
   → **Client-Side Data Fetching**.
3. Janky interactions (typing, scrolling, clicking) — especially on low-end devices?
   → **Re-render Optimization** + **Rendering Performance**.
4. Bottleneck is heavy JS (tight loops, big computations) — not network or rendering?
   → **JavaScript Performance**.
5. Unsure → start with **Bundle Size**, then **Re-render**.

## Categories

| # | Category | Impact | Prefix | When |
|---|---|---|---|---|
| 1 | Bundle Size Optimization | CRITICAL | `bundle-` | Initial load slow, large client JS |
| 2 | Eliminating Waterfalls | CRITICAL | `async-` | Sequential awaits on independent work |
| 3 | Client-Side Data Fetching | HIGH | `client-` | Repeated client requests, multiple listeners |
| 4 | Re-render Optimization | MEDIUM | `rerender-` | DevTools shows excess re-renders |
| 5 | Rendering Performance | MEDIUM | `rendering-` | Slow paint/layout, jank, hydration warnings |
| 6 | JavaScript Performance | LOW-MEDIUM | `js-` | Pure JS bottleneck (loops, lookups) |
| 7 | Advanced Patterns | LOW | `advanced-` | Higher tiers clean; fine-grained handler control |

**MANDATORY** when targeting a specific category: load `references/rules.md` and read the matching prefix block. The category labels above don't tell you *what to change* — the rules do.

**MANDATORY** when applying any fix: load `references/recipes.md` and copy the canonical patch shape for the matching rule. Don't write transformation code from memory — wrong-shaped memoization or wrong-shaped Suspense placement is worse than no fix.

**Do NOT load** the upstream AGENTS.md unless doing a full audit against all 58 rules. The category overview + `rules.md` + `recipes.md` cover the React-only subset.

## When NOT to optimize

Cheap perf wins are real. So is engineering time. Skip the optimization when:

- **The page already feels fast on the slowest device you ship to.** Memoization isn't free — it adds dependency arrays that drift, hides real bugs, and increases review surface. A measured 20% speedup nobody perceives is a maintenance liability.
- **You can't reproduce the slowness.** A re-render storm in DevTools that doesn't translate to dropped frames or stuttering input is reconciliation cost, which is cheap. Ship the change, don't optimize.
- **The bottleneck is a single hot product flow you're about to redesign.** Don't pay for perf work the redesign deletes.
- **The fix requires a significantly more complex API.** A `Provider` + `useStore` + selector setup to avoid one parent re-render is rarely worth it. Same for hand-rolled refs to "save a render" — the cognitive cost outlives the benefit.
- **The library you're optimizing around is moving fast.** React Compiler is rolling out — most `useMemo` / `useCallback` calls written today will be undone in a year. Hold the line on memoization until profiling forces it.

## First rule to try per category

When you've identified the right category, this is the rule with the highest leverage-to-effort ratio. Start here:

| Category | Try first | Why |
|---|---|---|
| Bundle Size | `bundle-barrel-imports` | One-line fix per import; immediate bundle reduction |
| Eliminating Waterfalls | `async-parallel` | `Promise.all([...])` — usually 1 line, halves latency |
| Client-Side Data Fetching | `client-swr-dedup` | Drop-in replacement for ad-hoc fetch; gets dedup + revalidation free |
| Re-render Optimization | `rerender-defer-reads` | No-cost win — fixing the subscription is cheaper than adding `memo` |
| Rendering Performance | `rendering-content-visibility` | Pure CSS, zero JS, helps long pages immediately |
| JavaScript Performance | `js-set-map-lookups` | One-line `new Set(...)` — wins compound with collection size |
| Advanced Patterns | (skip unless higher tiers are clean) | These are micro-optimizations |

## Common false alarms

These misdiagnoses waste a session — verify before applying any fix:

- **"This component re-renders too much"** — first check whether the re-render actually causes a paint or expensive child render. React reconciliation is cheap; if the DOM doesn't change and children are memoized, `memo` on the parent adds overhead without benefit.
- **"useMemo will fix this"** — memoizing trivial primitives or simple expressions costs more (equality + closure allocation) than the recompute. Profile before memoizing — assume React Compiler.
- **"Adding `key` will fix the list"** — `key={index}` on a reorderable list *causes* state-loss bugs, doesn't prevent them. React reuses DOM nodes by key; with index keys, state attaches to the wrong row after a sort. Use a stable id.
- **"`useEffect` is the right place for this"** — for derived state, derive during render. For one-time work, run at module scope or in an event handler. For data fetching, use SWR / React Query (or RSC if Next.js). Effects are the last resort, not the default.
- **"This `Suspense` boundary will speed up the page"** — a boundary high in the tree only helps if the work inside *actually* yields (lazy import, async data). Wrapping synchronous work in `Suspense` does nothing.
- **"Server Component is slow"** — if you're in a Next.js project, this is almost always a server-side waterfall, not React rendering. Switch to the `nextjs` skill.

## NEVER

These reliably tank performance — flag on sight:

- **NEVER** import large UI / feature bundles via barrel files when only a few components are used. Bundlers can't tree-shake aggressively through re-export chains; you ship the whole bundle. → `bundle-barrel-imports`, `bundle-dynamic-imports`.
- **NEVER** sequential awaits for independent async work — every awaited promise blocks the next. → `async-parallel`, `async-defer-await`.
- **NEVER** attach multiple global event listeners (scroll / resize / visibility) for the same event without deduplication — handlers stack across components and fire N times per scroll, each forcing a layout. → `client-event-listeners`, `client-passive-event-listeners`.
- **NEVER** use state or effects for values derivable during render or storable in refs. Effects re-run after every render and cause an extra commit; derive-during-render runs once. → `rerender-derived-state`, `rerender-derived-state-no-effect`, `rerender-use-ref-transient-values`.
- **NEVER** memoize trivial primitives or simple expressions. The dependency comparison + closure allocation costs more than recomputing `a + b`. → `rerender-simple-expression-in-memo`.
- **NEVER** subscribe to state that's only read inside callbacks. The component re-renders on every state change even when the rendered output doesn't depend on it. → `rerender-defer-reads`.
- **NEVER** use `key={index}` on lists that can reorder, filter, or insert at the start. State binds to the wrong row, inputs lose focus, animations play backwards. → use a stable id.
- **NEVER** load analytics / logging / tracking SDKs synchronously on first paint — they delay hydration and aren't critical until after interaction. → `bundle-defer-third-party`.
- **NEVER** skip `passive: true` on scroll / wheel / touchmove listeners — without it, the browser can't start scrolling until your handler returns, causing visible jank. → `client-passive-event-listeners`.
- **NEVER** reach for Redux / Zustand / a global store for state that's only read in one subtree. Component state + composition + context handles 90% of cases; a store is debt you carry forever for no perf win.
- **NEVER** add `'use client'` reflexively because "this file uses a hook". If the hook is in a leaf component, only that component needs the directive — pulling it up traps the parents into the client bundle.

## Scenario → Rules

- **Large JS bundle / slow hydration on first load:**
  Bundle Size + Rendering Performance — `bundle-barrel-imports`, `bundle-dynamic-imports`, `bundle-defer-third-party`, `rendering-hydration-suppress-warning`.

- **Janky interactions on low-end devices:**
  Re-render + Rendering Performance — `rerender-memo`, `rerender-defer-reads`, `rerender-transitions`, `rendering-content-visibility`, `rendering-usetransition-loading`.

- **Long lists that scroll poorly:**
  Rendering Performance — `rendering-content-visibility`, `rendering-hoist-jsx`. (For >1000 rows, virtualize with `react-virtuoso` / `@tanstack/react-virtual` — outside this skill's scope.)

- **Heavy client-side computation / tight loops:**
  JavaScript Performance — `js-index-maps`, `js-combine-iterations`, `js-cache-function-results`, `js-tosorted-immutable`, `js-hoist-regexp`.

- **Multiple components fetch the same endpoint:**
  Client-Side Data Fetching — `client-swr-dedup`. (Or React Query — same dedup behavior.)

- **Form input feels laggy as the user types:**
  Re-render Optimization — `rerender-transitions` (wrap the dependent expensive update in `startTransition`), `rerender-defer-reads` (don't subscribe parent to the input value).
