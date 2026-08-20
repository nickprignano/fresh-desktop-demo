# AVD One-Click Demo — Runbook

Goal: click a button on a web page, get a real, logged-into Azure Virtual Desktop desktop, in under 30 minutes, in your AVD/Nerdio demo subscription.

## What this deploys

- One AVD host pool (pooled, breadth-first, `startVMOnConnect` on)
- One desktop application group + one workspace
- One Windows 11 (multi-session AVD image) VM, **Microsoft Entra ID–joined only** — no domain controller, no AD DS, no hybrid join
- RBAC: whoever runs the deployment is automatically granted `Desktop Virtualization User` on the app group and `Virtual Machine User Login` on the VM (via the ARM `deployer()` function) — no manual object-ID lookups needed
- **Pizza-themed flavor pickers**, rendered natively by the Azure Portal's own deployment form (real ARM parameters with fun `allowedValues`, not a custom UI): Pizza Size (VM size: Personal Pan / Family Size / Large Party), Crust (Windows 11 image: 24H2 plain / 23H2 plain / 24H2 + Microsoft 365 Apps), and three Toppings (session capacity, clipboard/drive redirection, and OS disk tier — Sauce: Standard HDD / Standard SSD / Premium SSD). All default-selected so Review + Create needs zero clicks, but they're visible, real dropdowns you can change live on stage. Every combination still lands inside the same ~18-minute deploy window — none of these add real time, they just change $/hr and in-session performance.
- **Pizza delivery tracker** on the landing page: a 5-stage animated progress bar (Order Placed → Prepping Your Pie → In the Oven → Out for Delivery → Delivered) timed to the real ~18-minute deployment. Click any stage icon anytime to jump the tracker if the live deployment runs ahead or behind — built fresh for this, not reused from any other project.

- **Desktop branding**: a third VM extension (`FreshDesktopBranding`, a self-contained `CustomScriptExtension` — no external hosting, the whole PowerShell script is gzip+base64-embedded directly in the template) generates an Italian-tricolor "Fresh Desktop" wallpaper — the name in the same casing as the page's own brand treatment, paired with a drawn pizza-slice icon rather than text alone — on the VM itself, and applies it machine-wide via the Windows Personalization policy, plus seeds the default user profile with a dark theme and a green accent color so a brand-new Entra profile picks it up on first sign-in. Runs in parallel with the other extensions, so it doesn't add to the ~18-minute critical path.
- **Presentation clock**: a fixed badge in the top-right corner of the page, visible on every step. It auto-starts the instant step 2's Deploy to Azure button is clicked (no extra click, no manual Start needed), and won't restart if you click Deploy twice. Color shifts green → amber at 15:00 remaining → pulsing red at 5:00. If it hits 0:00 before you're done, it doesn't stop — it flips to a red "Overtime" display and counts up, so you never lose your on-screen clock mid-demo. Only manual controls are a single **Pause/Resume** toggle and **Reset**; it also auto-pauses the moment you click through to the AVD web client in step 4, since the clock stops mattering once you're live in the desktop.
- **Live cost calculator** (step 2): pick the same Pizza Size you're about to choose in the portal and see real pricing — hourly rate, a ~20-minute demo estimate, and monthly-if-left-running — pulled live from the Azure Retail Prices API for `northcentralus`. Falls back to a small hardcoded rate table if that call is ever blocked, and says so on the page. Priced at the default Sauce (Standard SSD) disk tier — it does not shift live if you pick Light or Extra Sauce in the portal instead.
- **Steps reveal progressively**: Track / Log In / Cleanup are hidden until they're actually relevant — clicking Deploy reveals and auto-starts the tracker, and the tracker hitting Delivered reveals Log In and Cleanup together — so the page never shows you a step you can't act on yet. The VM admin password generator now comes first (step 1), before Deploy (step 2), since the portal's Basics tab needs it.
- **Black/neutral color palette** — background and UI chrome are solid black and neutral gray, with only the Italian tricolor (green/red/white) and status green/red as accent colors. Deliberately has no blue anywhere and no corporate branding of any kind, so it reads as its own independent thing on stage rather than a company slide deck.

Files: `azuredeploy.json` (the template), `deploy-avd-demo.html` (the trigger page + tracker + countdown), `fresh-desktop-branding.ps1` (source of the branding script, embedded in the template — kept here for reference/editing only, not deployed separately), `LICENSE` (MIT — this is a public repo).

## Before tomorrow — do this today, not live

1. **Set up and unlock the `builder` deployment identity — do this first, it has its own gotcha.** Use a dedicated Entra ID account named `builder` for all deployment and demo work:
   - **Not** the original outlook.com / tenant-creator account — it's an MSA-bridge identity with its own MFA/sign-in quirks that don't behave like a normal Entra account.
   - **Not** the break-glass account — leave that untouched, emergency-only.

   `builder` needs two separate grants — having one does **not** imply the other:
   - **Global Administrator** (Entra ID role)
   - **Owner** (Azure RBAC, scoped to the subscription)

   **Gotcha:** a brand-new Entra ID user is forced through MFA registration and a password change on first use, and that has to happen via an interactive browser sign-in — go to `https://myaccount.microsoft.com`, sign in as `builder`, and complete both prompts. Do this *before* trying `az login` or signing into the portal as `builder`; a fresh account that's never been through interactive sign-in will fail or hang on `az login`.

