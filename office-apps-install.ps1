<#
  Fresh Desktop — Office Apps post-install (Sausage topping only)

  Installs Microsoft 365 Apps for enterprise via the Office Deployment Tool (ODT),
  Monthly Enterprise Channel, 64-bit, with Shared Computer Activation enabled (the
  documented Microsoft best practice for any AVD host pool, personal or pooled).

  Runs as its own CustomScriptExtension in PARALLEL with AADLoginForWindows/AVDAgentDSC
  (see azuredeploy.json's dependsOn — it only depends on the VM itself, not the other
  extensions), so it starts immediately at VM boot rather than waiting on a user to sign
  in. On a Family Size or Large Party VM (more vCPU/bandwidth), this realistically
  finishes before the Entra join + AVD agent registration chain does, so Office is
  usually already installed by the time anyone can actually log in. On the smaller
  Personal Pan size, it may still be finishing — that's expected, not a bug.

  Activation depends on the signed-in user's account carrying a Microsoft 365 Apps
  entitlement (e.g., M365 E3/E5) once they sign in — a standalone Entra ID P1/P2 license
  does NOT include this, so whichever license Dependency DEP-1 resolves to needs to be
  confirmed to include Microsoft 365 Apps, or this installs but activates in reduced-
  functionality mode.

  Logs to C:\OfficeAppsInstall.log.

  Disclosed caveat, same pattern as this project's other external references (see RAID
  Risk R-3 / the marketplace-terms pre-flight check): the Office Deployment Tool's
  download link is version-pinned by Microsoft and changes periodically, so this script
  resolves the current link dynamically from Microsoft's own download-confirmation page
  rather than hardcoding a version-specific URL that would silently go stale. If Microsoft
  ever changes that page's structure, this resolution step is the first thing to check.
#>

$ErrorActionPreference = 'Stop'
$logPath = 'C:\OfficeAppsInstall.log'

function Write-Log {
    param([string]$Message)
    "$(Get-Date -Format o)  $Message" | Out-File -FilePath $logPath -Append -Encoding utf8
}

try {
    Write-Log 'Starting Office Apps install (Sausage topping).'

    $workDir = 'C:\FreshDesktopOfficeInstall'
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    Set-Location -Path $workDir

    # Resolve the current Office Deployment Tool download link dynamically rather than
    # hardcoding a version-specific URL (Microsoft rotates these with each ODT release).
    Write-Log 'Resolving current Office Deployment Tool download URL from Microsoft Download Center.'
    $confirmationUrl = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117'
    $confirmationPage = Invoke-WebRequest -Uri $confirmationUrl -UseBasicParsing
    $odtUrl = ($confirmationPage.Links | Where-Object { $_.href -match 'officedeploymenttool.*\.exe$' } | Select-Object -First 1).href
    if (-not $odtUrl) {
        throw 'Could not resolve the Office Deployment Tool download URL — Microsoft may have changed the download-confirmation page structure.'
    }
    Write-Log "Resolved ODT URL: $odtUrl"

    $odtExe = Join-Path $workDir 'odtsetup.exe'
    Invoke-WebRequest -Uri $odtUrl -OutFile $odtExe -UseBasicParsing
    Write-Log 'Downloaded ODT installer.'

    Start-Process -FilePath $odtExe -ArgumentList "/quiet /extract:`"$workDir`"" -Wait -NoNewWindow
    Write-Log 'Extracted ODT (setup.exe + configuration.xml).'

    # Monthly Enterprise Channel, 64-bit, silent, Shared Computer Activation on (AVD best
    # practice per Microsoft Learn: "Deploy Microsoft 365 Apps by using Remote Desktop
    # Services" / "Overview of shared computer activation").
    $configXml = @'
<Configuration>
  <Add OfficeClientEdition="64" Channel="MonthlyEnterprise">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Property Name="SharedComputerLicensing" Value="1" />
  <Display Level="None" AcceptEULA="TRUE" />
  <Updates Enabled="TRUE" Channel="MonthlyEnterprise" />
</Configuration>
'@
    $configPath = Join-Path $workDir 'configuration.xml'
    $configXml | Out-File -FilePath $configPath -Encoding utf8
    Write-Log 'Wrote configuration.xml (Microsoft 365 Apps for enterprise, Monthly Enterprise Channel, Shared Computer Activation).'

    $setupExe = Join-Path $workDir 'setup.exe'
    Write-Log 'Starting setup.exe /configure — this is the multi-minute download+install step.'
    Start-Process -FilePath $setupExe -ArgumentList "/configure `"$configPath`"" -Wait -NoNewWindow

    Write-Log 'Office Apps install complete.'
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
