# ccwn v2.0 - Claude Code Windows Notifications Uninstaller

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "ccwn - Uninstaller" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host ""

# Paths
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$hooksDir = Join-Path $claudeDir "hooks"
$settingsPath = Join-Path $claudeDir "settings.json"
$scriptPath = Join-Path $hooksDir "notification.ps1"
$configPath = Join-Path $claudeDir "ccwn-config.json"
$ccwnCliPath = Join-Path $claudeDir "ccwn.ps1"

# Remove notification script
if (Test-Path $scriptPath) {
    Remove-Item $scriptPath -Force
    Write-Host "Removed: $scriptPath" -ForegroundColor Green
} else {
    Write-Host "Not found: $scriptPath" -ForegroundColor Gray
}

# Remove hooks from settings
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

    if ($settings.hooks) {
        $modified = $false

        # Remove Notification hook entries containing notification.ps1
        if ($settings.hooks.PSObject.Properties.Name -contains "Notification") {
            $filtered = @($settings.hooks.Notification | Where-Object {
                $json = $_ | ConvertTo-Json -Compress
                $json -notmatch "notification\.ps1"
            })
            if ($filtered.Count -eq 0) {
                $settings.hooks.PSObject.Properties.Remove("Notification")
                Write-Host "Removed hook: Notification" -ForegroundColor Green
            } else {
                $settings.hooks.Notification = $filtered
                Write-Host "Cleaned hook: Notification" -ForegroundColor Green
            }
            $modified = $true
        }

        # Remove Stop hook entries containing notification.ps1
        if ($settings.hooks.PSObject.Properties.Name -contains "Stop") {
            $filtered = @($settings.hooks.Stop | Where-Object {
                $json = $_ | ConvertTo-Json -Compress
                $json -notmatch "notification\.ps1"
            })
            if ($filtered.Count -eq 0) {
                $settings.hooks.PSObject.Properties.Remove("Stop")
                Write-Host "Removed hook: Stop" -ForegroundColor Green
            } else {
                $settings.hooks.Stop = $filtered
                Write-Host "Cleaned hook: Stop" -ForegroundColor Green
            }
            $modified = $true
        }

        if ($modified) {
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
            Write-Host "Updated: $settingsPath" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Not found: $settingsPath" -ForegroundColor Gray
}

# Remove config file
if (Test-Path $configPath) {
    $removeConfig = Read-Host "Remove ccwn config file? (y/N)"
    if ($removeConfig -eq "y" -or $removeConfig -eq "Y") {
        Remove-Item $configPath -Force
        Write-Host "Removed: $configPath" -ForegroundColor Green
    } else {
        Write-Host "Kept: $configPath" -ForegroundColor Gray
    }
} else {
    Write-Host "Not found: $configPath" -ForegroundColor Gray
}

# Remove CLI tool
if (Test-Path $ccwnCliPath) {
    Remove-Item $ccwnCliPath -Force
    Write-Host "Removed: $ccwnCliPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Uninstallation complete!" -ForegroundColor Cyan
Write-Host "Restart Claude Code to apply changes." -ForegroundColor White
Write-Host ""
