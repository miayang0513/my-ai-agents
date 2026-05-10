# Worked Example: Evaluating `internal-comms`

A full annotated run of the protocol on a real, official skill — `internal-comms` from `anthropics/skills` (32 lines, Navigation pattern). This shows how to apply the rubrics on a high-quality skill so you have an A-grade calibration anchor.

---

## Subject under evaluation

```yaml
---
name: internal-comms
description: A set of resources to help me write all kinds of internal communications,
  using the formats that my company likes to use. Claude should use this skill whenever
  asked to write some sort of internal communications (status reports, leadership
  updates, 3P updates, company newsletters, FAQs, incident reports, project updates, etc.).
license: Complete terms in LICENSE.txt
---

## When to use this skill
To write internal communications, use this skill for:
- 3P updates (Progress, Plans, Problems)
- Company newsletters
- FAQ responses
- Status reports
- Leadership updates
- Project updates
- Incident reports

## How to use this skill

To write any internal communication:

1. **Identify the communication type** from the request
2. **Load the appropriate guideline file** from the `examples/` directory:
    - `examples/3p-updates.md` - For Progress/Plans/Problems team updates
    - `examples/company-newsletter.md` - For company-wide newsletters
    - `examples/faq-answers.md` - For answering frequently asked questions
    - `examples/general-comms.md` - For anything else that doesn't explicitly match one of the above
3. **Follow the specific instructions** in that file for formatting, tone, and content gathering

If the communication type doesn't match any existing guideline, ask for clarification or more context about the desired format.

## Keywords
3P updates, company newsletter, company comms, weekly update, faqs, common questions, updates, internal comms
```

32 lines. Let's run the full protocol.

---

## Step 1 — Knowledge delta scan

| Section                                 | Tag   | Reasoning                                                                 |
| --------------------------------------- | ----- | ------------------------------------------------------------------------- |
| `## When to use` — list of comm types   | `[A]` | Claude knows what 3P/newsletter/FAQ are; the list is a quick activation reminder |
| `## How to use` — 3-step routing        | `[E]` | The specific routing (this request → that file) is project-specific knowledge Claude wouldn't infer |
| The 4 sub-bullets mapping types → files | `[E]` | Routing table — pure expert knowledge (this is the skill's actual value)  |
| Fallback: "ask for clarification"       | `[E]` | Non-obvious — many skills silently force a category. Telling Claude to ask is a good policy. |
| `## Keywords`                           | `[E]` | Improves trigger reliability (description supplement); not something Claude would generate |

**Ratio E:A:R ≈ 4:1:0 → ~80% Expert, ~20% Activation, 0% Redundant**

Healthy. The skill's body content earns its tokens — the per-file routing is exactly the kind of knowledge that has to live in the skill (Claude has no other way to discover the `examples/` filenames).

---

## Step 2 — Structure analysis

| Check                                          | Result                                                  |
| ---------------------------------------------- | ------------------------------------------------------- |
| Frontmatter present and valid                  | ✓ name + description + license                          |
| Line count                                     | 32 lines — fits Navigation target (~30)                 |
| Reference files                                | 4 files in `examples/` (3p-updates, company-newsletter, faq-answers, general-comms) |
| Pattern identified                             | Navigation (correct — multiple sub-scenarios that branch) |
| Loading triggers in workflow                   | Yes — step 2 says "Load the appropriate guideline file" with explicit per-type mapping |
| `Do NOT load` guards                           | ✗ Absent. No explicit instruction to load only one file at a time. |

---

## Step 3 — Score the 8 dimensions

### D1: Knowledge Delta — **13/20**

The body's expert content is concentrated in the routing table and fallback rule. The "When to use" list is `[A]` (acceptable activation). No tutorial, no basics. But for a 32-line file, the absolute volume of expert knowledge is small — the real expertise lives in the `examples/` files (which we're not evaluating here).

**Evidence**: routing bullets in step 2; the "ask for clarification" fallback. No `[R]` content.

**Why not 17–20**: SKILL.md body alone provides limited absolute expert knowledge. Most of the value is deferred to `examples/`. That's an architectural choice (Navigation pattern), not a flaw — but the body alone earns ~13.

### D2: Mindset + Procedures — **10/15**

