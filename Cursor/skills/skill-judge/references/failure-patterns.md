# Failure Patterns

Nine recurring failure modes. When a dimension scores below 70%, match it to one of these patterns and carry the prescribed fix into the report's "Top improvements" section.

Each pattern follows the same structure: **Symptom** (what you observe) → **How to detect** (concrete signal) → **Why it's bad** (consequence) → **Fix** (prescription) → **Example**.

---

## P1: The Tutorial

- **Symptom**: Explains what PDF is, how Python works, basic library usage
- **How to detect**: Look for "What is X" headings, paragraphs that read like a textbook intro, step-by-step instructions for standard library calls
- **Why it's bad**: Claude already learned this during pretraining. Every redundant token displaces something useful from the context window. The skill becomes a slow tax on every invocation.
- **Fix**: Delete all basic explanations. Skills are not classrooms. Focus on expert decisions, trade-offs, and anti-patterns Claude wouldn't generate on its own.
- **Affects**: D1 primarily, D2 secondarily.

```markdown
BAD:
## What is PDF?
PDF (Portable Document Format) is a file format developed by Adobe...

GOOD:
## When pdftotext fails
Scanned PDFs return empty strings — falling back to OCR adds 5–10s per page,
so detect scanned-vs-text first via `pdfinfo | grep "Tagged"`.
```

---

## P2: The Dump

- **Symptom**: SKILL.md is 800+ lines with everything stuffed in one file
- **How to detect**: `wc -l SKILL.md` returns >500; no `references/` directory; the file scrolls forever
- **Why it's bad**: Layer 2 is loaded into context every time the skill triggers. A 1000-line skill costs the same tokens whether the user needs section 1 or section 7. Progressive disclosure is the whole point.
- **Fix**: Move heavy content into `references/`. SKILL.md keeps the routing logic, decision trees, and load triggers (`MANDATORY`, `Do NOT load`). Aim for SKILL.md <300 lines.
- **Affects**: D5 primarily, D8 secondarily (long files become hard to navigate).

```
SKILL.md (180 lines)         <- routing + protocol
└── references/
    ├── scoring-rubrics.md    <- detail loaded only when scoring
    ├── failure-patterns.md   <- detail loaded only when matching anti-patterns
    └── example-evaluation.md <- detail loaded only on demand
```

---

## P3: The Orphan References

- **Symptom**: `references/` directory exists but the files are never loaded
- **How to detect**: SKILL.md mentions reference files only at the end as a list, with no `MANDATORY`/`Read this when...` triggers in the workflow
- **Why it's bad**: The agent doesn't know when to read them. The knowledge is technically present but functionally dead — same as deleting it.
- **Fix**: Embed loading triggers inside workflow steps:
  - `**MANDATORY** — Before scoring, load references/scoring-rubrics.md`
  - `Do NOT load X for this task`
  - Conditional triggers: `If the user asks about Y, load Z`
- **Affects**: D5.

---

## P4: The Checkbox Procedure

- **Symptom**: Step 1, Step 2, Step 3... mechanical procedures with no reasoning
- **How to detect**: Numbered lists where every step is an imperative ("Open the file", "Edit the cell", "Save"); no "Before doing X, ask Y" framings
- **Why it's bad**: Procedures without thinking patterns produce brittle agents. They follow steps blindly when reality requires judgment. The skill teaches obedience, not expertise.
- **Fix**: Wrap procedures with thinking frameworks:
  - "Before [action], ask yourself: what's the failure mode?"
  - "If [condition X], take path A; if [condition Y], take path B because [reason]"
  - Decision principles, not operation sequences.
- **Affects**: D2, D8.

```markdown
BAD:
1. Open the file
2. Find the function
3. Add the parameter
4. Save and test

GOOD:
Before editing, ask:
- Is this function called from outside the module? If yes, the parameter
  must be optional (breaks all callers otherwise).
- Does adding state here violate the layer rules in architecture.mdc?

Then: edit minimally, run typecheck, verify the public API surface
hasn't grown unintentionally.
```

---

## P5: The Vague Warning

- **Symptom**: "Be careful", "avoid errors", "consider edge cases", "handle this properly"
- **How to detect**: Warnings without specific examples or stated reasons; words like "appropriate", "properly", "carefully" without parameters
- **Why it's bad**: A vague warning is worse than no warning — it implies the author knew something but couldn't articulate it. Claude has no way to act on "be careful."
- **Fix**: Replace each vague warning with a specific NEVER + WHY:
  - `NEVER use Inter font — overused, signature of AI-generated UI`
  - `NEVER edit Excel cells starting with '=' as a string — Excel will execute the formula`
- **Affects**: D3 primarily.

