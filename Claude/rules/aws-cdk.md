---
paths:
  - "**/cdk.json"
  - "**/cdk.context.json"
  - "**/bin/*.ts"
  - "**/lib/*-stack.ts"
  - "**/lib/**/*-stack.ts"
  - "**/cdk/**/*.ts"
  - "**/infra/**/*.ts"
---

# AWS CDK

Defaults for AWS CDK projects. Triggers on common CDK file layouts (`bin/`, `lib/*-stack.ts`, `cdk/`, `infra/`).

- **CDK v2 only** (`aws-cdk-lib`). Never v1 / `@aws-cdk/*` — EOL, no security patches.
- **Avoid hardcoded physical names** (bucket names, table names, function names). CloudFormation *replaces* a resource if its physical name changes; suffix with `${stage}` or pull from env so the same stack deploys cleanly to multiple environments. Logical IDs are fine to be stable.
- **Lambda config from a typed module or env**, not magic numbers scattered across stack files. Timeout / memory / VPC / env should live in one place.
- **`NodejsFunction` for TypeScript Lambdas.** Set `bundling: { minify: true, sourceMap: true }`. Use `commandHooks` only when you genuinely need to shell out at build (asset prep, native deps).
- **Tag every stateful resource** with `Project`, `Environment`, `Owner`, `CostCenter`. Untagged AWS resources are unauditable later — and finance can't bill them back.
- **Run `cdk-nag`** against stacks handling production data. Catches IAM-too-broad, missing encryption, and unrotated secrets before code review does.
- **Stack composition over inheritance.** Compose constructs (`new MyApi(this, 'Api', { ... })`); avoid deep `extends Stack` hierarchies that bind unrelated resources together.
- **Plan before apply.** Surface `cdk diff` output before `cdk deploy` — never apply unprompted.

Conflicts with project conventions → project wins.
