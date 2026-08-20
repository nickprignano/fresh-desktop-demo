# FreshDesktopDemo Project QA — Open Items Ledger

**Project:** Fresh Desktop AVD Demo (`fresh-desktop-avd-demo`) · **File Prefix:** FreshDesktopDemo · **Date Stamp:** 08202026 (fixed at first creation)

Owned by `project-qa`. One row per `finding_id`, ever surfaced — rows are never deleted, only their disposition changes.

## Run 1 — 2026-08-20

**Trigger:** `known-projects` session-start drift check (`Last project-qa Check` was blank). **Scope:** full review, this project has no contacts/follow-up/time-tracking domains initialized (deliberate, disclosed decision per `PROJECT-CONTEXT.md` Notes — not audited as gaps). **Verdict:** PASS WITH WARNINGS. **Confidence:** Directly-Confirmed (read source files directly).

| finding_id | domain | owning_skill | description | first_surfaced | clear_cut | disposition | disposition_date | disposition_note | recheck_date |
|---|---|---|---|---|---|---|---|---|---|
| CSR-MISSING | item 10 — Core Session Rules | known-projects | No `CLAUDE.md` exists at project root — Core Session Rules section was never written (project's own Notes disclose this was skipped deliberately at minimal onboarding). | 2026-08-20 | true | fixed | 2026-08-20 | Wrote `CLAUDE.md` with the verbatim Core Session Rules v1.3 section, per Nick's confirmation. | |
| DEVGOV-MISSING | item 7 — Engineering-governance currency | dev-governance | `dev-governance` is an Enabled Capability (codebase detected: `.git`, JSON/HTML/PS1 sources) but no `GOVERNANCE.md`/`CHANGELOG.md` exist yet. | 2026-08-20 | true | fixed | 2026-08-20 | Wrote `GOVERNANCE.md` (normal tier — real named-infra provisioning + now public-facing, per Nick's 2026-08-20 direction) and `CHANGELOG.md`, per Nick's confirmation. `NAMING-CONVENTION.md` and `run-logs/` remain disclosed gaps inside `GOVERNANCE.md` itself, not fixed this pass. | |
| CONTRACT-VER-GAP | item 8 — Contract-version currency | contract-governance | `Contract Versions Expected` on `PROJECT-CONTEXT.md` is explicitly logged as "not captured" / open gap, never populated. | 2026-08-20 | true | deferred | 2026-08-20 | Nick confirmed he wants this populated, but `contract-governance`'s schema registry (`DELIVERY-SKILLSET-CONTRACTS.json`/`CORE-SESSION-RULES.md`) isn't present in this install — nothing to read the expected versions from. Left `PROJECT-CONTEXT.md`'s field as an explicit disclosed gap rather than inventing a value. | 2026-09-01 |
| STATUS-SNAPSHOT-NONE | item 6 — Status snapshot cadence | status-collector | No `status-collector` snapshot exists for this `active` project. | 2026-08-20 | false | deferred | 2026-08-20 | Nick's call: no external stakeholder needs a status report for a solo public demo repo today. Revisit once teammates/reviewers are more actively involved, or ahead of the 2026-09-29 conference. | 2026-09-15 |
| RAID-ACT23-MALFORMED | item 1 — RAID currency | raid-tracking | Decisions & Actions rows `ACT-2` and `ACT-3` are each missing their `Corroboration` column value (7 fields present instead of 8), misaligning the table. | 2026-08-20 | true | fixed | 2026-08-20 | Added `logged` (the default value) to both rows, matching `ACT-1`'s existing pattern. | |
| RAID-R6-OUTOFTABLE | item 1 — RAID currency | raid-tracking | Risk `R-6` is written as freeform prose under a "Risks (continued below Issues header...)" sub-heading instead of as a normal row in the Risks table. | 2026-08-20 | true | fixed | 2026-08-20 | Moved `R-6` into the Risks table as a normal row (after `R-4`); removed the freeform sub-heading. | |

**Limitations this run:** item 11 (GitHub/repo-hosting registry currency) not checked — this session has no access to the AHEAD OneDrive `AHEAD Cowork Project Register.xlsx`, and this project's public/no-JobID status makes it unclear the registry even applies; disclosed rather than guessed. Items 2–5 (lessons capture, contacts, follow-up register, time tracking) are out of scope by the project's own recorded, deliberate decision (see `PROJECT-CONTEXT.md` Notes) — not treated as findings.

**Ledger summary:** 0 open, 4 fixed, 2 deferred, 0 dismissed. Oldest open item age: n/a (nothing currently open).