Has a clear domain-specific procedure (identify type → load file → follow file). Lacks thinking framework ("Before writing, ask: who's the audience?"). For a Navigation skill that defers detail to sub-files, the absence of in-body thinking patterns is acceptable but leaves points on the table.

**Evidence**: 3-step "How to use this skill" procedure.

### D3: Anti-Pattern Quality — **4/15**

**No NEVER list.** No anti-patterns mentioned at all. This is the skill's biggest weakness. Internal communications has a well-known set of failure modes (don't name individuals in incident retros, don't use exclamation marks in leadership updates, don't bury the action in paragraph 4, etc.) — none captured.

**Evidence**: search for "never", "don't", "avoid" → zero hits in body.

### D4: Specification Compliance — **14/15**

Description is exemplary: WHAT (write internal communications), WHEN ("whenever asked to write some sort of internal communications"), KEYWORDS (specific comm types listed inline + dedicated keywords section in body). Frontmatter is valid. The only nit: "company likes to use" is slightly informal/personal — fine for an internal skill but reads like a template.

**Evidence**: frontmatter description; `## Keywords` section adds searchable terms.

### D5: Progressive Disclosure — **12/15**

Three-layer model is respected — heavy content lives in `examples/`. Loading trigger is in step 2 ("Load the appropriate guideline file"). What's missing: explicit `Do NOT load other files` guards. Without them, an agent seeing all four bullets might load multiple files "for context" and waste tokens.

**Evidence**: routing in step 2; absence of "Do NOT load" guidance.

### D6: Freedom Calibration — **11/15**

Internal comms is a creative-with-conventions task — medium fragility. The body itself prescribes nothing about tone or format (correctly delegates to per-format files), and the fallback "ask for clarification" is the right freedom level. The freedom decisions for the actual writing live in the `examples/` (not in scope here).

**Evidence**: deferral pattern; clarification fallback.

### D7: Pattern Recognition — **10/10**

Textbook Navigation pattern. ~30 lines, minimal SKILL.md, routes to sub-files. The pattern matches the task (multiple distinct comm types → branch to per-type guidance). No deviations.

**Evidence**: 32-line SKILL.md, 4-file `examples/` directory, branching workflow.

### D8: Practical Usability — **12/15**

Decision tree is implicit but workable (request → match type → load file). Fallback is explicit (ask for clarification on unmatched types). What's missing: no worked example in body of "user said X → I picked file Y because Z." The agent has to do that pattern-matching alone.

**Evidence**: step 2 routing; fallback rule. No worked routing example.

---

## Step 4 — Total + grade

```
D1 13  + D2 10 + D3  4 + D4 14
D5 12  + D6 11 + D7 10 + D8 12
─────────────────────────────────
Total: 86 / 120 = 71.7%  →  C grade
```

(C grade despite the elegant Navigation execution — D3 is the dragging dimension. Adding a NEVER list alone would push this to ~B+.)

---

## Step 5 — Failure-pattern matches

