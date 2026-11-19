<#
.SYNOPSIS
  Starts an Acumatica instance in the right order: SQL Server, wait until it accepts
  connections, SQL Agent, IIS, app pool(s), then optionally runs the warm-up script.

.DESCRIPTION
  -EnableAutoStart  Restore always-on behaviour (pool autoStart + AlwaysRunning, SQL services
                    Automatic). Undoes Stop-Acumatica.ps1 -DisableAutoStart.
  -Warmup           After start, run Invoke-AcumaticaWarmup.ps1 (same folder by default).

  Run elevated. Idempotent: already-running items are skipped.

.EXAMPLE
  .\Start-Acumatica.ps1 -AppPool 2026R1DEV -Warmup
  .\Start-Acumatica.ps1 -AppPool AcuTEST,AcuSTAGE -SqlInstance SQL2022 -EnableAutoStart -Warmup

.EXAMPLE  (remote)
  Invoke-Command -ComputerName ACUVM01 -FilePath .\Start-Acumatica.ps1 -ArgumentList @('AcuTEST')
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string[]] $AppPool,
    [string] $SqlInstance = 'MSSQLSERVER',
    [switch] $EnableAutoStart,
    [switch] $Warmup,
    [string] $WarmupScript = (Join-Path $PSScriptRoot 'Invoke-AcumaticaWarmup.ps1'),
    [string] $WarmupConfig = (Join-Path $PSScriptRoot 'warmup.config.json'),
    [int]    $TimeoutSec   = 180
)

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
Import-Module WebAdministration

function Log([string]$m) { Write-Host ('{0:HH:mm:ss}  {1}' -f (Get-Date), $m) }

function Get-SqlServiceNames([string]$inst) {
    if ($inst -eq 'MSSQLSERVER') { [pscustomobject]@{ Engine = 'MSSQLSERVER'; Agent = 'SQLSERVERAGENT'; Server = '.' } }
    else                         { [pscustomobject]@{ Engine = "MSSQL`$$inst"; Agent = "SQLAgent`$$inst"; Server = ".\$inst" } }
}

function Wait-SqlReady([string]$server, [int]$timeout) {
    # Service "Running" != ready: recovery may still be in progress. Probe with a real query.
    if (-not ('System.Data.SqlClient.SqlConnection' -as [type])) {
        Log "SqlClient unavailable in this host - falling back to a 15s settle delay"
        Start-Sleep 15; return $true
    }
    $deadline = (Get-Date).AddSeconds($timeout)
    while ((Get-Date) -lt $deadline) {
        try {
            $cn = New-Object System.Data.SqlClient.SqlConnection "Server=$server;Integrated Security=SSPI;Connect Timeout=5"
            $cn.Open()
            $cmd = $cn.CreateCommand()
            $cmd.CommandText = "SELECT COUNT(*) FROM sys.databases WHERE state_desc <> 'ONLINE'"
            $notOnline = [int]$cmd.ExecuteScalar()
            $cn.Close()
            if ($notOnline -eq 0) { return $true }
            Log "SQL up, $notOnline database(s) still recovering..."
        }
        catch { }   # not accepting connections yet - retry
        Start-Sleep 3
    }
    return $false
}

# ---- 1. SQL Server ----------------------------------------------------------
$svc = Get-SqlServiceNames $SqlInstance
foreach ($name in @($svc.Engine, $svc.Agent)) {
    $s = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $s) { Log "Service '$name' not present - skipping"; continue }

    if ($EnableAutoStart -and $s.StartType -ne 'Disabled') {
        Set-Service -Name $name -StartupType Automatic
        Log "Service '$name' startup set to Automatic"
    }
    if ($s.StartType -eq 'Disabled') { Log "Service '$name' is Disabled - skipping"; continue }

    if ($s.Status -ne 'Running') {
        Log "Starting '$name'..."
        Start-Service -Name $name
        $s.WaitForStatus('Running', [TimeSpan]::FromSeconds($TimeoutSec))
        Log "'$name' running"
    } else { Log "'$name' already running" }

    if ($name -eq $svc.Engine) {
        if (Wait-SqlReady $svc.Server $TimeoutSec) { Log "SQL Server accepting connections, all databases online" }
        else { throw "SQL Server did not become ready within $TimeoutSec s" }
    }
}

# ---- 2. IIS -----------------------------------------------------------------
foreach ($name in 'WAS', 'W3SVC') {
    if ((Get-Service $name).Status -ne 'Running') { Start-Service $name; Log "Started $name" }
}

foreach ($p in $AppPool) {
    $item = "IIS:\AppPools\$p"
    if (-not (Test-Path $item)) { throw "App pool '$p' not found" }

    if ($EnableAutoStart) {
        Set-ItemProperty $item -Name autoStart -Value $true
        Set-ItemProperty $item -Name startMode -Value 'AlwaysRunning'
        Log "Pool '$p': autoStart on, startMode AlwaysRunning"
    }
    if ((Get-WebAppPoolState -Name $p).Value -ne 'Started') {
        Start-WebAppPool -Name $p
        Log "Started app pool '$p'"
    } else { Log "Pool '$p' already started" }
}

# ---- 3. Warm-up -------------------------------------------------------------
if ($Warmup) {
    if (-not (Test-Path $WarmupScript)) { throw "Warm-up script not found: $WarmupScript" }
    Log "Running warm-up..."
    & $WarmupScript -ConfigPath $WarmupConfig
    if ($LASTEXITCODE -ne 0) { Log "Warm-up reported failures (see warmup log)"; exit 1 }
}

Log "Done"
exit 0
