# 🍕 Fresh Desktop

A one-click Azure Virtual Desktop demo. Click a button, get a real, logged-into AVD desktop in under 30 minutes — no domain controller, no manual RBAC, no copy-pasting IDs. Pizza-themed, because infrastructure demos don't have to be boring.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnickprignano%2Ffresh-desktop-demo%2Fmain%2Fazuredeploy.json)

## What this deploys

- One AVD host pool (pooled, breadth-first, `startVMOnConnect` on)
- One desktop application group + one workspace
- One Windows 11 (multi-session AVD image) VM, Microsoft Entra ID–joined only
- Automatic RBAC: whoever deploys it is granted `Desktop Virtualization User` and `Virtual Machine User Login` automatically, via the ARM `deployer()` function — no manual object-ID lookups
- Pizza-themed deployment parameters (VM size, image, session settings) rendered as real dropdowns in the Azure Portal's own deployment form
- A branded desktop wallpaper, generated and applied on first boot by a self-contained PowerShell extension — no external file hosting required

This is a demo/proof-of-concept template, not hardened for production use.

## Quick start

**Option 1 — one click:** hit the **Deploy to Azure** button above. It opens the Azure Portal pre-loaded with this template; fill in a resource group, region, and admin credentials, then Review + Create.

**Option 2 — the full demo experience:** open [`deploy-avd-demo.html`](./deploy-avd-demo.html) in a browser. It wraps the same deployment in a themed landing page with a live delivery tracker and a 30-minute presentation countdown, meant for showing this off live on stage.

Full walkthrough, pre-flight checklist, and troubleshooting notes are in [`AVD-DEMO-RUNBOOK.md`](./AVD-DEMO-RUNBOOK.md).

## Repo contents

| File | Purpose |
|---|---|
| `azuredeploy.json` | The ARM template — the actual deployable artifact |
| `deploy-avd-demo.html` | Themed landing page that triggers the deployment |
| `fresh-desktop-branding.ps1` | Source of the wallpaper-branding script (gzip+base64-embedded in the template itself — kept here for editing) |
| `AVD-DEMO-RUNBOOK.md` | Full setup, demo, and troubleshooting runbook |

## License

MIT — see [LICENSE](./LICENSE).
