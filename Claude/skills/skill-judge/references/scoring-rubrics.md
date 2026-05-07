# Scoring Rubrics — Anchor Points for D1–D8

Use this file when scoring. Each dimension has explicit score boundaries plus red/green flags so two evaluators converge on similar scores.

---

## D1: Knowledge Delta (20 points) — THE core dimension

> Does the skill add genuine expert knowledge?

| Score  | Criteria                                                                         |
| ------ | -------------------------------------------------------------------------------- |
| 0–5    | Mostly basics Claude knows — "what is X", how to write a for-loop, library tutorials |
| 6–10   | Mixed — some expert content diluted by obvious explanations                      |
| 11–15  | Mostly expert with minimal redundancy                                            |
| 16–20  | Pure delta — every paragraph earns its tokens                                    |

**Red flags (instant ≤5):**
- "What is [basic concept]" sections
- Step-by-step tutorials for standard operations (open file → read → save)
- Generic best-practice platitudes ("write clean code", "handle errors")
- Definitions of industry-standard terms (REST, OAuth, async)
- Explaining how to use well-documented common libraries

**Green flags (indicators of high delta):**
- Decision trees for non-obvious choices ("when X fails, try Y because Z")
- Trade-offs only an expert would know ("A is faster but B handles edge case C")
- Edge cases from real-world experience ("Excel breaks if cell value starts with `=`")
- "NEVER do X because [non-obvious reason]"
- Domain-specific thinking frameworks
- Workflows Claude wouldn't know (proprietary pipelines, niche tool combinations)

**Scoring questions:**
1. For each section, ask: "Does Claude already know this?"
2. If explaining something, ask: "Is this explaining TO Claude, or FOR Claude?"
3. Count paragraphs as `[E]`/`[A]`/`[R]`. If `[R] > 30%`, score cannot exceed 10.

---

## D2: Mindset + Procedures (15 points)

> Does it transfer expert thinking patterns AND domain-specific procedures Claude wouldn't infer?

| Score  | Criteria                                                                       |
| ------ | ------------------------------------------------------------------------------ |
| 0–3    | Only generic procedures Claude already knows                                   |
| 4–7    | Has domain procedures but lacks thinking frameworks                            |
| 8–11   | Good balance: thinking patterns + domain-specific workflows                    |
| 12–15  | Expert-level: shapes thinking AND provides procedures Claude wouldn't know     |

**Three procedure types to distinguish:**

| Type                       | Example                                                              | Value |
| -------------------------- | -------------------------------------------------------------------- | ----- |
| Thinking pattern           | "Before designing, ask: what makes this memorable?"                  | High  |
| Domain-specific procedure  | "OOXML workflow: unpack → edit XML → validate → repack"              | High  |
| Generic procedure          | "Step 1: open file. Step 2: edit. Step 3: save."                     | Low   |

