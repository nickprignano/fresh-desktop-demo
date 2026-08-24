<#
.SYNOPSIS
  Fresh Desktop AVD Demo — self-destruct watcher (optional, self-contained).

.DESCRIPTION
  Scans the subscription this Automation Account lives in for resource groups tagged
  Project=fresh-desktop-avd-demo whose SelfDestructAtUtc tag has passed, and deletes them.

  This is NOT AHEAD's shared lab-manager governance — it's a small, optional, self-contained
  fallback anyone can set up in their own subscription (community/forked deployments have no
  access to lab-manager), and is also being used as AHEAD's own interim safety net until
  lab-manager's tag-based-discovery gap is resolved. The full internal reasoning for this design
  (why a plain script over a packaged ARM/Bicep template) lives in this project's own internal
  RAID/decision log, kept outside this public repo — see AVD-DEMO-RUNBOOK.md (step 3d) for the
  `az` CLI setup steps you actually need to use this.

  Intended to run on a recurring Azure Automation schedule (hourly is plenty — the shortest
  self-destruct window is 1 hour, see azuredeploy.json's selfDestructHours parameter).

.NOTES
  Authenticates via the Automation Account's system-assigned managed identity — no stored
  credentials, no deprecated "Run As" account. The identity needs Contributor at subscription
  scope (one-time grant, documented in AVD-DEMO-RUNBOOK.md) since the resource group name/prefix
  varies per deploy and isn't known ahead of time.
#>

Connect-AzAccount -Identity | Out-Null

$taggedGroups = Get-AzResourceGroup | Where-Object {
    $_.Tags -and $_.Tags['Project'] -eq 'fresh-desktop-avd-demo' -and $_.Tags['SelfDestructAtUtc']
}

if (-not $taggedGroups) {
    Write-Output "No fresh-desktop-avd-demo resource groups found in this subscription. Nothing to do."
    return
}

$nowUtc = [DateTime]::UtcNow
Write-Output "Sweep started at $nowUtc UTC. Found $($taggedGroups.Count) tagged resource group(s)."

foreach ($rg in $taggedGroups) {
    $orderNumber = $rg.Tags['OrderNumber']
    $deadlineRaw = $rg.Tags['SelfDestructAtUtc']

    $deadline = $null
    $parsed = [DateTime]::TryParse(
        $deadlineRaw,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::AdjustToUniversal -bor [System.Globalization.DateTimeStyles]::AssumeUniversal,
        [ref]$deadline
    )

    if (-not $parsed) {
        Write-Warning "Resource group '$($rg.ResourceGroupName)' (Order $orderNumber) has an unparseable SelfDestructAtUtc tag ('$deadlineRaw') — skipping. Not deleting on a malformed deadline."
        continue
    }

    if ($nowUtc -ge $deadline) {
        Write-Output "DELETING '$($rg.ResourceGroupName)' (Order $orderNumber) — deadline $deadline UTC has passed (now $nowUtc UTC)."
        Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force -AsJob | Out-Null
    } else {
        Write-Output "'$($rg.ResourceGroupName)' (Order $orderNumber) not yet due — deadline $deadline UTC, now $nowUtc UTC."
    }
}
