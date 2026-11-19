<#
.SYNOPSIS
  Warms one or more Acumatica instances so the first real session isn't paying compile/cache costs.

.DESCRIPTION
  For each instance in the config file:
    1. Polls the root URL until the app domain is up (handles cold start after recycle/reboot)
    2. Logs in via the REST API (one short-lived session)
    3. GETs each listed screen's .aspx page   -> forces ASP.NET page compilation + graph init
    4. GETs $top=1 on each listed REST entity -> instantiates graphs, DAC caches, BQL/SQL plans
    5. Logs out (always, in finally) so no license session is left hanging
  Writes a timestamped log line per step; exit code 1 if any instance failed.

  Works in Windows PowerShell 5.1 and PowerShell 7+.

.PARAMETER ConfigPath
  JSON config (see warmup.config.json).

.NOTES
  Credentials: one DPAPI-protected credential file per instance, created ONCE by the
  same account that will run the scheduled task:
      Get-Credential | Export-Clixml C:\AcuWarmup\cred-2026R1DEV.xml
  Use a dedicated low-privilege API user that can see the warmed screens.
#>
[CmdletBinding()]
param(
    [string] $ConfigPath = (Join-Path $PSScriptRoot 'warmup.config.json')
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$config  = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$logPath = if ($config.LogPath) { $config.LogPath } else { Join-Path $PSScriptRoot 'warmup.log' }

function Write-Log([string]$Instance, [string]$Msg) {
    $line = '{0:yyyy-MM-dd HH:mm:ss}  [{1}]  {2}' -f (Get-Date), $Instance, $Msg
    Write-Host $line
    Add-Content -Path $logPath -Value $line
}

function Invoke-Timed([scriptblock]$Block) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try { & $Block | Out-Null; $ok = $true; $err = $null }
    catch { $ok = $false; $err = $_.Exception.Message }
    $sw.Stop()
    [pscustomobject]@{ Ok = $ok; Ms = $sw.ElapsedMilliseconds; Error = $err }
}

$failures = 0

foreach ($inst in $config.Instances) {
    $name    = $inst.Name
    $base    = $inst.BaseUrl.TrimEnd('/')
    $timeout = if ($inst.TimeoutSec) { $inst.TimeoutSec } else { 600 }
    $session = $null
    $loggedIn = $false

    try {
        Write-Log $name "=== Warm-up start: $base"

        # 1. Wait for the app to answer (first request after recycle can take minutes)
        $deadline = (Get-Date).AddSeconds($timeout)
        $up = $false
        while (-not $up -and (Get-Date) -lt $deadline) {
            $r = Invoke-Timed { Invoke-WebRequest -Uri "$base/" -UseBasicParsing -TimeoutSec $timeout }
            if ($r.Ok) { $up = $true; Write-Log $name ("App responding ({0:n0} ms)" -f $r.Ms) }
            else       { Write-Log $name "Not up yet: $($r.Error). Retrying in 15s"; Start-Sleep 15 }
        }
        if (-not $up) { throw "App did not respond within $timeout s" }

        # 2. Login
        $cred = Import-Clixml $inst.CredentialFile
        $body = @{
            name     = $cred.UserName
            password = $cred.GetNetworkCredential().Password
            tenant   = $inst.Tenant
        } | ConvertTo-Json
        Invoke-WebRequest -Uri "$base/entity/auth/login" -Method Post -Body $body `
            -ContentType 'application/json' -SessionVariable session -UseBasicParsing `
            -TimeoutSec $timeout | Out-Null
        $loggedIn = $true
        Write-Log $name "Logged in as $($cred.UserName) / tenant $($inst.Tenant)"

        # 3. Screens: compile .aspx + init graph
        foreach ($screen in $inst.Screens) {
            $path = "Pages/{0}/{1}.aspx" -f $screen.Substring(0,2), $screen
            $r = Invoke-Timed { Invoke-WebRequest -Uri "$base/$path" -WebSession $session -UseBasicParsing -TimeoutSec $timeout }
            Write-Log $name ("Screen {0,-10} {1,-4} {2,8:n0} ms {3}" -f $screen, ($(if($r.Ok){'OK'}else{'FAIL'})), $r.Ms, $r.Error)
        }

        # 4. REST entities: graphs, caches, query plans
        $ep = "$base/entity/$($inst.Endpoint)/$($inst.EndpointVersion)"
        foreach ($entity in $inst.Entities) {
            $r = Invoke-Timed { Invoke-RestMethod -Uri "$ep/$entity`?`$top=1" -WebSession $session -TimeoutSec $timeout }
            Write-Log $name ("Entity {0,-18} {1,-4} {2,8:n0} ms {3}" -f $entity, ($(if($r.Ok){'OK'}else{'FAIL'})), $r.Ms, $r.Error)
        }

        Write-Log $name "=== Warm-up complete"
    }
    catch {
        $failures++
        Write-Log $name "ERROR: $($_.Exception.Message)"
    }
    finally {
        # 5. Always release the session/license slot
        if ($loggedIn) {
            try {
                Invoke-WebRequest -Uri "$base/entity/auth/logout" -Method Post -WebSession $session -UseBasicParsing | Out-Null
                Write-Log $name "Logged out"
            } catch { Write-Log $name "Logout failed: $($_.Exception.Message)" }
        }
    }
}

exit [int]($failures -gt 0)