D3 scored 4/15 (<70%) → matches **P5 Vague Warning** (technically the absence of any warnings, but P5's fix applies: replace generic-or-missing warnings with specific NEVER + WHY).

No other dimension scored below 70%.

---

## Step 6 — Final report (the deliverable)

```markdown
# Skill Evaluation Report: internal-comms

## Summary
- **Total**: 86/120 (71.7%)
- **Grade**: C (top of band)
- **Pattern**: Navigation (correct choice — branches to 4 per-format files)
- **Knowledge ratio E:A:R**: 4:1:0 (~80% expert, healthy)
- **Verdict**: Textbook Navigation execution undermined by a complete absence of anti-patterns; one fix moves it to B+.

## Dimension scores
| #  | Dimension                | Score | Evidence                                                                       |
| -- | ------------------------ | ----- | ------------------------------------------------------------------------------ |
| D1 | Knowledge Delta          | 13/20 | Routing bullets + clarification fallback are [E]; body volume is limited (Navigation defers value to examples/) |
| D2 | Mindset + Procedures     | 10/15 | Solid 3-step procedure; no thinking framework ("Before writing, ask...")       |
| D3 | Anti-Pattern Quality     | 4/15  | **No NEVER list**; "avoid", "don't", "never" all absent in body                |
| D4 | Specification Compliance | 14/15 | Description has WHAT + WHEN + KEYWORDS; dedicated Keywords section reinforces  |
| D5 | Progressive Disclosure   | 12/15 | Loading trigger in step 2; missing "Do NOT load" guards                        |
| D6 | Freedom Calibration      | 11/15 | Defers freedom decisions to per-format files (correct for Navigation)          |
| D7 | Pattern Recognition      | 10/10 | Textbook Navigation; 32 lines + 4 sub-files                                    |
| D8 | Practical Usability      | 12/15 | Implicit decision tree + clarification fallback; no worked routing example     |

## Critical issues
- **No anti-patterns** (D3): the skill is silent on the well-known failure modes of internal comms (naming individuals in retros, exclamation marks in leadership updates, burying the action). This is the single biggest gap.

## Top 3 improvements (prioritized by leverage)

1. **Add a NEVER list** — comm-type-specific anti-patterns with WHY. Highest leverage (lifts D3 from 4 → 11+, total +7 points). Example:
   ```markdown
   ## NEVER
   - In incident retros, NEVER name individuals — focus on systems and processes.
     Naming people creates blame culture and discourages candid postmortems.
   - In leadership updates, NEVER use exclamation marks — they read as
     unsophisticated. Use precise verbs instead.
   - NEVER bury the action item — surface it in the first paragraph or use a
     dedicated "Action Required" callout. Executives skim.
   ```

2. **Add "Do NOT load" guards in step 2** — prevents the agent from loading multiple `examples/*.md` files "for context." Lifts D5 from 12 → 14 (+2). Example:
   ```markdown
   2. Load the **single** appropriate guideline file from `examples/`:
      - 3P/Plans/Problems → load `3p-updates.md` only
      - Company-wide → load `company-newsletter.md` only
      - FAQ → load `faq-answers.md` only
      - Other → load `general-comms.md` only
      **Do NOT load other guideline files** — they apply to different formats
      and dilute focus.
   ```

3. **Add a tone-calibration thinking framework above step 1** — short "before you start" prompt. Lifts D2 from 10 → 13 (+3). Example:
   ```markdown
   ## Before writing, ask:
   - **Audience**: who reads this? Executives skim; ICs read in detail.
     Calibrate density accordingly.
   - **Action**: what do you want them to do? Surface it explicitly.
   - **Bandwidth**: how much of their attention can you assume? An incident
     update gets read; a weekly newsletter gets glanced at.
   ```

Combined effect: 86 → 102 (B+, top of band).

## Failure patterns matched
- **P5 (Vague Warning)** on D3 — applied as: missing rather than vague. Fix prescribed in improvement #1.

## Detailed analysis

### D3 — the gap

The skill assumes `examples/*.md` carry all anti-pattern guidance. That's a defensible architectural choice but creates risk: an agent that loads `general-comms.md` for an off-the-list comm type misses the universal NEVERs (naming individuals, exclamation marks, buried actions) that apply across all formats. Top-level NEVERs in SKILL.md are loaded every time the skill activates — they're cheap insurance.

### D5 — the loading-guard nit

Without explicit "Do NOT load" guards, a careful agent reading the four-bullet menu may load 2–3 files "to compare formats." For 32-line SKILL.md this isn't a disaster but it's avoidable.

### D8 — the worked-example gap

The routing logic in step 2 maps cleanly when the request is unambiguous ("write a 3P update"). For ambiguous cases ("draft something for Friday's all-hands"), the agent has to make a judgment with no in-body example of how. One worked routing example would close this.
```

---

## Calibration takeaways

Use this as your A-/B-grade anchor:

- **86/120 (C, top) is the floor for an officially-shipped, well-executed skill** that's missing anti-patterns. If a skill scores below this and isn't missing more than D3, you've likely under-scored something else.
- **D7 = 10/10** is achievable when pattern + execution + appropriate-line-count all line up. Don't be stingy on D7 if all three are present.
- **D3 = 4/15 from "no NEVER list"** is a heavy but fair penalty. Anti-patterns are half of expert knowledge; their complete absence cannot score above 5.
- **Description quality (D4) is the easiest dimension to score 14–15** when the author bothers — and the easiest to score 6–8 when they don't. The asymmetry reflects how much triggering depends on this single field.
