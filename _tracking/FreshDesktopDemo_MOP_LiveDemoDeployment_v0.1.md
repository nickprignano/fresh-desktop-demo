# Fresh Desktop AVD Demo — Method of Procedure: Live One-Click AVD Deployment & Teardown

**Scope note (mop-generator, 2026-08-20):** this skill is validated on Data Center and Modern
Datacenter/VCF engagements; AI/Cloud/AVD has no prior MOP analog checked against this skeleton. This
is the first application of it to that practice — treat the fit as a first pass, and capture anything
that doesn't generalize cleanly as a `lessons-learned` entry rather than silently forcing it. **Tracker
pattern: inline** (this is a short, single-VM, single-window change with a handful of steps — no
companion `.xlsx` tracker needed per the skill's own size threshold). **Format note:** built as
markdown, not `.docx` — this project's own convention (RAID log, runbook, README are all markdown in
a public GitHub repo), not the skill's usual client-`.docx` default; flagging the deviation rather than
silently diverging from the skeleton.

## Document metadata
| | |
|---|---|
| **Document ID** | AHEAD-MOP-AVD-DEMO-001 |
| **Prepared for** | Internal — Fresh Desktop AVD Demo (public repo, no external client) |
| **Prepared by** | Nick Prignano |
| **Document type** | Change Control Process — Method of Procedure (MOP) |
| **Target platform / version** | Azure Virtual Desktop, Personal host pool, single-session Windows 11 Enterprise (24H2/25H2/23H2) — see RAID Decision `D-3` |
| **Version** | 0.1 (Draft) |

> **What this document is NOT / IS.** Not yet an approved change record — no formal approval step
> exists for a solo internal project (flagged below as an open gap). It IS the planned procedure for
> each live/dry-run deployment of this demo, and becomes the as-executed record once a run happens.

## Revision history

| Version | Date | Author | Approved by | Changes |
|---|---|---|---|---|
| 0.1 | 2026-08-20 | Nick Prignano | (not yet approved — solo project, no formal approval step defined) | Initial draft, formalizing the pre-flight → deploy → validate → rollback sequence already documented across `AVD-DEMO-RUNBOOK.md` and the RAID crosswalk |

## 1. Purpose, scope, and companion-procedure routing

- **Change description:** Deploy a real, logged-into Azure Virtual Desktop session host via the
  `deploy-avd-demo.html` one-click trigger page, for a live audience (near-term informal run-through,
  then the 2026-09-29 conference), then tear it down.
- **Scheduled window:** Per-run — no fixed recurring schedule; triggered ahead of each dry run and the
  live 2026-09-29 conference demo. Target duration ~18–30 minutes per the runbook's own goal.
- **Change type / risk tier:** Low blast radius (single resource group, single VM, torn down after each
  run), but **public-facing and time-boxed live** — failure is visible to an audience, not just to Nick.
- **Approval required from:** None formal — solo project, no PM/approver defined. **Gap, flagged to
  raid-tracking below** rather than silently assumed fine given this is now public-facing.
- **Communication plan:** None formal — no `contacts` distribution list exists for this project (solo,
  deliberately skipped per `PROJECT-CONTEXT.md`). If teammates reviewing the repo need a heads-up before
  a live run (e.g. to avoid clicking Deploy mid-test, per RAID `ACT-1`), that's currently ad hoc, not
  tracked.

> **When to use this procedure.** Use this MOP for any live or dry-run deployment of the current
> Personal-host-pool design (`D-3`). There is no sibling procedure for the earlier Pooled/multi-session
> design — that shape was superseded, not kept as an alternate path (RAID `D-1`).

## 2. Prerequisites and gating

