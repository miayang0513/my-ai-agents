---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
---

# React

Defaults for any React component file. For perf-focused work (re-renders, bundle, hydration, hot paths), invoke the `react` skill — it has the prioritized rules + decision flow + spot-and-fix recipes.

- **Function components only.** No class components in new code.
- **Don't use `useEffect` for data fetching.** Fetch on the server when possible; otherwise use a real client data layer (SWR / React Query). `useEffect` for fetching = race conditions + waterfalls + double-fires under StrictMode.
- **Embrace React 19 actions and form-action APIs** over manual `useState` + `onSubmit` plumbing.
- **Treat `useMemo` / `useCallback` as a measured optimization, not a default.** Assume React Compiler. Memoizing trivial primitives is pure noise.
- **Stable `key` props on list items.** Never the array index when items can reorder, get inserted, or get removed.
- **No comments unless they explain a non-obvious WHY** (constraint, invariant, workaround). Never describe what the JSX does.

Conflicts with project conventions → project wins.
