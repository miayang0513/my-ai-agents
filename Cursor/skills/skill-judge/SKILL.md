---
name: skill-judge
description: Evaluate the quality of an Agent Skill (SKILL.md) against official specifications and produce a structured report. Use when the user asks to review, audit, score, or improve a skill, or compare two skills — phrases like "evaluate this skill", "audit my SKILL.md", "score this skill", "how can I improve this skill", "is this skill well-designed", "compare these skills". Produces 8-dimension scoring (120 points), letter grade A–F, knowledge ratio E:A:R, top-3 prioritized improvements, and detailed analysis of weak dimensions. Core measure is knowledge delta — how much expert-only knowledge the skill provides beyond what Claude already knows.
---

# Skill Judge

**Pattern**: Process (~180 lines, multi-step evaluation procedure with reference files for rubrics, failure patterns, and a worked example).

## Core principle

> **Good Skill = Expert-only Knowledge − What Claude Already Knows**

A skill that mostly restates things Claude already knows is wasting tokens, regardless of polish. The single strongest signal of quality is the **knowledge delta** — what fraction of the content is actually new to Claude.

## Three-layer loading

Skills load in three layers; evaluation must respect this:

```
Layer 1 — Metadata (always loaded)         frontmatter only          ~100 tokens / skill
Layer 2 — SKILL.md body (after triggering) workflow + references     ideal < 300 lines
Layer 3 — Reference files (on demand)      heavy content             no limit
```

Triggering decisions are made on Layer 1 alone. If the description doesn't say WHAT, WHEN, KEYWORDS, the skill is invisible to the agent regardless of how good Layer 2 is.

## Knowledge classification (apply during scan)

| Tag   | Definition                                       | Treatment                          |
| ----- | ------------------------------------------------ | ---------------------------------- |
| `[E]` | Expert — Claude genuinely doesn't know this      | Must keep — this is the value      |
| `[A]` | Activation — Claude knows but may not think of   | Keep if brief — serves as reminder |
| `[R]` | Redundant — Claude definitely knows this         | Delete — wastes tokens             |

Healthy ratios: **>70% E, <20% A, <10% R**. High `[R]` ratio is the strongest single signal of low quality.

## Evaluation protocol

1. **Knowledge delta scan** — read SKILL.md and tag each section as `[E]`/`[A]`/`[R]`. Record the ratio.
2. **Structure analysis** — verify frontmatter, count lines, list reference files and sizes, identify the design pattern, check that loading triggers are embedded in workflow steps (not dumped at the end).
3. **Score the 8 dimensions** — **MANDATORY: load `references/scoring-rubrics.md`** for the anchor points on each dimension. Cite specific evidence (file path / quoted lines) for every score.
4. **Failure-pattern check** — for each dimension scoring below 70%, **load `references/failure-patterns.md`** and identify which named anti-pattern applies, then carry the prescribed fix into the improvements section.
5. **Calculate total + assign grade** — sum scores (max 120), apply the grading scale below.
6. **Generate report** — use the output format in this file.

For an annotated end-to-end run on a real skill, **load `references/example-evaluation.md`**.

**Do NOT load** `failure-patterns.md` or `example-evaluation.md` unless step 4 or step 6 of the protocol calls for it.

## 8 Dimensions (120 points total)

| #  | Dimension                | Max | Measures                                                                 |
| -- | ------------------------ | --- | ------------------------------------------------------------------------ |
| D1 | Knowledge Delta          | 20  | Genuine expert knowledge vs token-wasting redundancy (THE core)          |
| D2 | Mindset + Procedures     | 15  | Thinking patterns + domain-specific procedures Claude wouldn't infer     |
| D3 | Anti-Pattern Quality     | 15  | Specific NEVER lists with non-obvious reasons                            |
| D4 | Specification Compliance | 15  | Frontmatter validity + description that answers WHAT/WHEN/KEYWORDS       |
| D5 | Progressive Disclosure   | 15  | Three-layer loading respected; reference files used with explicit triggers|
| D6 | Freedom Calibration      | 15  | Specificity matches task fragility (creative=high, fragile=low)          |
| D7 | Pattern Recognition      | 10  | Follows an established design pattern; pattern fits the task             |
| D8 | Practical Usability      | 15  | Decision trees, working examples, error handling, edge cases             |

→ Score boundaries (what counts as 18/20 vs 12/20 vs 5/20) are in `references/scoring-rubrics.md`.

## Five design patterns

