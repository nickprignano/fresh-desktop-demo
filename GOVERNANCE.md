# Governance

Fresh Desktop AVD Demo runs on a lightweight engineering governance framework, under **normal
governance** — this file is the map; the actual content lives in the files below, not here.

**Tier rationale (2026-08-20):** defaulted to normal, not lite, because this project provisions real
named Azure infrastructure (AVD host pool, NAT Gateway, VM, VNet) with real RBAC/quota/licensing
dependencies, and — per Nick's explicit direction, 2026-08-20 — is by design public-facing (public
GitHub repo, live conference demo on 2026-09-29), not a throwaway/one-off script. Revisit if that
shape changes.

1. **Root changelog.** `CHANGELOG.md` — append-only, project-wide history only.
2. **Versioning guardrail.** A version number moves only when its artifacts exist and have been
   piloted/validated, never on a calendar date. This project's own RAID Assumption `ASM-1` already
   enforces this discipline for the `azuredeploy.json`/`deploy-avd-demo.html` pair — D-3/D-4 stayed
   `Open` even after implementation, specifically because they hadn't been validated against real
   Azure yet. Any exception must be an explicit, dated Decision in `FreshDesktopDemo_RAID_Crosswalk_08202026.md`.
3. **Working area vs. released snapshot.** This repo has no separate working/release branch split —
   `main` is what the Deploy-to-Azure button pulls live via raw GitHub URL (`azuredeploy.json`,
   `fresh-desktop-branding.ps1`, `office-apps-install.ps1`). This is a known, deliberately accepted
   risk, not the standard model — see RAID `R-3` ("accepted, not mitigated"). Revisit branch/tag
   pinning if review or contributor activity on `main` picks up before demo day.
4. **Sync-audit gate.** Not applicable — no sibling project depends on this one or vice versa.
5. **Naming convention.** Not yet formalized. Resource names currently default to
   `azuredeploy.json`'s `namePrefix` parameter (`avddemo`) plus ARM's own generated suffixes, with no
   written `NAMING-CONVENTION.md`. Flagged as a gap, not created in this pass — revisit if the
   resource footprint grows beyond one throwaway resource group per demo run.
6. **"Two is one, one is none."** Two known, accepted single points of failure are already disclosed
   in the RAID log rather than left silent: `R-3` (unpinned `main` branch the Deploy button pulls
   from) and `R-7` (NAT Gateway's public IP is not stable across deploy/teardown cycles — relevant to
   whoever configures Conditional Access for SSO).
7. **Run logs for manual processes.** The pre-flight sequence in `AVD-DEMO-RUNBOOK.md` is a real,
   recurring manual runbook (run before every dry run and before the live demo) but doesn't yet have
   its own dated, per-run log under `run-logs/`. Flagged as a gap, not created in this pass.
8. **Tiered honesty.** `deploy-avd-demo.html`'s live cost calculator already tiers cost by
   size/crust/topping choice. Capability estimates that depend on unresolved/unverified work are
   explicitly flagged rather than promised — see RAID Issue `I-1` (Entra SSO) and Dependency `DEP-1`
   (licensing), both open and blocking full functionality.
9. **Deployment vs. testing/validation stay separate.** Implementing a template change (D-3, D-4) is
   never treated as equivalent to validating it against real Azure — this project's RAID log already
   keeps those as separate, explicitly tracked states (see `ASM-1`).
10. **Repo location & backup discipline.** This project's working tree lives in a Cowork-connected
    local folder, mirrored to GitHub (`nickprignano/fresh-desktop-demo`, `main` branch) as the durable
    copy of record. No separate device-backup solution beyond git/GitHub has been disclosed for this
    machine — if that's a real gap, log it as a Risk via `raid-tracking` rather than leaving it
    silent.