---

## P6: The Invisible Skill

- **Symptom**: Great content but skill rarely triggers
- **How to detect**: Description is vague ("helpful skill for various tasks"), missing keywords, or contains only a name not a trigger condition
- **Why it's bad**: Layer 1 (description) is the only thing the agent sees before deciding to load the skill. If the description doesn't match the user's wording, the body is never read — no matter how brilliant.
- **Fix**: Description must answer WHAT, WHEN, KEYWORDS. Use trigger phrasing the user is likely to say verbatim.
- **Affects**: D4. Hard cap on D4 at 10/15 if any of WHAT/WHEN/KEYWORDS is missing.

```yaml
BAD:
description: "Helps with document tasks"

GOOD:
description: "Create, edit, and analyze .docx Word documents — tracked changes,
comments, formatting preservation, text extraction. Use when the user asks to
create, modify, redline, or extract from a Word document, mentions .docx, or
references 'tracked changes'."
```

---

## P7: The Wrong Location

- **Symptom**: "When to use this skill" / "Trigger phrases" section in the body, NOT in the description
- **How to detect**: A "## When to use" heading inside SKILL.md body, while the frontmatter description is short and generic
- **Why it's bad**: Misunderstands three-layer loading. The body is loaded *after* the triggering decision is already made. Triggering info in the body literally cannot affect triggering.
- **Fix**: Move all triggering language (use cases, trigger phrases, keywords) into the description field. Body keeps only "how to do the work" content.
- **Affects**: D4.

---

## P8: The Over-Engineered

- **Symptom**: README.md, CHANGELOG.md, INSTALLATION_GUIDE.md, CONTRIBUTING.md sit alongside SKILL.md
- **How to detect**: Skill folder treated like a software project; auxiliary docs that explain the skill *to humans* rather than help agents *do tasks*
- **Why it's bad**: A skill is consumed by an agent, not browsed by a human reader. Auxiliary docs aren't loaded by the agent and only inflate the package.
- **Fix**: Delete README/CHANGELOG/etc. The skill's own description IS its readme. References belong in `references/` only if an agent needs to load them.
- **Affects**: D5 (clutters reference loading); minor on D8.

---

## P9: The Freedom Mismatch

- **Symptom**: Rigid scripts forced on creative tasks, OR vague principles offered for fragile operations
- **How to detect**:
  - Creative skill (e.g. design, copywriting) with `MANDATORY: use exact template` everywhere → mismatch
  - Fragile skill (e.g. file-format manipulation) with "use your judgment to handle edge cases" → mismatch
- **Why it's bad**: Creative tasks need taste — rigid scripts produce derivative output. Fragile operations need precision — vague principles produce corrupted files.
- **Fix**: Calibrate to consequence-of-mistake.
  - High consequence (corrupts file, leaks secret, irreversible) → Low freedom (exact scripts, parameters, MANDATORY)
  - Low consequence (slightly less elegant design) → High freedom (principles, examples, taste cues)
- **Affects**: D6.

```markdown
WRONG (rigid for creative):
**MANDATORY**: every landing page must use 16px Inter, gradient #6E11A8 → #2575FC,
hero centered with 80px padding.

RIGHT (high freedom for creative):
Pick an extreme: brutally minimal, maximalist chaos, retro-futuristic, organic.
NEVER use generic AI aesthetics (Inter, purple gradients, default border-radius).

WRONG (vague for fragile):
Edit the OOXML carefully and handle edge cases.

RIGHT (low freedom for fragile):
1. Unzip with `unzip docx -d /tmp/x`
2. Edit ONLY `word/document.xml` — never `[Content_Types].xml`
3. Validate with `xmllint --noout` BEFORE re-zipping
4. Re-zip with `cd /tmp/x && zip -r ../out.docx .` (NOT `zip out.docx /tmp/x/*`,
   which produces an unreadable file)
```

---

## Quick lookup: dimension → likely failure pattern

| If this dimension scores low | Check these patterns first |
| ---------------------------- | -------------------------- |
| D1 Knowledge Delta           | P1 Tutorial                |
| D2 Mindset + Procedures      | P4 Checkbox Procedure      |
| D3 Anti-Pattern Quality      | P5 Vague Warning           |
| D4 Specification Compliance  | P6 Invisible Skill, P7 Wrong Location |
| D5 Progressive Disclosure    | P2 Dump, P3 Orphan References, P8 Over-Engineered |
| D6 Freedom Calibration       | P9 Freedom Mismatch        |
| D7 Pattern Recognition       | P9 Freedom Mismatch (often correlated) |
| D8 Practical Usability       | P4 Checkbox Procedure, P5 Vague Warning |
