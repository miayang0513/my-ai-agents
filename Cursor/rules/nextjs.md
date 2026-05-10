---
paths:
  - "**/app/**/*.ts"
  - "**/app/**/*.tsx"
  - "**/pages/**/*.ts"
  - "**/pages/**/*.tsx"
  - "**/next.config.{js,mjs,ts}"
  - "**/middleware.ts"
---

# Next.js (App Router)

Defaults for Next.js App Router code. For perf-focused work (Server Components, server caching, RSC serialization, server waterfalls, hydration), invoke the `nextjs` skill.

- **Server Components by default.** Only mark `"use client"` when interactivity, hooks, or browser APIs require it. Push the boundary down to leaves so layouts/headers stay server-rendered.
- **Server Actions for mutations.** Route Handlers (`app/api/`) only when integrating with external services or non-form clients. Always check auth + validate input inside actions — clients can call them directly via the discovered URL.
- **Mark dynamic behavior explicitly** at the segment level: `export const dynamic = 'force-static' | 'force-dynamic'`. Implicit defaults bite later when one `cookies()` call silently makes a whole route dynamic.
- **`error.tsx` + Suspense boundaries** instead of hand-rolled loading/error flags. Let the framework handle the streaming.
- **Use `next/image`, `next/font`, `next/dynamic`** — don't reach for raw `<img>` / `@font-face` / dynamic `import()` first.
- **Cache API hygiene:** `unstable_cache` for cross-request, `cache()` (from `react`) for per-request dedup, `revalidatePath` / `revalidateTag` after mutations.

Conflicts with project conventions → project wins.
