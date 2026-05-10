# React Recipes — Spot & Fix

Concrete spot-and-fix snippets for the highest-leverage rules. Load when applying a fix — copy the patch shape, don't reinvent it.

Each recipe: **Spot** (what to grep for / DevTools sign) → **Why bad** → **Fix** (canonical patch).

---

## bundle-barrel-imports

**Spot:** `import { Button } from '@org/ui'` where `@org/ui/index.ts` re-exports 200 components.

**Why bad:** Tree-shaking through barrels is fragile. Many bundlers ship the full barrel even if only one symbol is used.

**Fix:**
```ts
// Before
import { Button, Modal } from '@org/ui';

// After
import { Button } from '@org/ui/Button';
import { Modal } from '@org/ui/Modal';
```

If the package doesn't expose deep paths, add `modularizeImports` (Next.js) or a Babel plugin to rewrite at build time.

---

## bundle-dynamic-imports

**Spot:** Heavy component (`react-pdf`, `monaco-editor`, chart libs, rich text editor) imported at the top of a page that doesn't always render it.

**Fix:**
```tsx
import { lazy, Suspense } from 'react';

const HeavyChart = lazy(() => import('./HeavyChart'));

export function Dashboard({ showChart }: { showChart: boolean }) {
  return (
    <>
      {showChart && (
        <Suspense fallback={<ChartSkeleton />}>
          <HeavyChart />
        </Suspense>
      )}
    </>
  );
}
```
In Next.js, prefer `next/dynamic` over `React.lazy` — see the `nextjs` skill's recipe.

---

## async-parallel

**Spot:** `const a = await x(); const b = await y();` where `y` doesn't read `a`.

**Why bad:** `y` waits for `x` to finish even though it doesn't need to. Latency = `x + y` instead of `max(x, y)`.

**Fix:**
```ts
// Before
const user = await getUser(id);
const posts = await getPosts(id);

// After
const [user, posts] = await Promise.all([
  getUser(id),
  getPosts(id),
]);
```

---

## async-suspense-boundaries

**Spot:** Page renders nothing until *all* async work resolves; user sees a blank screen for 2s.

**Fix:**
```tsx
<Suspense fallback={<HeaderSkeleton />}>
  <SlowHeader />          {/* streams in independently */}
</Suspense>
<Suspense fallback={<FeedSkeleton />}>
  <SlowFeed />
</Suspense>
```
Each boundary streams as soon as its content resolves. Keep boundaries close to the slow work, not at the top of the tree.

---

## rerender-derived-state-no-effect

**Spot:**
```tsx
useEffect(() => {
  setFullName(`${first} ${last}`);
}, [first, last]);
```

**Why bad:** Triggers an extra render + commit. The derived value is already computable during render.

**Fix:**
```tsx
const fullName = `${first} ${last}`;
```
Or `useMemo` only if the computation is expensive.

---

## rerender-defer-reads

**Spot:** Component re-renders on every keystroke even though it only reads the value `onSubmit`.

```tsx
// Before — subscribes to `input`, so every change re-renders this component
const value = useStore((s) => s.input);
return <Form onSubmit={() => save(value)} />;
```

**Fix (Zustand — read on demand via `getState`):**
```tsx
import { useStore } from '@/store';  // your Zustand store

// No selector → no subscription → no re-renders for this state.
return <Form onSubmit={() => save(useStore.getState().input)} />;
```

**Fix (vanilla React — `useRef` synced via `useEffect`):**
```tsx
import { useEffect, useRef } from 'react';

const [input, setInput] = useState('');
const inputRef = useRef(input);
useEffect(() => { inputRef.current = input; }, [input]);

return <Form onSubmit={() => save(inputRef.current)} />;
```
Use the Zustand variant when state lives in a store; the ref variant for local React state where the component genuinely needs to re-render for the input but not for the consumer.

---

## rerender-transitions

**Spot:** A search input feels laggy because every keystroke re-renders a 5000-row filtered list.

**Fix:**
```tsx
import { useState, useTransition, type ChangeEvent } from 'react';

function Search() {
  const [query, setQuery] = useState('');
  const [deferredQuery, setDeferredQuery] = useState('');
  const [, startTransition] = useTransition();

  const onChange = (e: ChangeEvent<HTMLInputElement>) => {
    setQuery(e.target.value);                                  // urgent — input stays responsive
    startTransition(() => setDeferredQuery(e.target.value));   // non-urgent — list updates when ready
  };

  return (
    <>
      <input value={query} onChange={onChange} />
      <List query={deferredQuery} />
    </>
  );
}
```
React keeps the old list visible during the transition; the input doesn't drop frames. (`useDeferredValue(query)` is a one-liner alternative if you don't need the `isPending` flag.)

---

## rerender-memo (with the "is it actually re-rendering?" check first)

**Spot:** React DevTools profiler shows a `<HeavyChart />` re-rendering on every parent state change.

**Verify first:** Confirm the chart's *props* actually changed. If they did and the chart is expensive:

**Fix:**
```tsx
import { memo } from 'react';

const HeavyChart = memo(function HeavyChart({ data }: Props) {
  // ...
});
```
Watch for inline object/array props from the parent — they break referential equality and defeat `memo`. Pair with `rerender-memo-with-default-value`.

---

## rendering-content-visibility

**Spot:** A blog index page has 200 article cards; scrolling drops frames.

**Fix:**
```css
.article-card {
  content-visibility: auto;
  contain-intrinsic-size: 280px;  /* approx height; tells layout */
}
```
Browser skips layout + paint for off-screen cards. The `contain-intrinsic-size` prevents scroll-jump as cards enter the viewport.

---

## rendering-conditional-render

**Spot:** `{count && <Badge>{count}</Badge>}` — when `count === 0`, renders the literal `0`.

**Fix:**
```tsx
{count > 0 ? <Badge>{count}</Badge> : null}
```

---

## client-swr-dedup

**Spot:** Three components in different parts of the tree each call `fetch('/api/me')` on mount → 3 network requests.

**Fix:**
```tsx
import useSWR from 'swr';

export const useMe = () => useSWR('/api/me', fetcher);
```
SWR dedupes identical keys within a configurable window (default 2s). React Query has the same behavior with `useQuery({ queryKey: ['me'] })`.

---

## client-passive-event-listeners

**Spot:** A scroll handler somewhere in the app, no `passive` option.

**Fix:**
```ts
window.addEventListener('scroll', onScroll, { passive: true });
```

In React 18+, `onScroll` on a JSX element is already passive. The fix mainly applies to `useEffect`-attached listeners on `window` / `document`.

---

## js-set-map-lookups

**Spot:** `if (allowedRoles.includes(role))` inside a hot path called once per render of every list item.

**Fix:**
```ts
const ALLOWED = new Set(['admin', 'editor', 'viewer']);
// ...
if (ALLOWED.has(role)) { ... }
```
`Set.has` is O(1), `Array.includes` is O(n). The win compounds with list length.
