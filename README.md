# 🍕 Fresh Desktop

A one-click Azure Virtual Desktop demo. Click a button, get a real, logged-into AVD desktop in under 30 minutes — no domain controller, no manual RBAC, no copy-pasting IDs. Pizza-themed, because infrastructure demos don't have to be boring.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnickprignano%2Ffresh-desktop-demo%2F33cffcabf2e2b887ab80d09d1a58c0d75d9142b5%2Fazuredeploy.json)

> Deploy button and the template's own extension-script fetches are pinned to a specific commit SHA, not `main` — per data-governance review finding F2 (High) / RAID R-3 mitigation, 2026-08-24. A push to `main` no longer silently changes what gets deployed; re-pinning to a new SHA is a deliberate, reviewed step.

## What this deploys

- One AVD host pool (**Personal**, `startVMOnConnect` on)
- One desktop application group + one workspace
- One Windows 11 Enterprise (**single-session**) VM, Microsoft Entra ID–joined only
- Outbound internet via a NAT Gateway ("Pickup" — the only working networking option for now; "Delivery"/Azure Firewall Basic is shown as a greyed-out Coming Soon option) — no public IP on the VM, not open to inbound internet traffic
- Automatic RBAC: whoever deploys it is granted `Desktop Virtualization User` and `Virtual Machine User Login` automatically, via the ARM `deployer()` function — no manual object-ID lookups (a separate one-time subscription-level grant is still needed for Start VM on Connect; see the runbook)
- Pizza-themed deployment parameters (VM size, image, session settings) rendered as real dropdowns in the Azure Portal's own deployment form — one image choice ("Sausage") also triggers a post-install of Microsoft 365 Apps, done as a real background install, not baked into the image
- A branded desktop wallpaper, generated and applied on first boot by a self-contained PowerShell extension — no external file hosting required

This is a demo/proof-of-concept template, not hardened for production use.

## Quick start

**Option 1 — one click:** hit the **Deploy to Azure** button above. It opens the Azure Portal pre-loaded with this template; fill in a resource group, region, and admin credentials, then Review + Create.

**Option 2 — the full demo experience:** open [`deploy-avd-demo.html`](./deploy-avd-demo.html) in a browser. It wraps the same deployment in a themed landing page with a live Azure cost calculator, an order tracker, and a presentation clock — steps reveal themselves as they become relevant, meant for showing this off live on stage.

Full walkthrough, pre-flight checklist, and troubleshooting notes are in [`AVD-DEMO-RUNBOOK.md`](./AVD-DEMO-RUNBOOK.md).

**Running this yourself and want it to clean up after itself?** Every deploy tags its resource group with a self-destruct deadline (pick 1–12 hours in step 5 of the page), but nothing deletes it automatically unless you set that up too — see the runbook's step 3d for a one-time, CLI-only watcher you can add to your own subscription in a few minutes.

## Repo contents

| File | Purpose |
|---|---|
| `azuredeploy.json` | The ARM template — the actual deployable artifact |
| `deploy-avd-demo.html` | Themed landing page that triggers the deployment |
| `fresh-desktop-branding.ps1` | Wallpaper-branding script, fetched by the template at deploy time via raw GitHub URL |
| `office-apps-install.ps1` | Microsoft 365 Apps post-install script (Sausage topping only), same fetch mechanism |
| `self-destruct-runbook.ps1` | Optional Azure Automation runbook — deletes resource groups past their tagged self-destruct deadline. Set up once via CLI (runbook step 3d), not required to run the demo |
| `AVD-DEMO-RUNBOOK.md` | Full setup, demo, and troubleshooting runbook |

## License

MIT — see [LICENSE](./LICENSE).
