---
paths:
  - "**/handlers/**/*.{ts,js}"
  - "**/lambda/**/*.{ts,js}"
  - "**/lambdas/**/*.{ts,js}"
  - "**/functions/**/*.{ts,js}"
  - "**/*.handler.{ts,js}"
  - "**/serverless.{ts,js,yml,yaml}"
---

# Node + Lambda / Serverless

Defaults for Lambda-style serverless handlers. Triggers on common server-handler path patterns; if your project uses a different layout, add a project-level rule.

- **Node LTS only.** 20 or 22. Avoid runtimes EOL'ing within the next 12 months.
- **AWS SDK v3, not v2.** v2 isn't bundled with Node 18+ Lambda runtimes and is in maintenance mode.
- **Connection reuse at module scope.** Instantiate DB / HTTP / SDK clients *outside* the handler — module scope persists across invocations on the same execution environment. Per-handler instantiation multiplies cold-start cost and connection overhead.
- **Lazy init for top-level I/O that can fail** (secret loading, remote config). Wrap in a memoized promise inside the handler — don't crash a cold start because a dependency is briefly down.
- **Cold-start hygiene.** Minimize bundle size — direct imports over barrels, tree-shake-friendly libs. With CDK `NodejsFunction`, set `bundling: { minify: true, sourceMap: true }`. Lazy-load anything not on the hot path.
- **Type the handler signature.** Event / context / return types at the function signature; don't cast inside the body.

Conflicts with project conventions → project wins.