| Pattern    | Lines | Best for                              | Canonical example | Freedom |
| ---------- | ----- | ------------------------------------- | ----------------- | ------- |
| Mindset    | ~50   | Creative tasks requiring taste        | frontend-design   | High    |
| Navigation | ~30   | Multiple distinct scenarios → branch  | internal-comms    | Medium  |
| Philosophy | ~150  | Art/creation requiring originality    | canvas-design     | High    |
| Process    | ~200  | Complex multi-step procedures         | mcp-builder       | Medium  |
| Tool       | ~300  | Precise operations on specific format | docx, pdf, xlsx   | Low     |

**Selection rule**: pick the pattern matching the **task's nature**, not the author's preference. A creative task forced into Tool produces rigid, taste-less output. A fragile operation written in Mindset produces inconsistent results. The freedom column tells you the right calibration: ask "if the agent makes a mistake, what's the consequence?" — high consequence → low freedom.

## Grading scale

| Grade | Points    | Meaning                                 |
| ----- | --------- | --------------------------------------- |
| A     | ≥108 (90%+) | Excellent — production-ready expert skill |
| B     | 96–107    | Good — minor improvements needed        |
| C     | 84–95     | Adequate — clear improvement path       |
| D     | 72–83     | Below average — significant issues      |
| F     | <72       | Poor — needs fundamental redesign       |

## Output format

```markdown
# Skill Evaluation Report: <Skill Name>

## Summary
- **Total**: X/120 (X%)
- **Grade**: <A/B/C/D/F>
- **Pattern**: <name> (<right choice / mismatch — should be Y because Z>)
- **Knowledge ratio E:A:R**: X:Y:Z
- **Verdict**: <one sentence>

## Dimension scores
| # | Dimension | Score | Evidence |
|---|-----------|-------|----------|
| D1 | Knowledge Delta | X/20 | <specific cite or quote> |
| D2 | Mindset + Procedures | X/15 | <cite> |
| D3 | Anti-Pattern Quality | X/15 | <cite> |
| D4 | Specification Compliance | X/15 | <cite> |
| D5 | Progressive Disclosure | X/15 | <cite> |
| D6 | Freedom Calibration | X/15 | <cite> |
| D7 | Pattern Recognition | X/10 | <cite> |
| D8 | Practical Usability | X/15 | <cite> |

## Critical issues
- <must-fix #1, with file location>
- <must-fix #2>

## Top 3 improvements (prioritized by leverage)
1. <highest-leverage change + concrete how>
2. <next>
3. <next>

## Failure patterns matched
<For each dimension <70%, name the failure pattern from references/failure-patterns.md and quote the prescribed fix.>

## Detailed analysis
<For each dimension <80%, give: what's missing, specific quote from the skill, what would close the gap.>
```

## NEVER do when evaluating

- **NEVER** give high scores just because content looks polished. Polish ≠ knowledge delta.
- **NEVER** ignore token waste. Every redundant paragraph deducts.
- **NEVER** let length impress you. A 43-line skill can outperform a 500-line one.
- **NEVER** skip mentally walking the decision trees. Do they actually lead to correct choices?
- **NEVER** forgive explaining basics with "but it provides helpful context."
- **NEVER** undervalue the description field. Poor description = skill never gets used. D4 caps at 10/15 if description lacks any of WHAT/WHEN/KEYWORDS.
- **NEVER** put "when to use" info only in the body — agents only see the description before loading.
- **NEVER** assume all procedures are valuable. Distinguish domain-specific (high value) from generic (Claude already knows).

## The meta-question

Before finalizing a score, ask:

> "Would an expert in this domain say: 'Yes, this captures knowledge that took me years to learn'?"

If no, **D1 cannot exceed 12/20** regardless of how polished the prose is. The best skills are compressed expert brains — a designer's 10 years of taste compressed into 43 lines, a document expert's operational scars into a 200-line decision tree.

What gets compressed must be things Claude doesn't have. Otherwise it's garbage compression.

## Related concepts

- **Tool vs Skill**: tools define capability boundaries (what Claude *can* do); skills inject knowledge (what Claude *knows how* to do). Same model + different skills = different domain experts.
- **Knowledge externalization**: editing a markdown file changes model behavior on the next call — like a hot-swappable LoRA adapter, $0 cost, instant. The cost is paid in tokens, so every byte must earn its place.
- **Freedom calibration**: match constraint level to task fragility. Creative tasks need principles; fragile operations need exact scripts.