2. **Confirm Dasv5 quota in `northcentralus` — required pre-flight, not just a troubleshooting note.** This subscription's "Standard DSv5 Family vCPUs" quota started at **0** in `northcentralus` (and `centralus`) and was never granted, so the template's VM sizes were switched from Dsv5 to **Dasv5** (`Standard_D2as_v5` / `D4as_v5` / `D8as_v5`) — a self-service quota increase to 10 "Standard DASv5 Family vCPUs" in `northcentralus` was requested and approved instead. Confirm that quota is still in place:
   - Azure Portal → **Quotas** → **Compute** → filter to **DASv5**, region `northcentralus`
   - Should show at least enough vCPUs for the demo VM (2 for Personal Pan; more if you plan to demo a larger Pizza Size live)
   - If you ever need more, self-service increases are usually fast but not instant — don't leave it for the morning of.

3. **Confirm resource providers are registered** in your demo subscription (first-time registration can eat several minutes of your 30):
   ```
   az provider register --namespace Microsoft.DesktopVirtualization
   az provider register --namespace Microsoft.Compute
   az provider register --namespace Microsoft.Network
   az provider show -n Microsoft.DesktopVirtualization --query registrationState -o tsv
   ```
   Wait until each shows `Registered`.

4. **Template hosting is already handled — nothing to set up.** `azuredeploy.json` is hosted permanently at the public repo [`nickprignano/fresh-desktop-demo`](https://github.com/nickprignano/fresh-desktop-demo) and fetched directly by the Azure Portal at deploy time via its raw URL (default branch confirmed as `main` at build time — if you ever repoint or recreate the repo, re-verify the default branch before trusting the raw URL). The only time you touch GitHub again is if you edit `azuredeploy.json` locally and need to push that change to the repo before your next dry run or the live demo — the portal always fetches whatever's currently live there, not your local copy.

5. **Open `deploy-avd-demo.html`** in your browser, signed in as `builder`. Everything from here is button clicks: generate a VM admin password in step 1, then step 2's **🚀 Deploy to Azure** button opens the Azure Portal deployment page directly against the hosted template, in a new tab, and starts the presentation clock and order tracker automatically.

6. **Do one full dry run today**, not the morning of. Confirm the presentation clock (top-right) auto-starts when you click Deploy with no manual Start needed, that its color transitions (green → amber at 15:00 → pulsing red at 5:00) feel right against how long the real deployment actually takes, and — if you have a spare minute — let it run past 0:00 once to see it flip to red "Overtime" and count up, so it doesn't surprise you live. Click Deploy, fill in:
   - Subscription: your AVD/Nerdio demo sub, signed in as `builder`
   - Region: **`northcentralus`** (Chicago — physically closest to where the demo is happening, and where you hold the Dasv5 quota confirmed in step 2 above)
   - Admin username/password for the VM (this is a *local* fallback account on the VM itself, unrelated to the `builder` Entra identity — you'll sign in to AVD with `builder`, not this one)
   - Leave `namePrefix` as `avddemo` or shorten if you want a distinct run
   - Review + create

7. **Time it.** Expect roughly:
   - ~2–3 min: networking + host pool/workspace/app group
   - ~3–5 min: VM provisioning
   - ~5–8 min: Microsoft Entra join (AADLoginForWindows extension)
   - ~5–8 min: AVD agent registration (DSC extension)
   - Total: ~15–20 minutes is typical; budget the full 30 to be safe.

8. **Log in.** Once the portal says "Your deployment is complete," go to `https://client.wvd.microsoft.com/arm/webclient/`, sign in as `builder`, and your desktop should appear and connect. First sign-in to a fresh Entra-joined VM can take an extra minute while the profile is created.

## During the Darrell demo

- Have `deploy-avd-demo.html` already open, signed in as `builder`. There's no repeat setup step on your laptop anymore — the `builder` account's MFA/password unlock and the `northcentralus` Dasv5 quota (pre-flight steps 1–2 above) are one-time per account/subscription and should already be done by show time.
- Optionally point out the **live cost calculator** in step 2 first — click through the three Pizza Sizes to show real Azure pricing per hour before you ever hit Deploy.
- Click **🚀 Deploy to Azure** on stage; the page opens the Azure Portal directly against the hosted template, and both the presentation clock (top-right) and the order tracker start automatically — no separate click for either. The tracker card reveals itself and scrolls into view right away, so there's nothing to remember to switch on. When the portal's Basics tab loads, point out the Pizza Size / Crust / Toppings dropdowns — defaults are already picked, or change one live for fun before hitting Review + Create.
- Narrate each stage as it lights up on the tracker. It's a choreographed timer synced to typical deploy timing, not a live Azure feed — if the real deployment visibly finishes a stage early or late, just click the matching stage icon to resync. You're always in control on stage; nothing here can desync embarrassingly if you drive it.
- Once the tracker hits **Fresh Out of the Oven**, the Log In and Cleanup cards reveal themselves automatically — you don't need to scroll to steps that weren't ready yet. Clicking **Open AVD Web Client** auto-pauses the presentation clock, since it stops mattering once you're live in the desktop.
- If you're worried about live provisioning time, consider deploying ~20 minutes before you're on, then just doing the login + narration live, and mentioning the deploy step is one click. Use the **8x rehearse** speed toggle beforehand to practice the narration without waiting 18 minutes each time. If you reset and re-rehearse, hit **both** the tracker's Reset (which also re-hides Log In/Cleanup) and the presentation clock's Reset, so nothing shows stale state when you go live.

## Troubleshooting

- **Deploy button opens the portal but the template looks stale or fails to load:** the page always points at the fixed repo's raw URL (`https://raw.githubusercontent.com/nickprignano/fresh-desktop-demo/main/azuredeploy.json`). If you've edited `azuredeploy.json` locally, push/commit it to that repo first — the portal fetches whatever's currently live there, not your local copy.
- **Marketplace image terms — expected no-op for this image, not an error:** if you (or a pre-flight habit) run
  ```
  az vm image terms accept --urn MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest
  ```
  Azure returns **"has no terms to accept"** for this specific SKU. That's expected — this image doesn't require the usual marketplace terms acceptance, so seeing that message during a dry run is not a failure and needs no follow-up action. If a *different* deployment error mentions marketplace/purchase eligibility, it's unrelated to this command and needs its own investigation.
- **AADLoginForWindows extension fails:** almost always a managed-identity or connectivity issue. RDP/console into the VM isn't needed — check the extension status in the portal (VM → Extensions). See [Microsoft's troubleshooting guide](https://learn.microsoft.com/entra/identity/devices/howto-vm-sign-in-azure-ad-windows#troubleshoot-deployment-problems).
- **Deployed fine but can't log in ("account configured to prevent you from using this device"):** the RBAC role assignments didn't land — check IAM on the application group and the VM for your account under `Desktop Virtualization User` / `Virtual Machine User Login`. The template assigns these automatically to whoever runs the deployment; if someone else clicks Deploy, they get the access, not you.
- **Wallpaper/theme didn't show up:** the branding script logs to `C:\FreshDesktopBranding.log` on the VM (RDP or use the portal's "Run command" to check). The wallpaper itself is applied machine-wide via policy and should show up for anyone; the dark theme + green accent color is seeded into the *default* user profile, so it only takes effect on that account's very first interactive sign-in — if you signed in once already before the extension finished, sign out and back in.
- **Deployment hangs on the DSC extension:** the AVD agent registration token (4-hour expiration) may have lapsed if the deployment stalled elsewhere first — redeploy.

## Cleanup (stop the meter)

Step 5 on the page now handles this (it reveals itself once the tracker shows delivered): type in the resource group name you used, click **Copy Command & Open Cloud Shell** once, and it both copies `az group delete --name <name> --yes --no-wait` to your clipboard and opens [Azure Cloud Shell](https://shell.azure.com) in a new tab (no local CLI needed) — just paste and hit enter. There's also a direct link to the Portal's Resource Groups view if you'd rather delete it by clicking through.

This isn't a single automatic click like Deploy, on purpose: unlike GitHub's API, Azure's sign-in and management endpoints don't support direct browser-to-API calls (no CORS), so a page can't silently authenticate and delete on your behalf without a real backend. This is the fastest reliable alternative that's still just a couple of clicks.

Do this right after the demo — this deploys billable compute (VM) plus minor networking costs into a subscription you personally expense.

## VM sizing note

The template's VM sizes run on **Dasv5** (`Standard_D2as_v5` / `D4as_v5` / `D8as_v5` for Personal Pan / Family Size / Large Party), not Dsv5. This wasn't a cost-optimization choice made ahead of time — Dsv5 quota in this subscription was never granted (stayed at 0 in `northcentralus`), while a self-service request for Dasv5 quota (10 vCPUs) was approved, so the template was switched to match what's actually available. It also happens to be cheaper at the 2-vCPU tier: Dasv5 runs $0.086/hr vs. Dsv5's $0.096/hr. For reference, Dsv7 ($0.132/hr) is Intel's newest chip and notably **not** a budget option despite the higher version number, and Dasv7 ($0.091/hr) is close to Dasv5 but not cheaper — Dasv5 is the actual cheapest of the four at this size.

## Known limitation

This was built and validated against Microsoft's documented ARM schema and official AVD deployment patterns (host pool/app group/workspace resource shapes, the `AADLoginForWindows` + AVD-agent DSC extension pattern used by Microsoft's own RDS-Templates repo, and the built-in role GUIDs), but it has **not yet been deployed end-to-end** — the Cowork sandbox this was built in can't reach Azure's management endpoints (network policy), so the actual `az login`/deployment has to happen from your own browser or a machine with normal internet access. Please do the dry run in step 6 above before you're in front of Darrell.
