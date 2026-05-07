# React Rules — by Category

The full rule list for the `react` skill. Load when targeting a specific category. Each rule has a one-line definition + when to apply.

---

## 1. Bundle Size Optimization (CRITICAL — `bundle-`)

- **`bundle-barrel-imports`** — Import directly from the source file, not from a barrel `index.ts`. Bundlers can't reliably tree-shake through re-exports. Apply when: importing from a UI library or shared package.
- **`bundle-dynamic-imports`** — `React.lazy()` (or `next/dynamic` in Next.js) for heavy components only used after a user action. Apply when: a component >50KB gzipped is rendered lazily (modal, editor, chart, code highlighter).
- **`bundle-defer-third-party`** — Load analytics / logging / tag managers *after* hydration, not before first paint. Apply when: any non-critical third-party script.
- **`bundle-conditional`** — Load a feature module only when the feature activates. Apply when: an integration is gated by a flag or admin role.
- **`bundle-preload`** — `rel="preload"` or `<Link onMouseEnter={prefetch}>` for predicted next nav. Apply when: a single dominant flow exists (sign-up CTA, primary product card).

## 2. Eliminating Waterfalls (CRITICAL — `async-`)

- **`async-defer-await`** — Move `await` into the branch that actually consumes the value. Apply when: a value is awaited before a conditional that may not need it.
- **`async-parallel`** — `Promise.all([...])` for independent awaits. Apply when: two or more `await`s in sequence on independent promises.
- **`async-dependencies`** — `better-all` (or hand-rolled) for partial dependency graphs (some promises depend on results of earlier ones, others are independent). Apply when: 3+ promises with mixed dependencies.
- **`async-suspense-boundaries`** — Wrap async children in `<Suspense fallback>` to stream content as it resolves. Apply when: page has slow + fast async sections; fast can render first.

## 3. Client-Side Data Fetching (HIGH — `client-`)

- **`client-swr-dedup`** — Use SWR / React Query for automatic request dedup + revalidation. Apply when: multiple components fetch the same endpoint, or you'd otherwise reach for a custom cache.
- **`client-event-listeners`** — Single global listener with subscriber pattern, not N listeners across components. Apply when: scroll, resize, visibilitychange, online/offline.
- **`client-passive-event-listeners`** — `{ passive: true }` for scroll / wheel / touchmove. Apply when: any non-blocking input listener.
- **`client-localstorage-schema`** — Version your localStorage keys + minimize stored data. Apply when: persisting state across sessions.

## 4. Re-render Optimization (MEDIUM — `rerender-`)

- **`rerender-defer-reads`** — Don't subscribe to state used only in callbacks; access via ref / context selector. Apply when: a component re-renders on every keystroke but uses the value only `onSubmit`.
- **`rerender-memo`** — Extract expensive subtrees into `memo()`'d children. Apply when: a heavy child re-renders because of an unrelated parent state change.
- **`rerender-memo-with-default-value`** — Hoist non-primitive default props (objects, arrays, functions) to module scope or memoize them. Apply when: child component receives `prop={[]}` or `prop={{}}` inline.
- **`rerender-dependencies`** — Use primitive deps in `useEffect` / `useMemo`; derive primitives from objects. Apply when: a dep array contains an object or array literal.
- **`rerender-derived-state`** — Subscribe to a derived boolean (`useStore(s => s.count > 0)`) not the raw value. Apply when: re-rendering on raw value but only using a derived condition.
- **`rerender-derived-state-no-effect`** — Compute derived state during render, not in `useEffect` + `setState`. Apply when: an effect's only job is to compute one state from another.
- **`rerender-functional-setstate`** — `setX(prev => ...)` for callbacks that don't need to subscribe to the current value. Apply when: callback identity matters and you don't want it to change every render.
- **`rerender-lazy-state-init`** — `useState(() => expensive())` instead of `useState(expensive())`. Apply when: initial state requires a non-trivial computation.
- **`rerender-simple-expression-in-memo`** — Don't memoize trivial primitives or simple math. Apply when: tempted to wrap `a + b` in `useMemo`.
- **`rerender-move-effect-to-event`** — Move "respond to user click" logic from `useEffect` into the `onClick` handler. Apply when: an effect's dep array includes a value only changed by user interaction.
- **`rerender-transitions`** — `startTransition(() => setX(...))` for non-urgent updates (search results, filters). Apply when: a state update causes a heavy re-render that could yield to user input.
- **`rerender-use-ref-transient-values`** — `useRef` for values that change frequently but don't need to render (drag positions, timers, counts). Apply when: storing a value that's read in callbacks but never displayed.

