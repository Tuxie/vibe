# Showstopper prompt (Step 3)

After the primary pass, the orchestrator has a list of deferred clusters — each with a reason (`gate-failure:X`, `cannot-implement:Y`, `pre-condition-unmet:Z`, `frontmatter-parse-failure`). Step 3 batches them into exactly one `AskUserQuestion` so the user can resolve, accept-as-partial, or defer each.

If the list is empty, skip to Step 5.

## Data the orchestrator must have ready

For each showstopper:

- Cluster slug and goal
- Category: one of `gate-failure`, `cannot-implement`, `pre-condition-unmet`, `frontmatter-parse-failure`
- Detail line:
  - `gate-failure`: failed gate name + first 40 lines of stderr (the orchestrator captured this at Step 2)
  - `cannot-implement`: the subagent's "what would unblock this" paragraph
  - `pre-condition-unmet`: which pre-condition failed and why
  - `frontmatter-parse-failure`: the malformed field
- Attempted state: `reverted-to-pre-cluster-sha` (gate-failure or cannot-implement) or `not-attempted` (pre-condition-unmet or frontmatter-parse-failure)

## Prompt structure

```
Showstopper pass — {N} clusters need your input

The primary pass completed. These clusters were deferred. Pick one option
per cluster.

== Cluster 13-playwright-swap ==
Goal: Swap `bun test` for `bunx playwright test` in release workflow
Category: gate-failure
Detail: gate 'test' failed with
  > error: cannot find package '@playwright/test' at current Bun version
State: reverted to pre-cluster SHA

( ) Resolve with new input: _____________
    [Orchestrator will re-run the subagent with your text as additional
     context and retry the gates. No third pass — second-pass failure
     lands as partial.]
( ) Accept as partial: _____________
    [Mark Status: partial with your note. No further work. Useful when
     "we got one of the three findings done; the rest is blocked."]
( ) Defer whole: _____________
    [Mark Status: deferred with your reason. Optionally attach a
     docs/ideas/13-playwright-swap.md destination the orchestrator will
     pre-create.]

== Cluster 10-client-robustness ==
...

(Repeat per showstopper.)
```

## After the user answers

Record per cluster into working memory:

```
SHOWSTOPPER_ACTIONS = {
  "13-playwright-swap": {"action": "resolve", "input": "..."},
  "10-client-robustness": {"action": "partial", "note": "..."},
  "09-logger-migration": {"action": "defer", "reason": "...", "ideas_file": "docs/ideas/09-logger.md"},
  ...
}
```

Step 4 processes `resolve` entries. Every `partial` and `defer` is applied immediately: flip Status, set Resolved-in or Deferred-reason, run render-status.sh once at the end for the batch.

## Timeouts

If the user does not answer within a reasonable window, treat every showstopper as `defer: (no response — default defer)`. Continue to Step 5. Overnight-run contract means an unattended skill must finish, not block.

## Common mistakes

- **Asking more than once per cluster.** One `AskUserQuestion` covers all showstoppers. If the user's `resolve` input proves insufficient in the second pass, the cluster lands as `partial` — no third prompt.
- **Offering a 'retry unchanged' option.** A retry without new input would deterministically fail the same way. The three canonical choices are the only choices.
- **Running `render-status.sh` per-showstopper.** Batch the Status flips, run the script once.
- **Accepting empty free-text.** If the user picks `resolve` but the input is blank, treat it as `defer: (empty resolve input)`. Do not re-ask.
