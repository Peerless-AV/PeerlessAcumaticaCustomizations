<#
.SYNOPSIS
  Cleanly stops an Acumatica instance: IIS app pool(s) first, then SQL Agent, then SQL Server.

.DESCRIPTION
  Order matters: the app is stopped before the database so no in-flight Acumatica requests
  or scheduler jobs lose their connection mid-transaction.

  -KeepSql           Stop only the app (use this for Acumatica version upgrades / customization
                     work where the Configuration Wizard still needs the database online).
  -DisableAutoStart  Also set the pool(s) to not auto-start and SQL services to Manual, so a
                     reboot doesn't bring everything back. Start-Acumatica.ps1 -EnableAutoStart undoes it.
  -Force             If a worker process hasn't exited after the timeout, kill it.

  Run elevated. Idempotent: already-stopped items are skipped.

.EXAMPLE
  .\Stop-Acumatica.ps1 -AppPool 2026R1DEV
  .\Stop-Acumatica.ps1 -AppPool 2026R1DEV -KeepSql
  .\Stop-Acumatica.ps1 -AppPool AcuTEST,AcuSTAGE -SqlInstance SQL2022 -DisableAutoStart

.EXAMPLE  (remote)
  Invoke-Command -ComputerName ACUVM01 -FilePath .\Stop-Acumatica.ps1 -ArgumentList @('AcuTEST')
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string[]] $AppPool,
    [string] $SqlInstance = 'MSSQLSERVER',     # default instance; use the instance name for named instances
    [switch] $KeepSql,
    [switch] $DisableAutoStart,
    [switch] $Force,
    [int]    $TimeoutSec = 120
)

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
Import-Module WebAdministration

function Log([string]$m) { Write-Host ('{0:HH:mm:ss}  {1}' -f (Get-Date), $m) }

function Get-SqlServiceNames([string]$inst) {
    if ($inst -eq 'MSSQLSERVER') { [pscustomobject]@{ Engine = 'MSSQLSERVER'; Agent = 'SQLSERVERAGENT' } }
    else                         { [pscustomobject]@{ Engine = "MSSQL`$$inst"; Agent = "SQLAgent`$$inst" } }
}

$failed = $false

# ---- 1. IIS app pools -------------------------------------------------------
foreach ($p in $AppPool) {
    $item = "IIS:\AppPools\$p"
    if (-not (Test-Path $item)) { Log "App pool '$p' not found - skipping"; $failed = $true; continue }

    if ($DisableAutoStart) {
        Set-ItemProperty $item -Name autoStart -Value $false
        Set-ItemProperty $item -Name startMode -Value 'OnDemand'
        Log "Pool '$p': autoStart off, startMode OnDemand"
    }

    if ((Get-WebAppPoolState -Name $p).Value -ne 'Stopped') {
        Log "Stopping app pool '$p'..."
        Stop-WebAppPool -Name $p
    } else { Log "Pool '$p' already stopped" }

    # Wait for the worker process(es) to actually exit - this is when memory is released
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    do {
        $wps = @(Get-ChildItem "$item\WorkerProcesses" -ErrorAction SilentlyContinue)
        if ($wps.Count -eq 0) { break }
        Start-Sleep 2
    } while ((Get-Date) -lt $deadline)

    if ($wps.Count -gt 0) {
        if ($Force) {
            foreach ($wp in $wps) { Stop-Process -Id $wp.processId -Force; Log "Killed w3wp PID $($wp.processId)" }
        } else {
            Log "WARNING: worker process for '$p' still running after $TimeoutSec s (use -Force to kill)"
            $failed = $true
        }
    } else { Log "Pool '$p' stopped, worker process exited" }
}

# ---- 2. SQL Server ----------------------------------------------------------
if ($KeepSql) {
    Log "-KeepSql: leaving SQL Server running"
} else {
    $svc = Get-SqlServiceNames $SqlInstance
    foreach ($name in @($svc.Agent, $svc.Engine)) {        # Agent before engine
        $s = Get-Service -Name $name -ErrorAction SilentlyContinue
        if (-not $s) { Log "Service '$name' not present - skipping"; continue }

        if ($DisableAutoStart -and $s.StartType -ne 'Disabled') {
            Set-Service -Name $name -StartupType Manual
            Log "Service '$name' startup set to Manual"
        }
        if ($s.Status -ne 'Stopped') {
            Log "Stopping '$name'..."
            Stop-Service -Name $name -Force
            $s.WaitForStatus('Stopped', [TimeSpan]::FromSeconds($TimeoutSec))
            Log "'$name' stopped"
        } else { Log "'$name' already stopped" }
    }
}

Log ("Done{0}" -f $(if ($failed) { ' with warnings' } else { '' }))
exit [int]$failed
