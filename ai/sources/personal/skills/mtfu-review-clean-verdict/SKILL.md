---
name: mtfu-review-clean-verdict
description: >
  Personal review-output rule. USE ALWAYS when asked to review, assess, critique, or look over
  anything — a PR, diff, branch, file, design, plan, or "is there anything we should simplify /
  change / improve here?". "No changes needed" is an acceptable, complete, and often preferred
  answer, and cosmetic nits must not be promoted into findings to avoid an empty result. DO NOT
  USE to suppress or soften genuine defects — correctness bugs, security issues, data loss, and
  broken contracts are always reported, and this rule never lowers the bar of the code-review or
  code-review-precommit skills.
---

# It Is Fine To Say "This Is Fine"

**A review that finds nothing is a successful review. Reporting "nothing here is worth changing" is a complete deliverable — not a failure to do the job.**

I would rather get a two-line "looks fine, here's why I'm confident" than a ranked list of things that turn out not to matter. Padding costs me tokens, review attention, and trust in the next list you give me.

## The default

Start from "this is probably fine" and let evidence move you off it. The request to review is **not** evidence that something is wrong.

Never reason like:
- "I was asked to review, so I need findings."
- "I should return at least three items."
- "This is a big PR, there must be something."

Big, unfamiliar, or complex is not the same as wrong. Neither is "written differently than I would have written it."

## The bar for reporting something

Report it if acting on it would **make the code better in a way I'd care about**:

- Correctness bugs, race conditions, data loss, security issues — always report.
- Broken or missing contracts, misleading names, silent failure paths — report.
- Something that will actively cause a future mistake — report, with the mechanism.

Do **not** promote to a finding:
- Line-count reductions that don't make anything easier to reason about.
- Duplication that is textual rather than semantic (see below).
- Style, formatting, naming preferences, or "I'd have structured it differently".
- Anything you'd struggle to justify if I asked "so what breaks if we leave it?"

**If the only things you found are in the second list, the answer is "nothing worth changing."** You may add them afterwards as an explicitly optional footnote, unranked, clearly marked as take-it-or-leave-it. Never as "findings".

## Rank by consequence, not by size

Never rank or headline items by lines removed, files touched, or how big the refactor is. Rank by what goes wrong if it stays. "~200 lines" is not an argument. "This can silently drop a message" is.

## Before proposing any refactor, check semantics — not shape

Two pieces of code that *look* alike are not necessarily doing the same job. Before calling anything duplication, confirm they share semantics, not just structure:

- What does each one return, and to whom? (an HTTP caller? a worker loop? a retry mechanism?)
- What do their failure paths mean? Is `return false` a failure, or a yield?
- What are their timing/blocking constraints? Is a bounded wait there for a user, or for a queue?
- Do their signatures already tell you they differ?

If merging them would change any of those, it is not duplication — it is two things that should stay separate. Say so and move on. Deliberate near-duplication is a legitimate design choice.

**Never implement a proposed refactor to find out whether it was a good idea.** Establish that first, on the existing code. Discovering the answer via a failing test after the rewrite is the expensive path.

## How to deliver a clean verdict

Be specific about what you actually checked, so "fine" is credible rather than lazy:

> Read the OkUsers hash-import path — executor, both subscribers, the create/update/password-hash handlers. Nothing worth changing. The two near-duplicate flows (request path vs outbox path) differ deliberately: one throws for an HTTP caller, the other returns false to yield to the outbox retry. Structure is reasonable as-is.

That is a finished answer. Do not append a consolation list.

## After the verdict

- Do not implement anything from a review unless I explicitly ask. Review means inspect and report.
- If I push back on a finding, re-examine it honestly. Drop it if I'm right; hold it with reasons if I'm not. Don't defend it because you already said it, and don't cave because I sounded annoyed.
- If you already built something and it turns out to be wrong, say so plainly and revert it. Reverting your own work is not a loss.

## Relationship to the other review skills

This governs the *threshold and framing* of review output. It does not change what `code-review` or `code-review-precommit` are for, and it never suppresses a confidence-gated finding those skills would surface. A scorecard with no findings above the bar is a valid, good result.