**Valuable procedures look like:**
- Non-obvious correct ordering ("validate BEFORE packing, not after")
- Critical steps that are easy to miss ("MUST recalculate formulas after editing")
- Domain-specific sequences (MCP server's 4-phase development flow)
- Workflows Claude hasn't seen (proprietary tools, internal systems)

**Redundant procedures look like:**
- Generic file operations
- Standard programming patterns (loops, conditionals, error handling)
- Common library usage already in well-known docs

**The test:** Does it tell Claude (1) WHAT to think about, AND (2) HOW to do things it wouldn't otherwise know?

---

## D3: Anti-Pattern Quality (15 points)

> Does the skill have effective NEVER lists with non-obvious reasons?

| Score  | Criteria                                                                       |
| ------ | ------------------------------------------------------------------------------ |
| 0–3    | No anti-patterns mentioned                                                     |
| 4–7    | Generic warnings ("be careful", "avoid errors", "consider edge cases")         |
| 8–11   | Specific NEVER list with some reasoning                                        |
| 12–15  | Expert-grade anti-patterns with WHY — things only experience teaches           |

**Why this matters:** Half of expert knowledge is knowing what NOT to do. A senior designer instinctively cringes at purple gradients on white — that intuition came from stepping on landmines. Claude hasn't stepped on those landmines.

**Expert anti-patterns (specific + reason):**
```markdown
NEVER use generic AI-generated aesthetics:
- Overused fonts (Inter, Roboto, Arial)
- Cliched colors (purple gradients on white — signature of AI-generated UI)
- Default border-radius on everything
```

**Weak anti-patterns (vague, no reasoning):**
```markdown
Avoid making mistakes.
Be careful with edge cases.
Don't write bad code.
```

**The test:** Would an expert read the NEVER list and say "yes, I learned this the hard way"? Or "this is obvious to everyone"?

---

## D4: Specification Compliance (15 points)

> Frontmatter validity AND description quality. **Description is THE most important field — it determines whether the skill ever gets activated.**

| Score  | Criteria                                                                       |
| ------ | ------------------------------------------------------------------------------ |
| 0–5    | Missing or invalid frontmatter                                                 |
| 6–10   | Valid frontmatter but description is vague or incomplete                       |
| 11–13  | Valid frontmatter, description has WHAT but weak on WHEN/KEYWORDS              |
| 14–15  | Comprehensive description with WHAT, WHEN, and trigger KEYWORDS                |

**Frontmatter requirements:**
- `name`: lowercase, alphanumeric + hyphens only, ≤64 chars
- `description`: must answer three questions

**The three description questions:**

1. **WHAT** — what does this skill do? (capabilities)
2. **WHEN** — in what situations should it be used? (trigger scenarios)
3. **KEYWORDS** — what terms should fire it? (file extensions, domain terms, action verbs)

**Excellent description (all three):**
```yaml
description: "Comprehensive .docx document creation, editing, and analysis with
support for tracked changes, comments, formatting preservation, and text extraction.
Use when Claude needs to work with professional Word documents for: (1) creating
new documents, (2) modifying or editing content, (3) working with tracked changes,
(4) adding comments."
```
- WHAT: creation, editing, analysis, tracked changes, comments
- WHEN: "Use when Claude needs to work with professional Word documents for: (1)... (2)..."
- KEYWORDS: .docx, tracked changes, professional Word documents

**Poor description:**
```yaml
description: "处理文档相关功能"
```
- WHAT: vague (which functions?)
- WHEN: missing
- KEYWORDS: missing

**Hard cap:** if the description is missing ANY of WHAT/WHEN/KEYWORDS, D4 cannot exceed 10/15 — the skill will fire unreliably or not at all.

---

## D5: Progressive Disclosure (15 points)

> Is content layered for on-demand loading? Are reference files actually used?

| Score  | Criteria                                                                       |
| ------ | ------------------------------------------------------------------------------ |
| 0–5    | Everything dumped in SKILL.md (>500 lines, no references)                      |
| 6–10   | Has references but unclear when to load them                                   |
| 11–13  | Good layering with mandatory triggers present                                  |
| 14–15  | Perfect: decision trees + explicit triggers + "Do NOT load" guidance           |

**Loading-trigger quality ladder:**

| Quality   | Characteristics                                                       |
| --------- | --------------------------------------------------------------------- |
| Poor      | References listed at the end, no loading guidance                     |
| Mediocre  | Some triggers but not embedded in workflow                            |
| Good      | MANDATORY triggers in workflow steps                                  |
| Excellent | Scenario detection + conditional triggers + "Do NOT load" guards      |

**Good trigger (embedded in workflow):**
```markdown
### Creating new document

**MANDATORY**: Before proceeding, read `references/docx-js.md` (~500 lines)
in full. Do NOT set range limits when reading.

**Do NOT load** `ooxml.md` or `redlining.md` for this task.
```

**Bad trigger (just listed):**
```markdown
## References
- docx-js.md
- ooxml.md
- redlining.md
```

**For simple skills (<100 lines, no references):** score on conciseness and self-containment instead. A 32-line Navigation skill that has no references but is perfectly self-contained scores 13–15.

---

## D6: Freedom Calibration (15 points)

> Specificity matches task fragility.

| Score  | Criteria                                                                       |
| ------ | ------------------------------------------------------------------------------ |
| 0–5    | Severely mismatched (rigid scripts for creative tasks, vague for fragile ops)  |
| 6–10   | Partially appropriate, some mismatches                                         |
| 11–13  | Good calibration for most scenarios                                            |
| 14–15  | Perfect freedom calibration throughout                                         |

**Freedom spectrum:**

| Task type             | Should have       | Why                                                       | Example         |
| --------------------- | ----------------- | --------------------------------------------------------- | --------------- |
| Creative / design     | High freedom      | Multiple valid approaches; differentiation is the value   | frontend-design |
| Code review           | Medium freedom    | Principles exist but judgment required                    | code-review     |
| File-format ops       | Low freedom       | One wrong byte corrupts file; consistency critical        | docx, xlsx, pdf |

**High freedom (text principles):**
```markdown
Commit to a BOLD aesthetic direction. Pick an extreme: brutally minimal,
maximalist chaos, retro-futuristic, organic-natural...
```

**Medium freedom (parameterized priorities):**
```markdown
Review priority:
1. Security vulnerabilities (must fix)
2. Logic errors (must fix)
3. Performance issues (should fix)
4. Maintainability (optional)
```

**Low freedom (exact script):**
```markdown
**MANDATORY**: use exact script in `scripts/create-doc.py`.
Parameters: --title "X" --author "Y". Do NOT modify the script.
```

**The test:** "If the agent makes a mistake here, what's the consequence?"
- High consequence (corrupts file, leaks secret) → Low freedom
- Low consequence (slightly less elegant design) → High freedom

---

## D7: Pattern Recognition (10 points)

> Does the skill follow an established pattern, and is the pattern right for the task?

| Score | Criteria                                                       |
| ----- | -------------------------------------------------------------- |
| 0–3   | No recognizable pattern, chaotic structure                     |
| 4–6   | Partially follows a pattern with significant deviations        |
| 7–8   | Clear pattern with minor deviations                            |
| 9–10  | Masterful application of the appropriate pattern               |

**Pattern selection guide:**

| Task characteristic              | Recommended pattern   |
| -------------------------------- | --------------------- |
| Needs taste and creativity       | Mindset (~50 lines)   |
| Needs originality and craft      | Philosophy (~150)     |
| Multiple distinct sub-scenarios  | Navigation (~30)      |
| Complex multi-step procedure     | Process (~200)        |
| Precise operations on a format   | Tool (~300)           |

**Mismatch penalty:** if the pattern is wrong for the task (e.g., Tool pattern used for a creative task), cap at 5/10 even if the pattern is internally well-executed.

---

## D8: Practical Usability (15 points)

> Can an agent actually use this skill effectively?

| Score  | Criteria                                                                       |
| ------ | ------------------------------------------------------------------------------ |
| 0–5    | Confusing, incomplete, contradictory, or untested guidance                     |
| 6–10   | Usable but with noticeable gaps                                                |
| 11–13  | Clear guidance for common cases                                                |
| 14–15  | Comprehensive coverage including edge cases and error handling                 |

**Check for:**
- **Decision trees** — for multi-path scenarios, is there clear branching?
- **Working code** — do the examples actually run, or are they pseudocode that breaks?
- **Error handling** — what if the main approach fails? Are fallbacks given?
- **Edge cases** — are unusual but realistic scenarios covered?
- **Actionability** — can the agent immediately act, or must it figure things out?

**Good usability (decision tree + fallback):**
```markdown
| Task           | Primary    | Fallback    | Use fallback when    |
| -------------- | ---------- | ----------- | -------------------- |
| Read text      | pdftotext  | PyMuPDF     | Need layout info     |
| Extract tables | camelot-py | tabula-py   | camelot fails        |

Common issues:
- Scanned PDF: pdftotext returns blank → use OCR first
- Encrypted PDF: permission error → use PyMuPDF with password
```

**Poor usability (vague):**
```markdown
Use appropriate tools for PDF processing.
Handle errors properly. Consider edge cases.
```
