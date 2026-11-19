<#
.SYNOPSIS
  One-time IIS hardening so an Acumatica instance stays loaded instead of idling out.

.DESCRIPTION
  - Installs the IIS Application Initialization feature (if missing)
  - App pool: StartMode=AlwaysRunning, IdleTimeout=0
  - Replaces the default 1740-minute rolling recycle with a fixed daily recycle time
    (so the warm-up task can be scheduled right after it)
  - Site: preloadEnabled=true

  Run elevated on each Acumatica VM. Idempotent; safe to re-run.

.EXAMPLE
  .\Set-AcumaticaIisAlwaysOn.ps1 -SiteName "Default Web Site" -AppPath "/2026R1DEV" -RecycleAt "03:00"
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string] $SiteName,          # e.g. "Default Web Site"
    [Parameter(Mandatory)] [string] $AppPath,           # e.g. "/2026R1DEV"  (virtual dir of the instance)
    [string] $RecycleAt = "03:00"                       # daily recycle time (24h)
)

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
Import-Module WebAdministration

# 1. Application Initialization feature
$feature = Get-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit -ErrorAction SilentlyContinue
if ($feature -and $feature.State -ne 'Enabled') {
    Write-Host "Enabling IIS-ApplicationInit..."
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit -NoRestart | Out-Null
}

# 2. Resolve the app pool behind this application
$appItem = "IIS:\Sites\$SiteName$AppPath"
$pool = (Get-ItemProperty $appItem -Name applicationPool)
if (-not $pool) { throw "Could not resolve app pool for $appItem" }
$poolItem = "IIS:\AppPools\$pool"
Write-Host "App pool: $pool"

# 3. App pool settings
Set-ItemProperty $poolItem -Name startMode                    -Value 'AlwaysRunning'
Set-ItemProperty $poolItem -Name processModel.idleTimeout     -Value ([TimeSpan]::Zero)
Set-ItemProperty $poolItem -Name recycling.periodicRestart.time -Value ([TimeSpan]::Zero)   # disable rolling 29h recycle
Clear-ItemProperty $poolItem -Name recycling.periodicRestart.schedule
Set-ItemProperty $poolItem -Name recycling.periodicRestart.schedule -Value @{ value = $RecycleAt }

# 4. Preload the application
Set-ItemProperty $appItem -Name preloadEnabled -Value $true

Write-Host "Done. Pool '$pool' = AlwaysRunning, idle timeout off, daily recycle at $RecycleAt, preload on."
Write-Host "Schedule Invoke-AcumaticaWarmup.ps1 a few minutes after $RecycleAt and at system startup."
