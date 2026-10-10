# AI instructions & skills

Personal Copilot/Claude configuration that follows me across every machine — **without depending
on the work-only `ok-ai` tool**.

For how these rules are actually used day to day — the agent/Neovim layout and the review loop —
see [`.config/nvim/NVIM_SETUP.md`](../.config/nvim/NVIM_SETUP.md).

## Instructions vs skills

Two different mechanisms, and picking the wrong one is the common mistake:

| | Instructions | Skills |
|---|---|---|
| Loading | **Always**, every session | On demand, when the AI judges the `description` relevant |
| Context cost | Paid on every turn | Only the description, until triggered |
| Contents | Plain markdown | A folder — `SKILL.md` plus any scripts/assets |
| Use for | Short, universal, non-negotiable rules | Long, situational procedures |

A rule that must hold **100% of the time** belongs in instructions. As a skill it would only apply
when retrieval happens to fire — writing "USE ALWAYS" in a skill description is a sign it is in
the wrong place. Keep instructions short: every line is paid for in every session.

## How it works

- Instructions → `~/.copilot/copilot-instructions.md` (Copilot only; `~/.claude/CLAUDE.md` is
  managed by hand and not linked)
- Skills → `~/.copilot/skills/<skill>` and `~/.claude/skills/<skill>`

Both live in this repo and are **symlinked** into those locations on every machine — no external
tooling needed. One source of truth, works everywhere (home and work), fully offline.

```
ai/
├── instructions/
│   └── copilot-instructions.md   ← always loaded: change size, commit rules, never push
└── sources/
    └── personal/
        └── skills/
            └── mtfu-<skill>/
                └── SKILL.md      ← loaded on demand
```

> All personal skills are prefixed `mtfu-` so their global names never clash with `ok-ai` or other
> sources that install into the same `~/.copilot/skills/` directory.

> The `sources/personal/skills/` nesting keeps things tidy and stays compatible with `ok-ai` (OK's
> work-only installer) if I ever want to add a `packages.json` and distribute it. Not required for
> the symlink workflow.

## Setup on a machine (super easy)

1. Clone/sync this dotfiles repo (syncthing already does this).
2. Enable **Developer Mode** (Settings → System → For developers) so symlinks work without admin.
3. Run:
   ```powershell
   .\updateSymbolicLinks.ps1
   ```

`updateSymbolicLinks.ps1` calls [`ai/setup.ps1`](setup.ps1), which links the instructions file
into Copilot, then loops over every
`ai/sources/*/skills/*` folder and creates a per-skill symlink into `~/.copilot/skills` and
`~/.claude/skills`. It links **per skill**, so `ok-ai`-synced skills already in `~/.copilot/skills`
are left untouched.

> Instructions and skills load at startup — start a new CLI/Claude session after linking.

## Adding a new personal skill

First check it actually belongs in a skill and not in `ai/instructions/copilot-instructions.md`
(see the table above).

1. Create the folder + file (prefix the name with `mtfu-`):
   ```
   ai/sources/personal/skills/mtfu-<my-skill>/SKILL.md
   ```
   `SKILL.md` frontmatter (`name` must match the folder):
   ```markdown
   ---
   name: mtfu-my-skill
   description: >
     One paragraph. Say WHEN to use it and when NOT to. This text is how the AI decides
     to load the skill, so be specific about triggers.
   ---

   # Title

   ...content...
   ```
2. Re-run `.\updateSymbolicLinks.ps1`.
3. Commit + push (I push manually — see the instructions file 🙂).

## Using it at work with ok-ai (optional)

The symlink workflow works at work too — just clone this repo and run
`.\updateSymbolicLinks.ps1`. If you'd rather have `ok-ai` manage it (team sharing, presets), add a
`packages.json` under `ai/sources/personal/` listing the skills, then:

```powershell
ok-ai --add-source https://github.com/mtfu/dotfiles
```

with `contentPath` = `ai/sources/personal`. Not needed for personal use.

## Current instructions

`ai/instructions/copilot-instructions.md` — one logical change per turn; the AI commits only
mechanical changes (formatting, typos, renames, generated files) and **stages** anything with
logic in it for me to review; it must **never** run `git push`; no AI attribution trailers in
commit messages.

## Current skills

- `mtfu-review-clean-verdict` — review-output threshold: "nothing worth changing" is a complete
  answer, and cosmetic nits must not be padded into findings. Never softens real defects.

The git rules are deliberately *not* a skill — they moved to instructions, where they always apply.
