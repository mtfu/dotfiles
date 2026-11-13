---
name: mtfu-debugging
description: >
  Diagnose a bug, failing or flaky test, build or pipeline failure, crash or performance regression
  before fixing it: a failing repro first, root cause before any fix, one change at a time, and a
  Rider breakpoint hand-off when a debugger beats logging. USE FOR: "why does X fail", "fix this
  bug", red tests or builds. DO NOT USE FOR: reviewing a diff (ask for a review) or
  writing new features.
---

<!-- Inspired by systematic-debugging from obra/superpowers (MIT, (c) 2025 Jesse Vincent). -->

# Debugging

Root cause first. A fix you can't explain is a guess, and guesses stack.

## Rules

- No fix before you can say where the bad value is first produced, and why.
- One change per attempt. A disproved probe is reverted before the next one.
- Fix at the source, not where the symptom shows up.
- Never make it pass by weakening the check: no skipping or loosening tests, longer timeouts,
  retries or swallowed exceptions, unless the evidence shows that is the actual cause. Say so.
- "Why does this fail" ends with the root cause and a proposed fix. Apply it only when I ask.
- Three failed fixes: stop, show me the evidence. A symptom that moves with each fix is a design
  problem, not a patch problem.
- Say "I don't know why yet" rather than present a guess as the cause.

## 1. Get a red loop

Read the whole error first: inner exceptions, full stack trace, the warnings before it.

Then find one command that goes red on this bug, in roughly this order: a failing test at the seam
that reaches the bug (`dotnet test --filter`); an `.http`/curl request against a local instance; a
CLI run with a fixture input; a replay of a captured payload; a throwaway harness; old vs new
version; `git bisect run` in a separate worktree, never my checkout.

Tighten it: fast, asserts my exact symptom (not "didn't crash"), deterministic. Flaky: loop it until
the failure rate is high. Performance: measure against the known-good baseline before guessing.

No loop, no hypotheses. Say what you tried and ask me for an environment, an artifact or a Rider
session.

## 2. Narrow

- Confirm the loop shows my bug, not a different one nearby.
- Check what changed since it last worked: diff, packages, config, environment.
- Cut inputs and steps until removing anything turns the loop green.
- Multi-component flow (Angular, BFF, API, database, pipeline): check what enters and leaves each
  boundary, then dig only where good input turns bad. Log shape or presence, never secrets or PII.
- Compare with similar code that works and list every difference: registration order, lifetimes,
  async context, culture, time zone, versions.

## 3. Hypotheses

Write 3-5 ranked hypotheses, each with a prediction: "if X, then changing Y makes it go away". Show
them to me; I often know what to rule out. Test the top one with the smallest probe that could
disprove it. Tag temporary logs with a unique prefix like `[DEBUG-a4f2]`.

### Rider hand-off

When a debugger is the faster probe (async ordering, DI/lifetime, a value wrong deep in a call
chain), don't add logs. Give me:

- breakpoints as `File.cs:line`, with a condition when useful;
- the watch expressions to read;
- what each hypothesis predicts I'll see.

I run it in Rider and report back. Continue from my values.

## 4. Fix

1. Turn the minimized repro into a regression test at the seam where the bug lives, and watch it
   fail.
2. One fix at the source. No "while I'm here" changes.
3. Verify: the test passes, the original loop is green, the surrounding suite passes. Say what the
   checks didn't cover.
4. Clean up: remove every tagged probe (search for the prefix) and throwaway harness. Name the
   confirmed cause in the close.

## Signs you're off track

If I say "stop guessing", "is that actually happening?", "will it show us…?" or "we're stuck?", you
are guessing without evidence. Go back to the loop.

"It's environmental" is usually an investigation that stopped early. If the evidence really rules
the code out, record what you checked, handle it deliberately (bounded retry, timeout, clear error)
and add the telemetry that would confirm it next time.
