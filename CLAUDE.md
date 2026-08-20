# Project Instructions — Fresh Desktop AVD Demo

## Core Session Rules

Core Session Rules Version: 1.3
Source Contract: CORE-SESSION-RULES
Last Synced: 2026-08-20

1. `known-projects` must run before any substantive work in this project, including a read-only
   question about the project or its own skills.
2. A read-only question about a project still requires project-identity resolution -- it is not
   exempt just because it doesn't write anything.
3. An unbacked write claim must be flagged via a `run_registry_entry` with
   `entry_type: unbacked_claim_flag`, never silently asserted.
4. Skill-to-skill invocation should use the standard invocation envelope
   (`caller_skill`/`target_skill`/`trigger_type`/`authority_level`) wherever one skill calls another.
5. Durable state must route to its authoritative owner -- a consumer must never create a shadow system
   of record for a fact another skill already owns.
6. Customer-facing output must follow the full review chain -- `fact-checker` (technical claims) →
   `ahead-brand` → `deliverable-review` → the applicable release go/no-go checkpoint → human sign-off --
   with no step skipped for time pressure or an explicit instruction to skip it.
7. A governance exception requires a named override record citing the specific policy or source of
   truth being overridden -- never a silent bypass.
8. RAID logging is a required step, not a case-by-case judgment call -- any project work that surfaces
   a RAID-worthy risk, issue, decision, dependency, or assumption must be staged to the project's RAID
   crosswalk via `raid-tracking` in the same turn, at its own default `propose_write` authority level.
9. A Cowork/connector build-mechanics finding or a skill-governance convention worth generalizing must
   be checked against, and staged to, the shared cross-project Cowork Build & Governance Playbook --
   never left to a project's own memory alone; if the page write fails or is unreachable, log it to a
   `PENDING-PLAYBOOK-SYNC.md` in this project's own folder instead of dropping it.
10. An engineer working more than one client engagement must confirm the connected folder matches the
    intended engagement before any skill runs that touches durable state, especially early in a
    session -- a read-only mistake is low-cost, but a durable write landing in the wrong client's
    crosswalk is a real cross-client contamination risk.

**This check-in is not optional and does not depend on being asked for it.**

*(This project has no client/AHD JobID — rule 10 is not applicable in practice, kept verbatim per the canonical source rather than locally edited.)*
