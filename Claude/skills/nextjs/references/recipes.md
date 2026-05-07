# Next.js Recipes — Spot & Fix

Concrete spot-and-fix snippets for the highest-leverage Next.js rules. Load when applying a fix — copy the patch shape, don't reinvent. APIs evolve between Next versions; the recipes below target Next 15+ App Router. For Next 14: `after` is named `unstable_after` (rename the import); `unstable_cache` is unchanged.

Each recipe: **Spot** → **Why bad** → **Fix**.

---

## server-cache-react (per-request dedup)

**Spot:** `getCurrentUser()` is called from `layout.tsx`, `Sidebar.tsx`, and the page itself. Three DB hits per request.

**Fix:**
```ts
// lib/user.ts
import { cache } from 'react';

export const getCurrentUser = cache(async () => {
  const session = await auth();
  if (!session) return null;
  return db.user.findUnique({ where: { id: session.userId } });
});
```
`cache()` is per-request — the second call within a request returns the same Promise. Doesn't help across requests; for that use `unstable_cache` or external LRU.

---

## server-cache-lru (cross-request)

**Spot:** Hot-path query that's safe to be a few seconds stale, hit thousands of times.

**Fix (Next built-in):**
```ts
import { unstable_cache } from 'next/cache';

export const getProductCatalog = unstable_cache(
  async () => db.product.findMany({ where: { active: true } }),
  ['product-catalog'],          // cache key parts
  { revalidate: 60, tags: ['products'] }
);
```
Invalidate with `revalidateTag('products')` after a mutation. For finer-grained cross-request caching (multi-region, distributed), use Redis / Upstash directly.

---

## server-parallel-fetching

**Spot:** RSC awaits user, *then* awaits posts:
```tsx
export default async function Page({ params }) {
  const user = await getUser(params.id);    // 200ms
  const posts = await getPosts(params.id);  // 200ms
  return <Profile user={user} posts={posts} />;
}
```
Total: 400ms. The two fetches are independent.

**Fix:**
```tsx
export default async function Page({ params }) {
  const [user, posts] = await Promise.all([
    getUser(params.id),
    getPosts(params.id),
  ]);
  return <Profile user={user} posts={posts} />;
}
```
Total: 200ms.

---

## async-suspense-boundaries (streaming)

**Spot:** Page has a fast header + a slow feed. User sees a blank screen until both resolve.

**Fix:**
```tsx
export default function Page() {
  return (
    <>
      <Header />
      <Suspense fallback={<FeedSkeleton />}>
        <SlowFeed />
      </Suspense>
    </>
  );
}
```
Header + skeleton stream immediately; `<SlowFeed>` swaps in when its async work resolves. The page's shell is interactive faster.

---

## server-auth-actions

**Spot:** A Server Action with no auth check.

```ts
'use server';
export async function deletePost(id: string) {
  await db.post.delete({ where: { id } });
}
```
Anyone who finds the action's URL can call it.

**Fix:**
```ts
'use server';
import { auth } from '@/lib/auth';
import { db } from '@/lib/db';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';

const Input = z.object({ id: z.string().uuid() });

export async function deletePost(raw: unknown) {
  const session = await auth();
  if (!session) throw new Error('UNAUTHORIZED');

  const { id } = Input.parse(raw);

  const post = await db.post.findUnique({ where: { id } });
  if (post?.authorId !== session.userId) throw new Error('FORBIDDEN');

  await db.post.delete({ where: { id } });
  revalidatePath(`/users/${session.userId}/posts`);
}
```

---

## server-serialization

**Spot:** Passing `user` (full DB record, 30 fields including `password_hash`) to a client component that displays `name` + `avatar`.

**Why bad:** Every field is serialized into the HTML and the RSC payload. Bandwidth + leak risk.

**Fix:**
```tsx
const { name, avatar } = await getUser();
return <UserChip name={name} avatar={avatar} />;
```
Pass only the fields the client needs. Or define a `pickPublicUser(user)` helper at the data layer.

---

## server-after-nonblocking

**Spot:** Every request blocks on logging:
```ts
export async function POST(req) {
  const result = await handleRequest(req);
  await logEvent('request_handled', result);  // adds 80ms to TTFB
  return Response.json(result);
}
```

**Fix (Next 15+):**
```ts
import { after } from 'next/server';
import type { NextRequest } from 'next/server';

export async function POST(req: NextRequest) {
  const result = await handleRequest(req);
  after(() => logEvent('request_handled', result));
  return Response.json(result);
}
```
Response goes out immediately; `logEvent` runs after. On Next 14, import as `unstable_after` from `next/server`.

---

## bundle-dynamic-imports (Next-specific)

**Spot:** Heavy client component imported at the top of a page that only renders it on click.

**Fix:**
```tsx
// Before
import HeavyEditor from '@/components/HeavyEditor';

// After
import dynamic from 'next/dynamic';
const HeavyEditor = dynamic(() => import('@/components/HeavyEditor'), {
  loading: () => <EditorSkeleton />,
  ssr: false,  // only if the component truly can't render server-side
});
```
Only set `ssr: false` when needed — disabling SSR forfeits server-rendered content for that subtree.

---

## 'use client' boundary placement

**Spot:**
```tsx
// app/dashboard/page.tsx
'use client';

import { Sidebar } from '@/components/Sidebar';
import { Header } from '@/components/Header';
import { Counter } from '@/components/Counter';

export default function Dashboard() { /* ... */ }
```
The whole page is now client. Sidebar, Header (if they don't need interactivity) get pulled into the client bundle unnecessarily.

**Fix:** push `'use client'` down to the leaf:
```tsx
// app/dashboard/page.tsx — Server Component
import { Sidebar } from '@/components/Sidebar';
import { Header } from '@/components/Header';
import { Counter } from '@/components/Counter';  // this one is 'use client'

export default function Dashboard() { /* ... */ }
```
Now only `Counter` ships to the client. Sidebar + Header render on the server.

---

## revalidatePath / revalidateTag after mutation

**Spot:** Server Action updates a post but the page still shows the old title.

**Fix:**
```ts
'use server';
import { revalidatePath } from 'next/cache';

export async function updatePost(id: string, data: PostInput) {
  await db.post.update({ where: { id }, data });
  revalidatePath(`/posts/${id}`);
  revalidatePath('/posts');  // and the index
}
```
Or with tags:
```ts
import { revalidateTag } from 'next/cache';

revalidateTag('posts');  // pairs with unstable_cache({ tags: ['posts'] })
```

---

## rendering-hydration-no-flicker (theme example)

**Spot:** Page renders in light mode for ~200ms, then snaps to dark. The user's theme preference lives in `localStorage`.

**Fix (inline script in `<head>`):**
```tsx
// app/layout.tsx
const themeScript = `
  try {
    const stored = localStorage.getItem('theme');
    const theme = stored === 'dark' || stored === 'light'
      ? stored
      : (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    document.documentElement.dataset.theme = theme;
  } catch (_) {}
`;

export default function RootLayout({ children }) {
  return (
    <html>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeScript }} />
      </head>
      <body>{children}</body>
    </html>
  );
}
```
Theme is applied before React hydrates. No flash.

---

## rendering-hydration-suppress-warning (scoped)

**Spot:** Console warning: "Text content did not match. Server: '12:34:56' Client: '12:34:57'." for a `<time>` showing now.

**Fix:**
```tsx
<time suppressHydrationWarning>{new Date().toLocaleTimeString()}</time>
```
Apply to the *specific* mismatching element. Never put `suppressHydrationWarning` on `<html>` or `<body>` — that hides legit hydration bugs.
