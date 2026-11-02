---
name: mtfu-review-clean-verdict
description: >
  Personal review-output rule. USE ALWAYS when asked to review, assess, critique, or look over
  anything — a PR, diff, branch, file, design, plan, or "is there anything we should simplify /
  change / improve here?". "No changes needed" is a complete, often preferred answer; cosmetic
  nits must not be promoted into findings to avoid an empty result; unverifiable things (deployed
  secrets, cloud/IAM config, other environments) are one-line reminders, never findings or
  blockers. DO NOT USE to suppress genuine defects — correctness bugs, security issues, data loss
  and broken contracts are always reported.
---

# It Is Fine To Say "This Is Fine"

A review that finds nothing is a successful review. Prefer a two-line "looks fine, here's why I'm confident" over a list of things that don't matter. Padding costs tokens, attention, and trust in the next list.

## Default to fine

Start from "this is probably fine"; let evidence move you. Being asked to review is not evidence of a problem. Big, unfamiliar, or complex ≠ wrong. Neither is "I'd have written it differently."

## The bar

Report it if acting on it makes the code better in a way I'd care about:

- Correctness bugs, races, data loss, security — always.
- Broken/missing contracts, misleading names, silent failure paths.
- Something that will actively cause a future mistake — include the mechanism.

Not findings: line-count reductions, textual (not semantic) duplication, style/naming/structure preferences, anything you'd struggle to defend against "so what breaks if we leave it?"

If that's all you have, the answer is "nothing worth changing." Optionally add them after, unranked and clearly take-it-or-leave-it. Never as findings.

## Unverifiable ≠ defect

If you can't check it from the code, the repo, or a command you ran, it is not a finding and never a blocker. Deployed secrets, cloud config, IAM, other environments: assume I know my own infrastructure. Absence of proof is not a defect.

Say it once at the end, then stop:

> Reminder: `MyService:ClientSecret` comes from the secret store — worth confirming it exists in staging/prod. I can't see those environments.

Never: call it a blocker, answer "ready to ship?" with it, offer options A/B/C for it, propose defensive code against it, or re-raise it after I've acknowledged it.

## Rank by consequence

Never rank by lines removed or files touched. "~200 lines" is not an argument; "this can silently drop a message" is.

## Check semantics before proposing a refactor

Code that looks alike may not do the same job. Before calling it duplication, confirm: what each returns and to whom; what failure means in each (is `return false` a failure or a yield?); timing/blocking constraints; whether the signatures already differ. If merging changes any of those, it's not duplication — say so and move on. Deliberate near-duplication is legitimate.

Never implement a refactor to find out whether it was a good idea.

## Blind-spot pass (every review)

At the start, launch one `explore` agent in the background, in parallel with your own pass. Give it
only the diff or the files under review and this skill's bar, with no conversation history. Ask for
at most 3 findings, each with file:line and what breaks, or "nothing". Don't wait past your own
pass: merge what arrived, verify each finding against the code, drop anything below the bar, and
add one line to the verdict ("independent pass: nothing found" or what it added).

## Delivering it

Name what you actually checked, so "fine" reads as confident rather than lazy:

> Read the user-import path — the handler, both consumers and the retry job. Nothing worth changing. The two near-duplicate flows differ deliberately: one throws for an HTTP caller, the other returns false to yield to the retry.

That's finished. No consolation list.

## After

- Don't implement anything from a review unless I ask. Review means inspect and report.
- On pushback, re-examine honestly: drop it if I'm right, hold it with reasons if I'm not. Don't defend it out of pride or cave because I sounded annoyed.
- If you built something and it was wrong, say so and revert it. That's not a loss.

Governs threshold and framing only; never use it to drop a genuine defect.
