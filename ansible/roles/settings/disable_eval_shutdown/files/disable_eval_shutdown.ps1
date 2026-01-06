# Disable Windows Server Evaluation Shutdown
# This script prevents Windows Server Evaluation from shutting down after the trial period expires

# 1. Disable the License Manager scheduled task that triggers the shutdown
$taskPath = "\Microsoft\Windows\License Manager\"
$taskName = "ScheduledShutdown"

try {
    $task = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        if ($task.State -ne 'Disabled') {
            Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName
            Write-Host "CHANGED: Disabled scheduled task: $taskPath$taskName"
        } else {
            Write-Host "OK: Scheduled task already disabled: $taskPath$taskName"
        }
    } else {
        Write-Host "OK: Scheduled task not found (may not be an evaluation version)"
    }
} catch {
    Write-Host "WARNING: Could not disable scheduled task: $_"
}

# 2. Also check for any other license-related shutdown tasks
$allLicenseTasks = Get-ScheduledTask -TaskPath "\Microsoft\Windows\License Manager\*" -ErrorAction SilentlyContinue
foreach ($t in $allLicenseTasks) {
    if ($t.State -ne 'Disabled' -and $t.TaskName -like "*Shutdown*") {
        try {
            Disable-ScheduledTask -TaskPath $t.TaskPath -TaskName $t.TaskName
            Write-Host "CHANGED: Disabled additional license task: $($t.TaskPath)$($t.TaskName)"
        } catch {
            Write-Host "WARNING: Could not disable task $($t.TaskName): $_"
        }
    }
}

# 3. Disable the Windows License Manager Service (optional, more aggressive)
$serviceName = "LicenseManager"
try {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.StartType -ne 'Disabled') {
            Set-Service -Name $serviceName -StartupType Disabled
            Write-Host "CHANGED: Disabled service: $serviceName"
        } else {
            Write-Host "OK: Service already disabled: $serviceName"
        }
        if ($service.Status -eq 'Running') {
            Stop-Service -Name $serviceName -Force
            Write-Host "CHANGED: Stopped service: $serviceName"
        }
    } else {
        Write-Host "OK: Service not found: $serviceName"
    }
} catch {
    Write-Host "WARNING: Could not configure service: $_"
}

# 4. Create a registry key to suppress the evaluation notice (cosmetic)
try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
    if (Test-Path $regPath) {
        $currentValue = Get-ItemProperty -Path $regPath -Name "SkipRearm" -ErrorAction SilentlyContinue
        if (-not $currentValue -or $currentValue.SkipRearm -ne 1) {
            Set-ItemProperty -Path $regPath -Name "SkipRearm" -Value 1 -Type DWord -Force
            Write-Host "CHANGED: Set SkipRearm registry value"
        } else {
            Write-Host "OK: SkipRearm already set"
        }
    }
} catch {
    Write-Host "WARNING: Could not set registry value: $_"
}

Write-Host "Evaluation shutdown prevention completed"
