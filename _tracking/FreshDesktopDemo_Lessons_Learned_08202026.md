# FreshDesktopDemo — Lessons Learned

Newest entries at top.

---

**Date**: 2026-08-20
**Context**: This project stayed on a "minimal onboarding" governance posture (no `CLAUDE.md`, no `GOVERNANCE.md`, `_tracking/` ledger not run) even after it was shared with teammates for review, on the reasoning that it was "just a personal demo repo." Nick pushed back explicitly once the AVD demo work resumed: public-facing status — not client-vs-internal status — is what should trigger the standard skill pipeline (`known-projects` → `project-qa` → `dev-governance`/`raid-tracking` → `mop-generator`), because a public GitHub repo and a live 2026-09-29 conference demo carry real reputational/operational exposure regardless of whether a paying client exists.
**Lesson (rule of thumb)**: "Internal, no client" is not the same test as "low stakes, skip governance." A project's actual audience/exposure (public repo, live audience, conference date) should drive whether the standard pipeline applies, independent of whether it has a client engagement behind it.
**Why it matters**: This project ran for a full session doing real infrastructure/security work (RBAC, licensing, NAT Gateway, SSO) with zero durable governance record, discoverable only because a human explicitly asked "shouldn't this have gone through the standard pipeline" after the fact — the same class of gap `project-qa`'s own roster-reconciliation check (item 14) exists to catch, just not yet triggered here because nothing flagged this folder as needing a QA pass.
**What to do differently next time**: When a project's `Client` field says "Internal" but the work is genuinely public-facing (a public repo, a scheduled external audience, a shippable artifact), treat that as equivalent to a client engagement for the purpose of deciding whether `known-projects`/`project-qa`/`dev-governance`/`mop-generator` apply — don't let the "no client" field alone justify skipping them.
**Source/handoff reference**: This session's own exchange — Nick: "even tho this is an internal initiative it should go through the same standard pipelines esp bc its by design public facing." First real application of `mop-generator` to an AVD/AI-Cloud-practice engagement (previously validated only on Data Center and Modern Datacenter/VCF) — see `FreshDesktopDemo_MOP_LiveDemoDeployment_v0.1.md`'s own scope note for what did and didn't generalize cleanly.

---

**Date**: 2026-08-20
**Context**: While iterating on `deploy-avd-demo.html`'s cost calculator, verification via `jsdom` inside this Cowork sandbox's mounted/synced project folder (`C:\local\community\avd-demo`) started hanging indefinitely on even a bare `require('jsdom')` — no error, no output, just a 120s timeout. Copying the exact same file into the session's own scratch `outputs`/tmp directory and running the identical test there worked instantly.
**Lesson (rule of thumb)**: In this Cowork sandbox, a synced/mounted local folder (e.g. a `C:\local\...` OneDrive-backed connected folder) can silently hang Node operations that touch `node_modules` — even a trivial `require()` — while the exact same code runs fine from the session's own internal scratch/outputs directory.
**Why it matters**: Without knowing this, a hang like this looks like a bug in the code being tested (or in jsdom/Node itself), and it's easy to burn a lot of time debugging the wrong layer before suspecting the environment.
**What to do differently next time**: If a Node-based test (jsdom or anything else that touches `node_modules`) hangs with zero output — even on the simplest possible `require()` — suspect the synced/mounted folder first. Copy the file(s) under test into the session's own scratch/outputs directory and re-run there before spending more time debugging the code itself.
**Source/handoff reference**: This session's own troubleshooting — confirmed by running `require('jsdom')` from `avd-demo`'s mounted folder (hung, 124 timeout) vs. an identical call from `/sessions/.../tmp/jsdomtest` (returned instantly).

---

**Date**: 2026-08-20
**Context**: Multiple `git commit`s in this same sandbox, against the same synced `avd-demo` folder, succeeded at the object level but then failed to remove their own `.git/index.lock`/`.git/HEAD.lock` files ("unable to unlink ... Operation not permitted"), which blocked the *next* git command in the session with `fatal: Unable to create '.../index.lock': File exists` — even though no second git process was actually running.
**Lesson (rule of thumb)**: In this sandbox, a git-lock-exists error immediately after (or between) commits against a synced folder is very often a stale lock the sandboxed process can't clean up itself, not a real second process or a corrupted repo.
**Why it matters**: The error message ("Another git process seems to be running... or may have crashed") reads like a real problem and invites over-investigation, when the actual fix is trivial — but only if it's recognized for what it is.
**What to do differently next time**: When this error appears, first check whether the prior commit actually landed (`git log --oneline -3`) before assuming failure. If it did land and the lock is just blocking the *next* operation, the fix is removing `.git/index.lock` and `.git/HEAD.lock` — note that the sandbox itself frequently can't unlink these either (`Operation not permitted`), so this usually has to be done from the user's own machine (`Remove-Item .git\index.lock, .git\HEAD.lock -Force`), not treated as a real git/repo problem to diagnose further.
**Source/handoff reference**: Recurred across at least 3 separate commits this session on `avd-demo`; originally first documented in a prior session's handoff for this same repo.

---

**Date**: 2026-08-20
**Context**: `deploy-avd-demo.html`'s "Deploy to Azure" button always opens the Azure Portal against a fixed GitHub **raw** URL for `azuredeploy.json` on the `main` branch. Mid-session, the user tested the live page and reported the newly-added toppings/crust options "didn't land" — turned out the ARM template edits were sitting locally, committed but not yet pushed, so the Portal was still loading the stale version already live on GitHub.
**Lesson (rule of thumb)**: Any page (this one, or a future one built the same way) that deep-links to a GitHub **raw** URL for its "live" config/template will keep silently serving whatever's currently pushed to that branch — a local edit or even a local commit has zero effect on what the linked page actually loads until it's pushed.
**Why it matters**: This makes "the live page doesn't reflect my change" a highly plausible first support question with a totally different root cause (git state, not application logic) — worth checking git push status first before debugging the template/HTML logic itself.
**What to do differently next time**: Before investigating a "my change didn't show up" report on a raw-URL-linked page like this one, check `git status`/`git log` vs. `origin/main` first. If local commits are ahead of the remote, that's very likely the whole explanation — no code debugging needed, just push.
**Source/handoff reference**: This session's own "i think something broke, ... the toppings didnt land" exchange — root cause confirmed via `git status` showing local commits ahead of `origin/main`.