| Must be in place (confirm, do not remediate) | Must remediate or not supported (blocks the change until corrected) |
|---|---|
| `builder` Entra ID identity exists, has completed forced first-sign-in (MFA + password change) | If `builder` doesn't exist yet or hasn't been through interactive sign-in — create it and complete first sign-in before anything else (see Task Pre-1) |
| `builder` holds both Global Administrator (Entra role) and Owner (Azure RBAC, subscription scope) | If either grant is missing — assign it; having one does not imply the other |
| `builder`'s license includes what SSO/Office activation needs (Entra ID P1/P2 for Conditional Access, M365 Apps for Office activation on the Sausage topping) | **Currently unresolved — RAID Dependency `DEP-1`.** Reported as "E7," not a real SKU. Blocks full SSO + Office activation until the tenant's actual license inventory is checked and the right SKU assigned |
| Dasv5 quota ≥ needed vCPUs in `northcentralus` (2 for Personal Pan; more for larger sizes) | If quota shows 0 or insufficient — request a self-service increase; not instant, don't leave for the morning of |
| Resource providers registered (`Microsoft.DesktopVirtualization`, `Microsoft.Compute`, `Microsoft.Network`) | If any show unregistered — run `az provider register`, wait for `Registered` |
| Marketplace terms accepted for whichever single-session Win11 Enterprise SKU will be used on stage | **Not yet verified against the real subscription — RAID Action `ACT-2`.** Check via `az vm image terms show`; accept before the demo, not live |
| Subscription-scope RBAC grant for Start VM on Connect (`Desktop Virtualization Power On Contributor` → AVD service principal) exists | **Not yet run against the real tenant — RAID Risk `R-1`.** One-time, durable once done; the template cannot make this grant itself |
| Cloud Shell pre-provisioned for `builder` (one-time storage-account wizard cleared) | **Not yet done — RAID Action `ACT-3`.** If skipped, this friction lands in the live post-demo cleanup step instead |
| `main` branch of `nickprignano/fresh-desktop-demo` reflects the intended deploy content | **Currently a disclosed, accepted risk (RAID `R-3`)** — the Deploy button always pulls whatever is live on `main`, unpinned. Confirm nothing half-finished is on `main` before a live run |

## 3. Pre-change tasks

| # | Task | Owner | Due before window | Status |
|---|---|---|---|---|
| Pre-1 | Create/verify `builder` Entra ID identity; complete forced first sign-in at `myaccount.microsoft.com` | Nick | Before any other step | not_started |
| Pre-2 | Grant `builder` Global Administrator + Owner | Nick | Before RBAC/CLI steps | not_started |
| Pre-3 | Resolve RAID `DEP-1` — list tenant's real license SKUs, assign the correct one to `builder` | Nick | Before SSO validation | not_started |
| Pre-4 | Run one-time RBAC grant for Start VM on Connect (RAID `R-1`) | Nick (as `builder`, subscription Owner) | Once per subscription | not_started |
| Pre-5 | Verify/accept marketplace terms for the SKU(s) to be used on stage (RAID `ACT-2`) | Nick | Before first deploy with that SKU | not_started |
| Pre-6 | Confirm Dasv5 quota in `northcentralus` | Nick | Before scheduling the window | not_started |
| Pre-7 | Pre-provision Cloud Shell for `builder` (RAID `ACT-3`) | Nick | Before first live cleanup | not_started |
| Pre-8 | Push all pending local changes to `main` on GitHub | Nick | Before any dry run or the live demo | not_started |

## 4. Change-window tasks (the procedure itself)

| Step | Task | Owner | Expected duration | Status | Actual start | Actual end | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Open `deploy-avd-demo.html`, signed in as `builder` | Nick | 1 min | not_started | | | |
| 2 | Click through Pizza Size / Crust / Toppings (steps 1–3) and Pickup/Delivery (step 4 — Pickup only) | Nick | 1 min | not_started | | | |
| 3 | Generate VM admin password, click Deploy to Azure (step 5) | Nick | <1 min | not_started | | | |
| 4 | Fill Azure Portal Basics tab: subscription, region `northcentralus`, admin user/password, `namePrefix` = `avddemo` | Nick | 2 min | not_started | | | |
| 5 | Review + Create, wait for deployment (host pool, VM, NAT Gateway, extensions) | Azure (unattended) | ~18 min | not_started | | | Presentation clock auto-starts on Deploy click |
| 6 | Sign in to AVD web client / Windows App as `builder`; confirm Entra SSO completes | Nick | 2–5 min | not_started | | | Validates RAID `I-1` is actually resolved |

