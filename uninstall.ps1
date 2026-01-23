# Claude Code Windows Notifications - Uninstaller

$ErrorActionPreference = "Stop"

Write-Host "Claude Code Windows Notifications - Uninstaller" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

# Paths
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$hooksDir = Join-Path $claudeDir "hooks"
$settingsPath = Join-Path $claudeDir "settings.json"
$scriptPath = Join-Path $hooksDir "windows-notification.mjs"

# Remove script file
if (Test-Path $scriptPath) {
    Remove-Item $scriptPath -Force
    Write-Host "Removed: $scriptPath" -ForegroundColor Green
} else {
    Write-Host "Script not found: $scriptPath" -ForegroundColor Yellow
}

# Update settings.json
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable

    if ($settings.ContainsKey("hooks")) {
        foreach ($event in @("Notification", "Stop")) {
            if ($settings["hooks"].ContainsKey($event)) {
                # Filter out windows-notification hooks
                $filtered = @($settings["hooks"][$event] | Where-Object {
                    $json = $_ | ConvertTo-Json -Compress
                    $json -notmatch "windows-notification\.mjs"
                })

                if ($filtered.Count -eq 0) {
                    $settings["hooks"].Remove($event)
                    Write-Host "Removed hook: $event" -ForegroundColor Green
                } else {
                    $settings["hooks"][$event] = $filtered
                    Write-Host "Cleaned hook: $event" -ForegroundColor Green
                }
            }
        }

        # Remove hooks key if empty
        if ($settings["hooks"].Count -eq 0) {
            $settings.Remove("hooks")
        }

        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
        Write-Host "Updated: $settingsPath" -ForegroundColor Green
    }
} else {
    Write-Host "Settings not found: $settingsPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Uninstallation complete!" -ForegroundColor Cyan
