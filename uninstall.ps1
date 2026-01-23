# Claude Code Windows Notifications - Uninstaller

$ErrorActionPreference = "Stop"

Write-Host "Claude Code Windows Notifications - Uninstaller" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

# Paths
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$hooksDir = Join-Path $claudeDir "hooks"
$settingsPath = Join-Path $claudeDir "settings.json"
$scriptPath = Join-Path $hooksDir "notification.ps1"

# Remove script file
if (Test-Path $scriptPath) {
    Remove-Item $scriptPath -Force
    Write-Host "Removed: $scriptPath" -ForegroundColor Green
} else {
    Write-Host "Script not found: $scriptPath" -ForegroundColor Yellow
}

# Update settings.json
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

    if ($settings.PSObject.Properties.Name -contains "hooks") {
        $modified = $false

        foreach ($event in @("Notification", "Stop")) {
            if ($settings.hooks.PSObject.Properties.Name -contains $event) {
                $hooks = @($settings.hooks.$event)
                $filtered = @($hooks | Where-Object {
                    $json = $_ | ConvertTo-Json -Compress
                    $json -notmatch "notification\.ps1"
                })

                if ($filtered.Count -ne $hooks.Count) {
                    if ($filtered.Count -eq 0) {
                        $settings.hooks.PSObject.Properties.Remove($event)
                    } else {
                        $settings.hooks.$event = $filtered
                    }
                    Write-Host "Removed hook: $event" -ForegroundColor Green
                    $modified = $true
                }
            }
        }

        if ($modified) {
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
            Write-Host "Updated: $settingsPath" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Settings not found: $settingsPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Uninstallation complete!" -ForegroundColor Cyan