## 5. Validation steps

| # | What confirms success | Owner | Status |
|---|---|---|---|
| 1 | AVD session host is reachable and `builder` reaches a working desktop | Nick | not_started |
| 2 | Entra SSO completed with no manual credential prompt (validates `I-1`) | Nick | not_started |
| 3 | Session host has real outbound internet access (validates NAT Gateway fix, RAID `D-4`/`R-6`) | Nick | not_started |
| 4 | On the Sausage topping: Microsoft 365 Apps is installed/activated (validates `D-5`, contingent on `DEP-1`) | Nick | not_started |
| 5 | Desktop branding (Fresh Desktop wallpaper, dark theme) applied | Nick | not_started |

## 6. Rollback / backout procedure

- **Rollback trigger condition(s):** Deployment fails/hangs past a reasonable window (~30 min with no
  progress), a required extension fails (`AADLoginForWindows`, `OfficeAppsInstall`, branding), or SSO/
  sign-in cannot be completed live.
- **Rollback owner:** Nick (sole operator — no other rollback owner exists; flagged as a gap below).
- **Decision point:** Which of the four branches below depends on how far the deployment actually
  progressed when the trigger fired.

### 6.1 Before the change is submitted / started
Simply don't click Deploy, or close the Portal tab before Review + Create — no billable resources
exist yet, nothing to undo.

### 6.2 Failed mid-execution
| Step | Rollback task | Owner | Expected duration | Status |
|---|---|---|---|---|
| 1 | Check extension status in the Portal (VM → Extensions) to identify which one failed | Nick | 2 min | not_started |
| 2 | If unrecoverable live, cancel the deployment and delete the partially-created resource group | Nick | 2 min | not_started |

### 6.3 Succeeded but must be reversed
| Step | Rollback task | Owner | Expected duration | Status |
|---|---|---|---|---|
| 1 | On the page's cleanup step (step 8), enter the resource group name, click Copy Command & Open Cloud Shell | Nick | 1 min | not_started |
| 2 | Paste `az group delete --name <name> --yes --no-wait` in Cloud Shell, confirm | Nick | 1 min | not_started |

### 6.4 Restore from baseline (last resort)
Not applicable — this environment is fully ephemeral (torn down after every run, no persistent data or
FSLogix profile store per RAID `D-2`). There is no baseline to restore to; "restore" is simply re-running
Section 4 from a clean deploy.

## Appendix A: RACI / Ownership

Not sourced from `raci-mapping` — this project has no RACI table (solo internal project). **Gap:**
every step above defaults to Nick as sole owner with no Accountable/Consulted/Informed distinction.
Acceptable for a solo demo; worth a real RACI pass if teammates take on execution or approval roles
before the 2026-09-29 conference.

## Appendix B: Open Items / Risks

Every gap surfaced while building this MOP is already tracked in
`FreshDesktopDemo_RAID_Crosswalk_08202026.md` — cross-referenced inline above (`R-1`, `R-3`, `ACT-2`,
`ACT-3`, `DEP-1`, `I-1`, `D-2`). Two new gaps surfaced specifically by building this MOP, not
previously logged:

- **No formal approval step or distribution list exists** for a public-facing live demo (Section 1) —
  recommend logging as a RAID Risk if teammates/reviewers become more involved before 9/29.
- **No RACI table exists** (Appendix A) — single point of failure if Nick is unavailable; recommend
  logging as a RAID Risk given the public/conference commitment.

## References

`AVD-DEMO-RUNBOOK.md` (this project's existing runbook — this MOP formalizes, and should be kept in
sync with, that document's pre-flight/deploy/cleanup sections, not replace it) and Microsoft Learn's
AVD/Entra SSO documentation cited in RAID Issue `I-1`. Where this MOP and the runbook ever disagree,
treat that as a drift finding to reconcile, not a reason to trust one over the other silently.
