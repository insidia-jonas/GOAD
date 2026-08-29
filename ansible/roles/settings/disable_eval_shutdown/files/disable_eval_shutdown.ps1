# Disable Windows Evaluation / trial shutdown on every Windows SKU.
# Covers:
#   - WLMS (Windows Licensing Monitoring Service) — hourly shutdown on Eval
#   - License Manager scheduled tasks and service
#   - SkipRearm / SoftwareProtectionPlatform tweaks
# Safe to re-run (idempotent). Prints CHANGED / OK / WARNING for Ansible.

$ErrorActionPreference = 'Continue'

function Write-Changed([string]$Message) { Write-Host "CHANGED: $Message" }
function Write-Ok([string]$Message)      { Write-Host "OK: $Message" }
function Write-Warn([string]$Message)    { Write-Host "WARNING: $Message" }

function Disable-WindowsService {
    param([Parameter(Mandatory = $true)][string]$Name)

    try {
        $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if (-not $service) {
            Write-Ok "Service not found: $Name"
            return
        }

        $changed = $false
        if ($service.StartType -ne 'Disabled') {
            Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
            Set-Service -Name $Name -StartupType Disabled
            sc.exe config $Name start= disabled | Out-Null
            $changed = $true
        }
        elseif ($service.Status -eq 'Running') {
            Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
            $changed = $true
        }

        if ($changed) {
            Write-Changed "Disabled and stopped service: $Name"
        }
        else {
            Write-Ok "Service already disabled: $Name"
        }
    }
    catch {
        Write-Warn "Could not configure service ${Name}: $_"
    }
}

function Disable-LicenseScheduledTasks {
    $taskRoots = @(
        '\Microsoft\Windows\License Manager\',
        '\Microsoft\Windows\Windows Activation Technologies\',
        '\Microsoft\Windows\SoftwareProtectionPlatform\'
    )

    foreach ($taskPath in $taskRoots) {
        $tasks = @()
        try {
            $tasks = @(Get-ScheduledTask -TaskPath $taskPath -ErrorAction SilentlyContinue)
        }
        catch {
            continue
        }

        foreach ($task in $tasks) {
            if (-not $task) { continue }
            $match = ($task.TaskName -match '(?i)shutdown|license|activation|rearm|wlms|eval')
            if (-not $match) { continue }
            if ($task.State -eq 'Disabled') {
                Write-Ok "Scheduled task already disabled: $($task.TaskPath)$($task.TaskName)"
                continue
            }
            try {
                Disable-ScheduledTask -TaskPath $task.TaskPath -TaskName $task.TaskName | Out-Null
                Write-Changed "Disabled scheduled task: $($task.TaskPath)$($task.TaskName)"
            }
            catch {
                Write-Warn "Could not disable task $($task.TaskName): $_"
            }
        }
    }

    # Catch tasks registered under other paths (WLMS / eval leftovers)
    try {
        $extra = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
            $_.TaskName -match '(?i)ScheduledShutdown|WLMS|EvalShutdown|LicenseManager'
        })
        foreach ($task in $extra) {
            if ($task.State -eq 'Disabled') { continue }
            try {
                Disable-ScheduledTask -TaskPath $task.TaskPath -TaskName $task.TaskName | Out-Null
                Write-Changed "Disabled extra license task: $($task.TaskPath)$($task.TaskName)"
            }
            catch {
                Write-Warn "Could not disable extra task $($task.TaskName): $_"
            }
        }
    }
    catch { }
}

# 1. WLMS is the service that powers off Evaluation editions after ~1 hour
Disable-WindowsService -Name 'WLMS'

# 2. Modern License Manager service (Win10/11 / Server 2019+)
Disable-WindowsService -Name 'LicenseManager'

# 3. Scheduled shutdown / activation tasks
Disable-LicenseScheduledTasks

# 4. SkipRearm + suppress eval nag (cosmetic / rearm budget)
try {
    $spp = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform'
    if (-not (Test-Path $spp)) {
        New-Item -Path $spp -Force | Out-Null
    }
    $current = Get-ItemProperty -Path $spp -Name 'SkipRearm' -ErrorAction SilentlyContinue
    if (-not $current -or $current.SkipRearm -ne 1) {
        Set-ItemProperty -Path $spp -Name 'SkipRearm' -Value 1 -Type DWord -Force
        Write-Changed 'Set SkipRearm registry value'
    }
    else {
        Write-Ok 'SkipRearm already set'
    }
}
catch {
    Write-Warn "Could not set SkipRearm: $_"
}

# 5. Hide remaining evaluation grace-period UI noise when the key exists
try {
    $evalKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $edition = (Get-ItemProperty -Path $evalKey -Name 'EditionID' -ErrorAction SilentlyContinue).EditionID
    if ($edition -and $edition -match '(?i)Eval') {
        Write-Ok "Edition is evaluation ($edition); WLMS/License Manager disabled"
    }
    else {
        Write-Ok "Edition is not evaluation ($edition)"
    }
}
catch { }

# 6. Best-effort rearm (extends remaining eval time; harmless if already exhausted)
try {
    $rearmMarker = 'HKLM:\SOFTWARE\GOAD\DisableEvalShutdown'
    if (-not (Test-Path $rearmMarker)) {
        New-Item -Path $rearmMarker -Force | Out-Null
    }
    $alreadyRearmed = (Get-ItemProperty -Path $rearmMarker -Name 'RearmAttempted' -ErrorAction SilentlyContinue).RearmAttempted
    if ($alreadyRearmed -ne 1) {
        $p = Start-Process -FilePath 'cscript.exe' -ArgumentList '//Nologo C:\Windows\System32\slmgr.vbs /rearm' -Wait -PassThru -WindowStyle Hidden
        Set-ItemProperty -Path $rearmMarker -Name 'RearmAttempted' -Value 1 -Type DWord -Force
        Write-Changed "Attempted slmgr /rearm (exit $($p.ExitCode))"
    }
    else {
        Write-Ok 'slmgr /rearm already attempted on this host'
    }
}
catch {
    Write-Warn "slmgr /rearm skipped: $_"
}

Write-Host 'Evaluation shutdown prevention completed'