## 5. Rendering Performance (MEDIUM — `rendering-`)

- **`rendering-animate-svg-wrapper`** — Animate the wrapper `div`, not the SVG element. SVG transforms re-trigger paint; CSS transforms on a div don't. Apply when: animating an icon or shape.
- **`rendering-content-visibility`** — `content-visibility: auto` on long off-screen sections. Browser skips layout/paint until scrolled into view. Apply when: page has many sections / cards / posts.
- **`rendering-hoist-jsx`** — Extract static JSX outside the component body. Apply when: a JSX subtree doesn't depend on props or state.
- **`rendering-svg-precision`** — Trim SVG coordinate precision (3 decimals max). Apply when: importing icons from a designer's export with 6+ decimal places.
- **`rendering-hydration-no-flicker`** — Inline-script `theme` / locale before React hydrates to prevent flash. Apply when: server can't compute the value (user preferences, timezone).
- **`rendering-hydration-suppress-warning`** — `suppressHydrationWarning` only on attributes you *expect* to differ (timestamps, locale-formatted dates). Apply when: a known unavoidable mismatch generates console noise.
- **`rendering-activity`** — `<Activity mode="hidden">` for show/hide instead of mount/unmount. Apply when: a panel or modal is opened repeatedly with internal state.
- **`rendering-conditional-render`** — Ternary, not `&&`. `0 && <X/>` renders `0`. Apply when: a falsy non-boolean might leak into the tree.
- **`rendering-usetransition-loading`** — `useTransition` for "loading" state instead of a manual `isLoading` flag. Lets React keep the previous UI visible during the update. Apply when: filtering / sorting a list.

## 6. JavaScript Performance (LOW-MEDIUM — `js-`)

- **`js-batch-dom-css`** — Group CSS changes via class toggle or `cssText`. Apply when: changing 3+ styles imperatively.
- **`js-index-maps`** — `Map` for repeated lookups by key. Apply when: searching the same array more than once.
- **`js-cache-property-access`** — Cache `obj.prop` in a local variable inside loops. Apply when: a property is accessed in every loop iteration.
- **`js-cache-function-results`** — Module-level `Map` cache for pure expensive functions. Apply when: function is called repeatedly with the same args (string parsing, regex compilation).
- **`js-cache-storage`** — Cache `localStorage.getItem` reads in a module variable. Apply when: a key is read on every render.
- **`js-combine-iterations`** — Fuse `filter().map()` into one `for` loop. Apply when: chained array methods on a hot path with >10k items.
- **`js-length-check-first`** — Check `array.length` before any expensive comparison. Apply when: short-circuiting an empty case.
- **`js-early-exit`** — Return early when a condition is decided. Apply when: nested conditions can be flattened.
- **`js-hoist-regexp`** — Hoist `RegExp` instances out of loops / functions. Apply when: a regex literal is constructed inside a hot function.
- **`js-min-max-loop`** — Single loop for min/max, never `arr.sort()[0]`. Apply when: only need extreme values.
- **`js-set-map-lookups`** — `Set` / `Map` for O(1) membership / lookup, not `array.includes`. Apply when: lookup happens >3 times on the same array.
- **`js-tosorted-immutable`** — `array.toSorted()` over `[...array].sort()`. Apply when: need a sorted copy without mutating.

## 7. Advanced Patterns (LOW — `advanced-`)

- **`advanced-event-handler-refs`** — Store handlers in refs to keep their identity stable. Apply when: passing a handler to a deeply memoized child where re-renders matter more than handler freshness.
- **`advanced-init-once`** — `if (!initialized) init()` at module scope. Apply when: app needs a single global setup.
- **`advanced-use-latest`** — `useLatest` (custom hook) for stable callback refs reading the latest closure value. Apply when: an effect callback needs to read fresh state without the dep array invalidating.

---

## Cross-cutting: when a rule's category is wrong for your context

Some rules apply to React broadly (`async-parallel`) and also fire for Server Components (which live in the `nextjs` skill). If you're in a Next.js project and the bottleneck is server-side, switch to the `nextjs` skill. If client-only React, the rules above cover it.
