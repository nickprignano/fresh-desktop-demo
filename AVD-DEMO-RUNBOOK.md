# AVD One-Click Demo — Runbook

Goal: click a button on a web page, get a real, logged-into Azure Virtual Desktop desktop, in under 30 minutes, in your AVD/Nerdio demo subscription.

## What this deploys

- One AVD host pool (**Personal**, `personalDesktopAssignmentType: Automatic`, `startVMOnConnect` on — switched from Pooled/multi-session 2026-08-20; see Decision D-3 in the RAID log)
- One desktop application group + one workspace
- One Windows 11 Enterprise (**single-session**) VM, **Microsoft Entra ID–joined only** — no domain controller, no AD DS, no hybrid join
- Outbound internet via a **NAT Gateway** (Standard SKU, static public IP) — the VM has no public IP and isn't open to inbound internet traffic. This replaces reliance on Azure's now-retired "default outbound access," which new VNets stopped getting after 2026-03-31 (see Risk R-6). **Note for whoever configures Conditional Access for SSO (below): this NAT Gateway's public IP is not stable across deploy/teardown cycles** — avoid IP-based location conditions on this flow (Risk R-7).
- RBAC: whoever runs the deployment is automatically granted `Desktop Virtualization User` on the app group and `Virtual Machine User Login` on the VM (via the ARM `deployer()` function) — no manual object-ID lookups needed. **Start VM on Connect additionally needs a one-time, subscription-scope RBAC grant that the template itself cannot make — see pre-flight step 3a.**
- **Pizza-themed flavor pickers**: Pizza Size (VM size: Personal Pan / Family Size / Large Party), Crust (OS disk tier, Chicago-style naming: Thin / Stuffed / Deep Dish = Standard HDD / Standard SSD / Premium SSD), and Toppings (Windows 11 Enterprise image version: Cheese = 24H2 / Sausage = 25H2, newest, **+ Microsoft 365 Apps installed post-deploy (see below)** / Pepperoni = 23H2, older — single-session Enterprise has no marketplace SKU with Microsoft 365 Apps *preinstalled*, so as of 2026-08-20 only Sausage gets Office, via a real post-install step, not a baked-in image) are each a row of real, clickable buttons on the page itself (steps 1–3), previewing live pricing as you go — and the exact same three choices also render natively as real ARM-parameter dropdowns in the Azure Portal's own deployment form once you deploy, so what you pick on the page is what you match in the Basics tab. All default-selected so Review + Create needs zero clicks, but every option is a real, changeable dropdown on stage. Every combination still lands inside the same ~18-minute deploy window — none of these add real time to the *session host becoming available*, they just change $/hr, in-session performance, and (for Sausage) whether Office is ready the instant you log in. Note: the clipboard/drive-redirection toggle (pizza-themed as a "pepperoni" Yes/No switch) only ever lived in the Portal's own Basics tab, not on the page — so "Pepperoni" now names both one of the three page-side Topping choices and, unrelatedly, that Yes/No clipboard-redirection toggle in the portal. Same word, two different fields; worth a glance before a live demo so it doesn't trip you up. **The separate "extra cheese" session-capacity toggle was removed entirely 2026-08-20** — it set the host pool's max concurrent session limit, which is meaningless for a Personal host pool (always exactly one user per VM); see Decision D-3.
- **Office Apps post-install (Sausage only, added 2026-08-20):** a fourth VM extension (`OfficeAppsInstall`, `CustomScriptExtension`, conditioned on the Sausage topping) installs Microsoft 365 Apps for enterprise via the Office Deployment Tool, Monthly Enterprise Channel, with Shared Computer Activation enabled (Microsoft's documented best practice for any AVD host pool). It depends only on the VM existing — same dependency level as `AADLoginForWindows` — so it starts immediately at boot, in parallel with the Entra-join step, not gated on anyone signing in. On Family Size or Large Party it typically finishes before the Entra-join + AVD-agent-registration chain does, so Office is usually ready the moment you can actually log in; on Personal Pan it may still be finishing (expected, not a bug). **Activation depends on `builder`'s license actually including Microsoft 365 Apps** (M365 E3/E5 does; a standalone Entra ID P1/P2 does not) — ties directly to Dependency DEP-1's licensing outcome. **Decided 2026-08-28 — closes `DEP-1`:** going with **Microsoft 365 E3, month-to-month**, not F3 — confirmed via Microsoft Learn that F3 doesn't include desktop Microsoft 365 Apps (web/mobile only), so it would have satisfied the Conditional Access/Entra ID P1 need in item 3aa.3 below but left this Office-activation half of `DEP-1` unresolved. E3 covers both. Purchase was in progress as of this writing (tenant had zero licenses assigned at last check) — confirm the license has actually landed and is assigned to `builder` before the next dry run, since this gates whether the Sausage topping's Office install actually activates.
- **Auto-destroy after (step 5, added 2026-08-23):** a slider next to the Deploy button sets how many
  hours (1–12, default 4) until Azure tears the whole resource group down on its own — matches the
  `selfDestructHours` ARM parameter, which you also pick in the Portal's Basics tab like the other
  choices. The template itself never deletes anything; it only tags the resource group
  (`OrderNumber`, `DeployedAtUtc`, `SelfDestructAtUtc`, `SelfDestructHours`, `DeployedBy`) so the
  separate lab-manager Cowork project's teardown backend can read the deadline and delete it,
  recording destruction against the same `OrderNumber` tag for independent verification on both
  sides. **Double-tagged 2026-08-23** with lab-manager's own `LabExpiryDate`/`LabExpiryMode`/`LabKit`
  keys per their confirmed schema (`LabExpiryDate` duplicates `SelfDestructAtUtc` verbatim) — as of
  today this is schema compliance only, since lab-manager's own killswitch doesn't yet act on these
  tags for any workload (their I-15). See RAID `D-7`/`R-12`/`DEP-2` and
  `FreshDesktopDemo_ADR_Log_08232026.md` ADR-2. **This is a backstop, not a replacement for step 8**
  — do the manual cleanup below right after the demo as before; the tag-driven teardown is only there
  for when that doesn't happen.
- **Pickup or Delivery? (step 4, added 2026-08-20):** a fourth picker for the outbound-networking model. **Pickup** (NAT Gateway) is the only working option right now — simple outbound-only egress, no filtering, matches D-4. **Delivery** (Azure Firewall Basic, FQDN-filtered/governed egress) is shown greyed-out as "Coming Soon" — real UI, not wired to anything yet. See Scope Discovery SD-1 for the underlying decision to defer it, and flag to Nick before treating "Coming Soon" as a real timeline commitment.
- **Pizza delivery tracker** on the landing page: a 5-stage animated progress bar (Order Placed → Prepping Your Pie → In the Oven → Out for Delivery → Delivered) timed to the real ~18-minute deployment. Click any stage icon anytime to jump the tracker if the live deployment runs ahead or behind — built fresh for this, not reused from any other project.

- **Desktop branding**: a `FreshDesktopBranding` `CustomScriptExtension` generates an Italian-tricolor "Fresh Desktop" wallpaper — the name in the same casing as the page's own brand treatment, paired with a drawn pizza-slice icon rather than text alone — on the VM itself, and applies it machine-wide via the Windows Personalization policy, plus seeds the default user profile with a dark theme and a green accent color so a brand-new Entra profile picks it up on first sign-in. Runs in parallel with the other extensions, so it doesn't add to the ~18-minute critical path. **Correction 2026-08-20:** this script is fetched at deploy time via `fileUris` pointing at the repo's raw GitHub URL, the same as `office-apps-install.ps1` (below) — it is **not** actually gzip+base64-embedded in the template despite what earlier revisions of this doc claimed. Practical effect: Risk R-3's branch-pinning exposure (a push to `main` mid-edit changing what deploys) applies to **both** PowerShell scripts, not just `azuredeploy.json` itself.
- **Top-right badge, two states**: before you deploy, it shows the live price total for whatever you've picked in steps 1–3 (updates as you click through). The moment you click Deploy in step 5, it permanently swaps to the presentation clock — a one-way flip, it doesn't go back to showing price after that. The clock auto-starts the instant Deploy is clicked (no extra click, no manual Start needed), and won't restart if you click Deploy twice. Color shifts green → amber at 15:00 remaining → pulsing red at 5:00. If it hits 0:00 before you're done, it doesn't stop — it flips to a red "Overtime" display and counts up, so you never lose your on-screen clock mid-demo. Only manual controls are a single **Pause/Resume** toggle and **Reset**; it also auto-pauses the moment you click through to the AVD web client in step 7, since the clock stops mattering once you're live in the desktop.
- **Live cost calculator** (steps 1–3, total shown in step 5): pick your Pizza Size, Crust, and Toppings on the page in steps 1–3 — each has its own row of real, clickable choices instead of a wall of text — and step 5 shows the combined live total (hourly rate, a ~20-minute demo estimate, monthly-if-left-running, and an order-summary line to match in the portal) pulled from the Azure Retail Prices API for `northcentralus`. Falls back to a small hardcoded rate table per disk tier if that call is ever blocked, and says so on the page. The same total also mirrors into the top-right badge (see above) until Deploy is clicked.
- **Steps reveal progressively, all the way through this time**: step 1 (Pizza Size) is the only one visible on page load; clicking any button in step 1 reveals step 2 (Crust), clicking any button there reveals step 3 (Toppings), clicking any button there reveals step 4 (Pickup/Delivery), and clicking Continue there reveals step 5 (password + Deploy) — so you move through the order one pick at a time instead of seeing everything at once. From step 5 onward it's the same pattern as before: Deploy reveals and auto-starts the tracker, and the tracker hitting Delivered reveals Log In and Cleanup together. The password field inside step 5 stays hidden until you actually click Generate.
- **Black/neutral color palette** — background and UI chrome are solid black and neutral gray, with only the Italian tricolor (green/red/white) and status green/red as accent colors. Deliberately has no blue anywhere and no corporate branding of any kind, so it reads as its own independent thing on stage rather than a company slide deck.

Files: `azuredeploy.json` (the template), `deploy-avd-demo.html` (the trigger page + tracker + countdown), `fresh-desktop-branding.ps1` and `office-apps-install.ps1` (the two extension scripts — both fetched by the template at deploy time via raw GitHub URL, **not** embedded in the template; keep this in mind for Risk R-3), `LICENSE` (MIT — this is a public repo).

## Before tomorrow — do this today, not live

1. **Set up and unlock the `builder` deployment identity — do this first, it has its own gotcha.** Use a dedicated Entra ID account named `builder` for deployment and on-stage demo login:
   - **Not** the original outlook.com / tenant-creator account — it's an MSA-bridge identity with its own MFA/sign-in quirks that don't behave like a normal Entra account, and it's kept as the break-glass account (see below).
   - **Not** the break-glass account — leave that untouched, emergency-only.

   **Account model (resolved 2026-08-27, closes RAID `I-1` — see 3aa item 5 below):** three separate identities, deliberately not one do-everything account:
   - **`builder`** — **Azure RBAC Owner only** (subscription scope), **no Entra directory role**. Deploys the template and signs into the AVD desktop on stage.
   - **A dedicated Entra-admin account** — holds an Entra directory role (Global Administrator or, at minimum, Security Administrator / Conditional Access Administrator), used only to configure Conditional Access, Security Defaults, and per-user MFA (3aa below), and to manage `builder`'s own role assignments. Never used for deploy or demo login.
   - **The original outlook.com / tenant-creator account** — holds **both** Entra Global Administrator and Azure Owner. Break-glass/tenant-bootstrap only, untouched, not used for routine setup or demo work.

   This replaces the single-identity assumption this step originally documented (`builder` holding both Global Administrator and Owner) — see 3aa item 5 for why it changed.

   **Gotcha:** a brand-new Entra ID user is forced through MFA registration and a password change on first use, and that has to happen via an interactive browser sign-in — go to `https://myaccount.microsoft.com`, sign in as `builder`, and complete both prompts. Do this *before* trying `az login` or signing into the portal as `builder`; a fresh account that's never been through interactive sign-in will fail or hang on `az login`.

2. **Confirm Dasv5 quota in `northcentralus` — required pre-flight, not just a troubleshooting note.** This subscription's "Standard DSv5 Family vCPUs" quota started at **0** in `northcentralus` (and `centralus`) and was never granted, so the template's VM sizes were switched from Dsv5 to **Dasv5** (`Standard_D2as_v5` / `D4as_v5` / `D8as_v5`) — a self-service quota increase to 10 "Standard DASv5 Family vCPUs" in `northcentralus` was requested and approved instead. Confirm that quota is still in place:
   - Azure Portal → **Quotas** → **Compute** → filter to **DASv5**, region `northcentralus`
   - Should show at least enough vCPUs for the demo VM (2 for Personal Pan; more if you plan to demo a larger Pizza Size live)
   - If you ever need more, self-service increases are usually fast but not instant — don't leave it for the morning of.

3. **Confirm resource providers are registered** in your demo subscription (first-time registration can eat several minutes of your 30). **Updated 2026-08-24 (RAID R-15 / data-governance F3 fix):** the Log Analytics workspace and diagnostic settings added for monitoring bring two more providers into the template — add them to the same check:
   ```
   az provider register --namespace Microsoft.DesktopVirtualization
   az provider register --namespace Microsoft.Compute
   az provider register --namespace Microsoft.Network
   az provider register --namespace Microsoft.OperationalInsights
   az provider register --namespace Microsoft.Insights
   az provider show -n Microsoft.DesktopVirtualization --query registrationState -o tsv
   az provider show -n Microsoft.OperationalInsights --query registrationState -o tsv
   az provider show -n Microsoft.Insights --query registrationState -o tsv
   ```
   Wait until each shows `Registered`. **Note (confirmed via Microsoft Learn, 2026-08-24):** ARM auto-registers any resource provider whose type appears as an explicit resource in a template deployment (Portal or CLI) if it isn't already registered — so a Portal-only deploy won't hard-fail on a fresh subscription the way it would for a provider Azure can't infer from the template. Running this check ahead of time isn't required to make the deploy succeed; it's here because auto-registration can add a few minutes of latency on a provider's *first-ever* use in a subscription, and that latency lands inside the same ~18-minute timed window as everything else. `Microsoft.OperationalInsights` and `Microsoft.Insights` are near-universal providers (Log Analytics and the platform Activity Log both depend on them) and are registered by default on most subscriptions that have ever created any monitored resource — so this is a low-risk, fast sanity check, not a likely blocker, but check it once for a brand-new/sandboxed lab subscription rather than discovering it live.

3a. **One-time RBAC grant for Start VM on Connect (Risk R-1) — do this once per subscription, not per deploy.** The template cannot grant this itself: a subscription-scope role assignment can't be made from inside a resource-group-scoped ARM deployment without restructuring the whole template. Run once, as `builder` (who already holds subscription Owner):
   ```
   az ad sp list --display-name "Azure Virtual Desktop" --query "[].id" -o tsv
   az role assignment create --assignee <object ID from above> --role "Desktop Virtualization Power On Contributor" --scope /subscriptions/<subscription ID>
   ```
   This grant is durable — once done for a subscription, it never needs to be redone on later deploy/teardown cycles.

3b. **Verify marketplace terms for the new single-session image.** The old multi-session SKU (`win11-24h2-avd`) was a confirmed no-terms-needed no-op — that doesn't automatically carry over to the new single-session Enterprise SKUs (`win11-24h2-ent` / `win11-25h2-ent` / `win11-23h2-ent`). Check whichever you plan to actually use on stage:
   ```
   az vm image terms show --urn MicrosoftWindowsDesktop:windows-11:win11-24h2-ent:latest
   ```
   If terms aren't accepted, run `az vm image terms accept --urn ...` for that exact SKU before the demo, not live.

3aa. **SSO / Conditional Access pre-flight (Issue I-1) — do this before the next dry run, not after another failure.** Per Microsoft's own troubleshooting guide for AVD SSO/Conditional Access, work through this in order:
   1. **Security Defaults — confirmed disabled 2026-08-28.** Microsoft's docs and multiple confirmed support cases describe this exact shape: *if Security Defaults are enabled, Global Administrators are always forced through MFA at VM sign-in, independent of per-user MFA or Conditional Access settings.* This step originally applied directly to `builder`, which held Global Administrator by design; `builder`'s Global Administrator role has since been removed (see account model in step 1 above and item 5 below), and Security Defaults itself has now been turned off tenant-wide (Entra admin center → Identity → Overview → Properties → Security Defaults → **No**) by the Entra-admin account, specifically so Conditional Access (items 2–4 below) could actually take effect — Security Defaults and Conditional Access can't run at once.
   2. **Per-user MFA — confirmed disabled tenant-wide, 2026-08-28.** Entra admin center → Identity → Users → All users → **Per-user MFA** toolbar button → all users, including `builder`, show **Disabled**. This is required on Entra-joined session hosts regardless of Conditional Access — it isn't just a caveat, it actively breaks sign-in ("The sign-in method you're trying to use isn't allowed").
   3. **Two-policy Conditional Access structure — built 2026-08-28.** Policy 1 (`MFA - Azure Virtual Desktop (feed-gateway)`) targets the **Azure Virtual Desktop** app (`9cdead84-a844-4324-93f2-b2e6bb768d07`); Policy 2 (`MFA - Windows Cloud Login (session-host SSO)`) targets the **Windows Cloud Login** app (`270efc09-cd0d-444b-a71f-39af4910ec45`). Both target the `grp-avd-demo-users` group (currently just `builder`), Client apps scoped to Browser + Mobile apps and desktop clients, Grant = Require MFA. Sign-in frequency: Policy 1 = Periodic reauthentication, 1 hour; Policy 2 = **Every time** (the strictest option, only supported on Windows Cloud Login — deliberately set higher than Policy 1, not just matching, per this engagement's enterprise-ready bar). Requires Entra ID P1/P2 — ties directly to Dependency DEP-1's licensing question. **Decided 2026-08-28 — closes `DEP-1`:** went with **Microsoft 365 E3, month-to-month** (not F3 — see the Office Apps note above under "What this deploys" for why), assigned to `builder` via a `grp-license-m365-e3` group, confirmed active.
   4. **No stray "All cloud apps" policy — resolved 2026-08-28, but not a non-issue: one was found and fixed.** Disabling Security Defaults (item 1) triggered Microsoft to auto-create a **Microsoft-managed** Conditional Access policy, "Multifactor authentication for all users," scoped to All users / All cloud apps / Require MFA, with no sign-in frequency control set — a safety net so the tenant isn't left with zero MFA coverage, but exactly the kind of blanket policy this item warns about, since it also covered the Azure Virtual Desktop and Windows Cloud Login apps with no coordination with the two-policy structure in item 3. Microsoft-managed policies can't have their scope edited directly, so the fix was: **Duplicate** it into a custom policy ("Require multifactor authentication for all users - AVD Apps Excluded") that excludes both AVD apps from its cloud-apps scope, turn that duplicate **On**, then set the *original* Microsoft-managed policy's state to **Off** (its State field has its own Edit control, separate from full policy edit). End state: the duplicate covers the rest of the tenant, the two dedicated policies in item 3 have exclusive control over the AVD apps. General lesson for future Security-Defaults toggles in this tenant: check for a newly auto-created Microsoft-managed policy afterward, don't assume disabling Security Defaults leaves a clean slate.
   5. **Resolved 2026-08-27 — RAID `I-1` closed.** This step originally posed an open decision between two options: (a) keep `builder` as a single do-everything Global Admin identity and structure Conditional Access/Security Defaults so a Global Admin can still sign in cleanly, or (b) split the identity — keep `builder` for one-time admin setup and introduce a second, ordinary account just for the demo login on stage (which would need its own RBAC role assignment, since the template's `deployer()` grant is tied to whoever actually deployed). **Neither — resolved a third way:** `builder` keeps a single identity for both deploy and demo login, but has had its Global Administrator role removed entirely; Entra-side configuration (Conditional Access, Security Defaults, per-user MFA) moved to a dedicated Entra-admin account that's never used for deploy or demo login (see the account model in step 1 above). This closes the original risk (Global-Admin-forced-MFA on `builder`) without the added complexity option (b) would have introduced. **Items 2–4 above are now also confirmed done (2026-08-28)** — the full pre-flight SSO/CA setup is complete pending an actual dry-run login to verify it behaves as expected end-to-end (see item 6 below and step 6 further down).
   6. Diagnose any remaining failure directly from the evidence, not guesswork: **Entra admin center → Identity → Monitoring & health → Sign-in logs**, filtered to `builder`, looking at both the **Azure Virtual Desktop** and **Windows Cloud Login** app entries for the failure window — the **Conditional Access** tab on each failed entry names the exact policy that blocked it.

   Source: [Troubleshoot single sign-on and Conditional Access for Azure Virtual Desktop](https://learn.microsoft.com/troubleshoot/azure/virtual-desktop/troubleshoot-sso-conditional-access), [Enforce Microsoft Entra multifactor authentication for Azure Virtual Desktop using Conditional Access](https://learn.microsoft.com/azure/virtual-desktop/set-up-mfa).

3c. **Pre-provision Cloud Shell for `builder`.** First-ever Cloud Shell launch forces a one-time storage-account/file-share setup wizard — that friction currently sits directly in the post-demo cleanup step (step 7 on the page). Sign in to https://shell.azure.com as `builder` once, ahead of time, so cleanup on demo day is an actual single paste-and-enter.

3d. **Optional but recommended: one-time self-destruct watcher, per subscription.** `azuredeploy.json` tags every deployed resource group with a `SelfDestructAtUtc` deadline (see step 5's slider below), but the template itself never deletes anything — something has to actually read that tag and act on it. If you're deploying inside AHEAD's own lab-manager-governed lab, check with lab-manager first (as of 2026-08-23 its coverage of this specific workload has a known gap — see RAID `DEP-2`/`I-14` — so don't assume it's covered). For everyone else (this is a public repo — forking this to run in your own subscription is expected), or as AHEAD's own interim backstop, set up this small self-contained watcher once. **CLI only, by design — never packaged as an ARM/Bicep template** (see ADR-3):

   ```bash
   # One-time per subscription — run from Cloud Shell (bash) or any shell with az CLI + login.
   # Validated 2026-08-28 against a real subscription. Two of the commands below don't match the
   # current `az automation` CLI extension (it's marked experimental) and need a direct ARM REST
   # workaround instead — noted inline. `az automation runbook show` also doesn't reliably reflect
   # draft content/state in this extension; don't use it to sanity-check the upload in step 4, trust
   # the command's own exit code instead.

   # 0. Install the automation extension if prompted (preview; required for every command below)
   az extension add --name automation --yes

   # 1. Small resource group to hold the watcher (kept separate so it never gets deleted with a demo RG)
   az group create --name rg-freshdesktop-watcher --location northcentralus

   # 2. Automation Account, then a system-assigned managed identity via direct REST — `--assign-identity`
   #    is not a real flag on `automation account create` (confirmed 2026-08-28), and there's no
   #    dedicated identity-assignment command for Automation Accounts in this extension either.
   SUB_ID=$(az account show --query id -o tsv)
   az automation account create \
     --automation-account-name aa-freshdesktop-watcher \
     --resource-group rg-freshdesktop-watcher \
     --location northcentralus \
     --sku Basic
   az rest --method patch \
     --url "https://management.azure.com/subscriptions/$SUB_ID/resourceGroups/rg-freshdesktop-watcher/providers/Microsoft.Automation/automationAccounts/aa-freshdesktop-watcher?api-version=2023-11-01" \
     --body '{"identity": {"type": "SystemAssigned"}}'
   PRINCIPAL_ID=$(az rest --method get --url "https://management.azure.com/subscriptions/$SUB_ID/resourceGroups/rg-freshdesktop-watcher/providers/Microsoft.Automation/automationAccounts/aa-freshdesktop-watcher?api-version=2023-11-01" --query identity.principalId -o tsv)

   # 3. One-time, durable grant — Contributor at subscription scope. Needed because the demo's
   #    resource group name/prefix varies per deploy, so the watcher can't be scoped narrower
   #    ahead of time (same style of grant as the Start VM on Connect RBAC in step 3a).
   az role assignment create --assignee "$PRINCIPAL_ID" --role "Contributor" --scope "/subscriptions/$SUB_ID"

   # 4. Publish the watcher runbook (fetched from this repo, same raw-GitHub hosting pattern as
   #    the VM extension scripts — see Risk R-3 for the branch-pinning caveat that applies here too)
   curl -s -o self-destruct-runbook.ps1 https://raw.githubusercontent.com/nickprignano/fresh-desktop-demo/main/self-destruct-runbook.ps1
   az automation runbook create \
     --automation-account-name aa-freshdesktop-watcher \
     --resource-group rg-freshdesktop-watcher \
     --name SelfDestructWatcher \
     --type PowerShell
   az automation runbook replace-content \
     --automation-account-name aa-freshdesktop-watcher \
     --resource-group rg-freshdesktop-watcher \
     --name SelfDestructWatcher \
     --content @self-destruct-runbook.ps1
   az automation runbook publish \
     --automation-account-name aa-freshdesktop-watcher \
     --resource-group rg-freshdesktop-watcher \
     --name SelfDestructWatcher

   # 5. Recurring hourly schedule, then link it to the runbook via direct REST — `az automation
   #    job-schedule create` does not exist in the current CLI extension (confirmed 2026-08-28; the
   #    only subgroups are account/configuration/hrwg/job/python3-package/runbook/runtime-environment/
   #    schedule/software-update-configuration/source-control — no job-schedule), so the JobSchedule
   #    resource has to be created directly.
   az automation schedule create \
     --automation-account-name aa-freshdesktop-watcher \
     --resource-group rg-freshdesktop-watcher \
     --name hourly \
     --frequency Hour \
     --interval 1 \
     --start-time "$(date -u -d '+10 minutes' +%Y-%m-%dT%H:%M:%SZ)"
   JOB_SCHEDULE_ID=$(python3 -c "import uuid; print(uuid.uuid4())")
   az rest --method put \
     --url "https://management.azure.com/subscriptions/$SUB_ID/resourceGroups/rg-freshdesktop-watcher/providers/Microsoft.Automation/automationAccounts/aa-freshdesktop-watcher/jobSchedules/$JOB_SCHEDULE_ID?api-version=2015-10-31" \
     --body '{"properties": {"schedule": {"name": "hourly"}, "runbook": {"name": "SelfDestructWatcher"}}}'
   ```

   Check it worked: Portal → the `aa-freshdesktop-watcher` Automation Account → **Jobs** — each hourly
   run's output lists every tagged resource group it found and whether it deleted or skipped it. That
   job history is also your confirmation trail that a given demo's resource group actually got torn
   down, without needing anything more than what Azure already gives you for free. **Validated
   2026-08-28 — closes RAID `D-8`:** ran hourly against a real subscription for a full week with zero
   failed jobs.

4. **Template hosting is already handled — nothing to set up.** `azuredeploy.json` is hosted permanently at the public repo [`nickprignano/fresh-desktop-demo`](https://github.com/nickprignano/fresh-desktop-demo) and fetched directly by the Azure Portal at deploy time via its raw URL (default branch confirmed as `main` at build time — if you ever repoint or recreate the repo, re-verify the default branch before trusting the raw URL). The only time you touch GitHub again is if you edit `azuredeploy.json` locally and need to push that change to the repo before your next dry run or the live demo — the portal always fetches whatever's currently live there, not your local copy.

5. **Open `deploy-avd-demo.html`** in your browser, signed in as `builder`. Everything from here is button clicks: click through Pizza Size / Crust / Toppings in steps 1–3 (clicking the already-highlighted default button still works and still advances you to the next step — each step stays hidden until you click something in the one before it), continue past step 4 (Pickup/Delivery — Pickup is the only working option), then in step 5 generate a VM admin password and click **🚀 Deploy to Azure** — it opens the Azure Portal deployment page directly against the hosted template, in a new tab, and starts the presentation clock and order tracker automatically.

6. **Do one full dry run today**, not the morning of. Confirm the presentation clock (top-right) auto-starts when you click Deploy with no manual Start needed, that its color transitions (green → amber at 15:00 → pulsing red at 5:00) feel right against how long the real deployment actually takes, and — if you have a spare minute — let it run past 0:00 once to see it flip to red "Overtime" and count up, so it doesn't surprise you live. Click Deploy, fill in:
   - Subscription: your AVD/Nerdio demo sub, signed in as `builder`
   - Region: **`northcentralus`** (Chicago — physically closest to where the demo is happening, and where you hold the Dasv5 quota confirmed in step 2 above)
   - Admin username/password for the VM (this is a *local* fallback account on the VM itself, unrelated to the `builder` Entra identity — you'll sign in to AVD with `builder`, not this one)
   - Leave `namePrefix` as `avddemo` or shorten if you want a distinct run
   - Review + create

6a. **Repeat the full pass on the iPad, from a clean slate.** Fully tear down (`az group delete`) before redeploying for the iPad pass — a Personal host pool with Automatic assignment binds the VM to whichever identity connects first and stays bound, so a stale environment (or a teammate clicking the public repo's Deploy button in the meantime) can claim that assignment ahead of your intended test. While on the iPad, also confirm `builder`'s registered MFA method is actually completable from that device, not just the laptop — a sign-in with an MFA method bound to a device that isn't physically on stage fails live with no recovery path.

7. **Time it.** Expect roughly:
   - ~2–3 min: networking + host pool/workspace/app group
   - ~3–5 min: VM provisioning
   - ~5–8 min: Microsoft Entra join (AADLoginForWindows extension)
   - ~5–8 min: AVD agent registration (DSC extension)
   - Total: ~15–20 minutes is typical; budget the full 30 to be safe.

8. **Log in.** Once the portal says "Your deployment is complete," go to `https://client.wvd.microsoft.com/arm/webclient/`, sign in as `builder`, and your desktop should appear and connect. First sign-in to a fresh Entra-joined VM can take an extra minute while the profile is created.

## During the Darrell demo

- Have `deploy-avd-demo.html` already open, signed in as `builder`. There's no repeat setup step on your laptop anymore — the `builder` account's MFA/password unlock and the `northcentralus` Dasv5 quota (pre-flight steps 1–2 above) are one-time per account/subscription and should already be done by show time.
- Optionally click through the **Pizza Size / Crust / Toppings** pickers in steps 1–3 first — each click reveals the next step and updates the live price total in the top-right badge — before you ever hit Deploy.
- Click **🚀 Deploy to Azure** in step 5; the page opens the Azure Portal directly against the hosted template, and both the presentation clock (top-right) and the order tracker start automatically — no separate click for either. The tracker card reveals itself and scrolls into view right away, so there's nothing to remember to switch on. When the portal's Basics tab loads, match the Pizza Size / Crust / Toppings dropdowns to whatever you picked on the page — defaults are already picked to match, or change one live for fun before hitting Review + Create.
- Narrate each stage as it lights up on the tracker. It's a choreographed timer synced to typical deploy timing, not a live Azure feed — if the real deployment visibly finishes a stage early or late, just click the matching stage icon to resync. You're always in control on stage; nothing here can desync embarrassingly if you drive it.
- Once the tracker hits **Fresh Out of the Oven**, the Log In and Cleanup cards reveal themselves automatically — you don't need to scroll to steps that weren't ready yet. Clicking **Open AVD Web Client** auto-pauses the presentation clock, since it stops mattering once you're live in the desktop.
- If you're worried about live provisioning time, consider deploying ~20 minutes before you're on, then just doing the login + narration live, and mentioning the deploy step is one click. Use the **8x rehearse** speed toggle beforehand to practice the narration without waiting 18 minutes each time. If you reset and re-rehearse, hit **both** the tracker's Reset (which also re-hides Log In/Cleanup) and the presentation clock's Reset, so nothing shows stale state when you go live.

## Troubleshooting

- **Deploy button opens the portal but the template looks stale or fails to load:** the page always points at the fixed repo's raw URL (`https://raw.githubusercontent.com/nickprignano/fresh-desktop-demo/main/azuredeploy.json`). If you've edited `azuredeploy.json` locally, push/commit it to that repo first — the portal fetches whatever's currently live there, not your local copy.
- **Marketplace image terms — expected no-op for this image, not an error:** if you (or a pre-flight habit) run
  ```
  az vm image terms accept --urn MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest
  ```
  Azure returns **"has no terms to accept"** for this specific SKU. That's expected — this image doesn't require the usual marketplace terms acceptance, so seeing that message during a dry run is not a failure and needs no follow-up action. If a *different* deployment error mentions marketplace/purchase eligibility, it's unrelated to this command and needs its own investigation. **This note describes the old multi-session SKU; the template now uses single-session Enterprise SKUs (`win11-*-ent`) — see pre-flight step 3b, which hasn't confirmed the same no-terms-needed behavior for those yet.**
- **Sausage topping's Office install didn't finish / Office isn't there:** check `C:\OfficeAppsInstall.log` on the VM (portal's "Run command", or RDP if you have a fallback path). Common causes: (1) it's still running — on Personal Pan this can genuinely still be in progress when you log in, that's expected; (2) the dynamic Office Deployment Tool URL resolution failed because Microsoft changed the download-confirmation page's structure — the log will show this explicitly; (3) `builder`'s license doesn't actually include Microsoft 365 Apps (see Dependency DEP-1) — Office installs but won't activate.
- **AADLoginForWindows extension fails:** almost always a managed-identity or connectivity issue. RDP/console into the VM isn't needed — check the extension status in the portal (VM → Extensions). See [Microsoft's troubleshooting guide](https://learn.microsoft.com/entra/identity/devices/howto-vm-sign-in-azure-ad-windows#troubleshoot-deployment-problems).
- **Deployed fine but can't log in ("account configured to prevent you from using this device"):** the RBAC role assignments didn't land — check IAM on the application group and the VM for your account under `Desktop Virtualization User` / `Virtual Machine User Login`. The template assigns these automatically to whoever runs the deployment; if someone else clicks Deploy, they get the access, not you.
- **Wallpaper/theme didn't show up:** the branding script logs to `C:\FreshDesktopBranding.log` on the VM (RDP or use the portal's "Run command" to check). The wallpaper itself is applied machine-wide via policy and should show up for anyone; the dark theme + green accent color is seeded into the *default* user profile, so it only takes effect on that account's very first interactive sign-in — if you signed in once already before the extension finished, sign out and back in.
- **Deployment hangs on the DSC extension:** the AVD agent registration token (4-hour expiration) may have lapsed if the deployment stalled elsewhere first — redeploy. **Also check outbound connectivity first (Risk R-6):** this template creates a fresh VNet on every deploy, and Azure retired implicit "default outbound access" for new VNets after 2026-03-31 — if the NAT Gateway (added 2026-08-20) failed to provision or isn't yet live in the resource group, the session host may have no outbound internet at all, which looks identical to a stalled DSC extension. Confirm the NAT Gateway resource shows "Succeeded" before assuming it's a token-expiration issue.
- **In-session Windows credential prompt shows "Sign in Failed" after AVD web client connects fine:** this is expected without RDP single sign-on configured — Entra-joined VMs don't get automatic SSO, they always show a standard in-session credential prompt unless SSO is explicitly set up (5 separate tasks per Microsoft's docs, not something this template does by itself). The template now sets the host pool RDP property `enablerdsaadauth:i:1` (added 2026-08-20) so SSO will work *once the tenant side is also configured*, but that alone doesn't finish the job. If you just need to get logged in: re-enter `builder`'s actual Entra UPN + current password at that prompt (don't use any VM local-admin-style username there). If it still fails with the right credentials, check `builder` for **per-user MFA** specifically (Entra ID → Users → Authentication methods) — it's explicitly unsupported on Entra-joined session hosts and will reliably fail/loop. To make the prompt go away entirely (true SSO), still needed at the tenant level, one-time: enable Entra auth for RDP (Entra ID → Devices → Remote connection configuration → **Windows Cloud Login** → toggle on), optionally hide the per-host consent dialog via a dynamic device group, and review Conditional Access/Security Defaults for anything blocking the new Windows Cloud Login app. No Kerberos server object needed — there's no on-prem AD DS in this environment. Source: [Configure single sign-on for Azure Virtual Desktop using Microsoft Entra ID](https://learn.microsoft.com/azure/virtual-desktop/configure-single-sign-on).

## Cleanup (stop the meter)

Step 8 on the page now handles this (it reveals itself once the tracker shows delivered): type in the resource group name you used, click **Copy Command & Open Cloud Shell** once, and it both copies `az group delete --name <name> --yes --no-wait` to your clipboard and opens [Azure Cloud Shell](https://shell.azure.com) in a new tab (no local CLI needed) — just paste and hit enter. There's also a direct link to the Portal's Resource Groups view if you'd rather delete it by clicking through.

This isn't a single automatic click like Deploy, on purpose: unlike GitHub's API, Azure's sign-in and management endpoints don't support direct browser-to-API calls (no CORS), so a page can't silently authenticate and delete on your behalf without a real backend. This is the fastest reliable alternative that's still just a couple of clicks.

Do this right after the demo — this deploys billable compute (VM) plus minor networking costs into a subscription you personally expense.

## VM sizing note

The template's VM sizes run on **Dasv5** (`Standard_D2as_v5` / `D4as_v5` / `D8as_v5` for Personal Pan / Family Size / Large Party), not Dsv5. This wasn't a cost-optimization choice made ahead of time — Dsv5 quota in this subscription was never granted (stayed at 0 in `northcentralus`), while a self-service request for Dasv5 quota (10 vCPUs) was approved, so the template was switched to match what's actually available. It also happens to be cheaper at the 2-vCPU tier: Dasv5 runs $0.086/hr vs. Dsv5's $0.096/hr. For reference, Dsv7 ($0.132/hr) is Intel's newest chip and notably **not** a budget option despite the higher version number, and Dasv7 ($0.091/hr) is close to Dasv5 but not cheaper — Dasv5 is the actual cheapest of the four at this size.

## Known limitation

This was built and validated against Microsoft's documented ARM schema and official AVD deployment patterns (host pool/app group/workspace resource shapes, the `AADLoginForWindows` + AVD-agent DSC extension pattern used by Microsoft's own RDS-Templates repo, and the built-in role GUIDs), but it has **not yet been deployed end-to-end** — the Cowork sandbox this was built in can't reach Azure's management endpoints (network policy), so the actual `az login`/deployment has to happen from your own browser or a machine with normal internet access. Please do the dry run in step 6 above before you're in front of Darrell.

**Update 2026-08-20:** the template was substantially reworked the same day (Personal host pool instead of Pooled, single-session Windows 11 Enterprise image instead of multi-session, a NAT Gateway added for outbound internet, the session-capacity parameter removed) following a design review and adversarial grill — the full decision record lives in this project's own internal RAID log, kept outside this public repo. **None of these changes have been deployed even once yet either** — the next dry run is testing genuinely new ground, not just re-confirming the old design. Do the full dry run (step 6) and the iPad pass (step 6a) before relying on this for a live audience.
