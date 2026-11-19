# Server Management Scripts

## Purpose

PowerShell scripts for managing the Acumatica instances Peerless-AV runs itself: the three offline
change-control instances, and local development instances such as 2026R1DEV. They cover three things:

1. **Stay warm.** IIS keeps the Acumatica app loaded, and a warm-up script pre-loads screens and caches,
   so the first person to open Acumatica after a restart doesn't wait for pages to compile and caches to build.
2. **Controlled stop.** Shut down the app and SQL Server cleanly, in the right order. Use it before updates,
   or to free memory on a dev machine.
3. **Controlled start.** Bring everything back in the right order, confirm SQL is ready, then warm the instance up.

These scripts are for **self-hosted Acumatica on Windows / IIS / SQL Server only**. They have not been used against Live.

## Files

| File | Run | What it does |
|---|---|---|
| `Set-AcumaticaIisAlwaysOn.ps1` | Once per VM (elevated) | Installs IIS Application Initialization. Sets the app pool to AlwaysRunning with no idle timeout, swaps the default 29-hour rolling recycle for a fixed daily recycle time, and turns on preload |
| `Invoke-AcumaticaWarmup.ps1` | Scheduled / on demand | Waits for the site, logs in through REST, opens each listed screen (page compile + graph init), GETs `$top=1` on each listed entity (caches and queries), always logs out. Writes a timed log line per step |
| `warmup.config.json` | Edit per VM | Instances, URLs, tenant, credential file, endpoint version, and the screens and entities to warm |
| `Stop-Acumatica.ps1` | On demand (elevated) | App pool(s), then SQL Agent, then SQL Server. Waits for the worker process to exit |
| `Start-Acumatica.ps1` | On demand (elevated) | SQL Server (waits until all databases are online), then SQL Agent, then IIS, then app pool(s), then warm-up if asked |

## Setup (per VM)

1. Copy this folder to the VM, e.g. `C:\AcuWarmup\`.
2. Run once, elevated:
   ```powershell
   .\Set-AcumaticaIisAlwaysOn.ps1 -SiteName "Default Web Site" -AppPath "/2026R1DEV" -RecycleAt "03:00"
   ```
3. **Credentials.** Sign in as the account that will run the scheduled task and create the encrypted credential file:
   ```powershell
   Get-Credential | Export-Clixml C:\AcuWarmup\cred-2026R1DEV.xml
   ```
   The file is encrypted with Windows DPAPI, so it only works for **that account on that machine**.
   Use a dedicated low-privilege API user that can open the warmed screens. **Never commit `cred-*.xml`.** The local `.gitignore` blocks it.
4. **Edit `warmup.config.json`:**
   - `EndpointVersion`: check it on the Web Service Endpoints screen (SM207060) of each instance (`24.200.001` is a placeholder)
   - `Screens` / `Entities`: what people actually open, including customized screens (e.g. the Stock Item screen with the EPR tab)
   - Add one entry under `Instances` for each instance on the VM
5. Test by hand: `.\Invoke-AcumaticaWarmup.ps1`, then check `warmup.log`.
6. **Task Scheduler:** create one task with two triggers.
   - **At startup**, delayed 2–3 minutes
   - **Daily**, about 5 minutes after the `-RecycleAt` time

   Action: `powershell.exe -ExecutionPolicy Bypass -File C:\AcuWarmup\Invoke-AcumaticaWarmup.ps1`
7. Set SQL Server **max server memory** on each VM. Without a limit, SQL slowly takes most of the VM's RAM.

## Usage

```powershell
# Dev laptop, done for the day (then suspend the Parallels VM to give the RAM back to macOS)
.\Stop-Acumatica.ps1 -AppPool 2026R1DEV -DisableAutoStart

# Dev laptop, starting work
.\Start-Acumatica.ps1 -AppPool 2026R1DEV -Warmup

# Acumatica version upgrade: app down, SQL stays up for the Configuration Wizard
.\Stop-Acumatica.ps1 -AppPool AcuTEST -KeepSql
#   ... run upgrade ...
.\Start-Acumatica.ps1 -AppPool AcuTEST -Warmup

# Full maintenance (Windows updates, SQL patching)
.\Stop-Acumatica.ps1 -AppPool AcuTEST
.\Start-Acumatica.ps1 -AppPool AcuTEST -Warmup

# Named SQL instance / several pools
.\Stop-Acumatica.ps1 -AppPool AcuTEST,AcuSTAGE -SqlInstance SQL2022

# Run on a server from your workstation
Invoke-Command -ComputerName <vm> -FilePath .\Stop-Acumatica.ps1 -ArgumentList @('AcuTEST')
```

### Switches

| Script | Switch | Effect |
|---|---|---|
| Stop | `-KeepSql` | Stop only the app, leave SQL running |
| Stop | `-DisableAutoStart` | Pools set to not auto-start and SQL services set to Manual, so a reboot doesn't start them |
| Stop | `-Force` | Kill the worker process if it hasn't exited after `-TimeoutSec` |
| Start | `-EnableAutoStart` | Undo `-DisableAutoStart` (AlwaysRunning, SQL services Automatic) |
| Start | `-Warmup` | Run `Invoke-AcumaticaWarmup.ps1` when started |

All scripts are idempotent: anything already in the requested state is skipped. Exit code `0` means success, `1` means failures or warnings.

## Notes & limitations

- **Publishing a customization, or changing `web.config`, restarts the app** and wipes the warm-up. Run the warm-up by hand afterwards.
- **Modern UI:** the warm-up covers the server side (graphs, caches, queries). The screen code that runs in the browser is cached by each user's browser, so the first open of a Modern UI screen still costs something on the client.
- **Dev laptop trade-off:** an always-on instance holds a few GB in the IIS worker process plus SQL Server's memory cache. Idle CPU is negligible. In Parallels, the VM's assigned RAM is held either way, so suspending the VM frees more than stopping services.
- Requires Windows PowerShell 5.1 or PowerShell 7+, the `WebAdministration` module, and admin rights (except for the warm-up).

---

## History

| Date | Change |
|---|---|
| 2026-11-19 | Initial version: `Set-AcumaticaIisAlwaysOn.ps1`, `Invoke-AcumaticaWarmup.ps1`, `warmup.config.json`, `Stop-Acumatica.ps1`, `Start-Acumatica.ps1`. Not yet tested on 2026R1DEV or the change-control VMs |
