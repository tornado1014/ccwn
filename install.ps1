# ccwn v2.0 - Claude Code Windows Notifications Installer
# Run: irm https://raw.githubusercontent.com/tornado1014/ccwn/master/install.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "ccwn v2.0 - Claude Code Windows Notifications" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Paths
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$hooksDir = Join-Path $claudeDir "hooks"
$settingsPath = Join-Path $claudeDir "settings.json"
$scriptPath = Join-Path $hooksDir "notification.ps1"
$configPath = Join-Path $claudeDir "ccwn-config.json"

# Create directories
if (-not (Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    Write-Host "Created: $hooksDir" -ForegroundColor Gray
}

# Determine source path (local or remote)
$scriptDir = if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { $null }
$localSource = if ($scriptDir) { Join-Path $scriptDir "hooks\notification.ps1" } else { $null }

if ($localSource -and (Test-Path $localSource)) {
    # Local install
    Copy-Item $localSource $scriptPath -Force
    Write-Host "Installed: $scriptPath" -ForegroundColor Green
} else {
    # Remote install - download from GitHub
    $repoUrl = "https://raw.githubusercontent.com/tornado1014/ccwn/master/hooks/notification.ps1"
    try {
        Invoke-WebRequest -Uri $repoUrl -OutFile $scriptPath -UseBasicParsing
        Write-Host "Downloaded: $scriptPath" -ForegroundColor Green
    } catch {
        Write-Host "Error downloading script: $_" -ForegroundColor Red
        exit 1
    }
}

# Hook configuration
$hookCommand = "powershell -NoProfile -ExecutionPolicy Bypass -File `"%USERPROFILE%\.claude\hooks\notification.ps1`""

# Read existing settings or create new
if (Test-Path $settingsPath) {
    $settingsJson = Get-Content $settingsPath -Raw
    $settings = $settingsJson | ConvertFrom-Json
} else {
    $settings = [PSCustomObject]@{}
}

# Ensure hooks property exists
if (-not ($settings.PSObject.Properties.Name -contains "hooks")) {
    $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([PSCustomObject]@{})
}

# Helper function to create hook entry
function New-HookEntry {
    return @(
        [PSCustomObject]@{
            hooks = @(
                [PSCustomObject]@{
                    type = "command"
                    command = $hookCommand
                    timeout = 10
                }
            )
        }
    )
}

# Add Notification hook
if (-not ($settings.hooks.PSObject.Properties.Name -contains "Notification")) {
    $settings.hooks | Add-Member -NotePropertyName "Notification" -NotePropertyValue (New-HookEntry)
    Write-Host "Added hook: Notification" -ForegroundColor Green
} else {
    $existingJson = $settings.hooks.Notification | ConvertTo-Json -Compress
    if ($existingJson -match "notification\.ps1") {
        Write-Host "Hook exists: Notification" -ForegroundColor Yellow
    } else {
        $settings.hooks.Notification += (New-HookEntry)
        Write-Host "Added hook: Notification" -ForegroundColor Green
    }
}

# Add Stop hook
if (-not ($settings.hooks.PSObject.Properties.Name -contains "Stop")) {
    $settings.hooks | Add-Member -NotePropertyName "Stop" -NotePropertyValue (New-HookEntry)
    Write-Host "Added hook: Stop" -ForegroundColor Green
} else {
    $existingJson = $settings.hooks.Stop | ConvertTo-Json -Compress
    if ($existingJson -match "notification\.ps1") {
        Write-Host "Hook exists: Stop" -ForegroundColor Yellow
    } else {
        $settings.hooks.Stop += (New-HookEntry)
        Write-Host "Added hook: Stop" -ForegroundColor Green
    }
}

# Save settings
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "Updated: $settingsPath" -ForegroundColor Green

# ============================================
# ntfy Push Notification Setup
# ============================================

Write-Host ""
Write-Host "=== ntfy Push Notifications ===" -ForegroundColor Cyan
Write-Host "Get notifications on your phone when Claude needs attention."
Write-Host ""

$setupNtfy = Read-Host "Enable ntfy push notifications? (y/N)"

if ($setupNtfy -eq "y" -or $setupNtfy -eq "Y") {
    Write-Host ""
    Write-Host "A topic name is like a password - choose something hard to guess." -ForegroundColor Yellow

    # Generate random topic suggestion
    $randomTopic = "ccwn-$(Get-Random -Maximum 999999)-$(Get-Random -Maximum 999999)"
    Write-Host "Suggested: $randomTopic"
    Write-Host ""

    $topic = Read-Host "Enter topic name (or press Enter for suggested)"
    if (-not $topic) {
        $topic = $randomTopic
    }

    Write-Host ""
    Write-Host "Server: ntfy.sh (public, free)" -ForegroundColor Gray

    # Create config
    $config = @{
        version = "2.0"
        localToast = @{
            enabled = $true
            silent = $true
        }
        ntfy = @{
            enabled = $true
            server = "https://ntfy.sh"
            topic = $topic
            auth = @{
                type = "none"
                token = ""
            }
            defaults = @{
                priority = "default"
                tags = @("computer", "claude")
            }
        }
        events = @{
            idle_prompt = @{
                localToast = $true
                ntfy = $true
                title = "Claude Code"
                message = "Waiting for input"
                priority = "default"
                tags = @("hourglass")
            }
            permission_prompt = @{
                localToast = $true
                ntfy = $true
                title = "Claude Code"
                message = "Permission required"
                priority = "high"
                tags = @("warning")
            }
            elicitation_dialog = @{
                localToast = $true
                ntfy = $true
                title = "Claude Code"
                message = "MCP tool requires input"
                priority = "default"
                tags = @("question")
            }
            stop = @{
                localToast = $true
                ntfy = $true
                title = "Claude Code"
                message = "Task completed"
                priority = "low"
                tags = @("white_check_mark")
            }
        }
    }

    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
    Write-Host ""
    Write-Host "Created: $configPath" -ForegroundColor Green

    # Mobile app setup instructions
    Write-Host ""
    Write-Host "=== Mobile App Setup ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Install ntfy app on your phone:" -ForegroundColor White
    Write-Host "   Android: Play Store or F-Droid" -ForegroundColor Gray
    Write-Host "   iOS: App Store" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Open the app and tap '+' to subscribe" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Enter topic: " -NoNewline -ForegroundColor White
    Write-Host "$topic" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "4. Server: https://ntfy.sh (default)" -ForegroundColor White
    Write-Host ""

    # Test notification
    $testNotify = Read-Host "Send test notification? (Y/n)"
    if ($testNotify -ne "n" -and $testNotify -ne "N") {
        Write-Host ""
        try {
            Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method POST `
                -Headers @{ Title = "ccwn Test"; Tags = "tada,white_check_mark" } `
                -Body "Installation successful! ccwn is ready." -TimeoutSec 10 | Out-Null
            Write-Host "Test notification sent!" -ForegroundColor Green
            Write-Host "Check your phone (if you've subscribed to the topic)" -ForegroundColor Gray
        } catch {
            Write-Host "Failed to send test: $_" -ForegroundColor Red
        }
    }
} else {
    # Create basic config without ntfy
    if (-not (Test-Path $configPath)) {
        $config = @{
            version = "2.0"
            localToast = @{
                enabled = $true
                silent = $true
            }
            ntfy = @{
                enabled = $false
                server = "https://ntfy.sh"
                topic = ""
                auth = @{
                    type = "none"
                    token = ""
                }
            }
        }
        $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
        Write-Host "Created: $configPath (ntfy disabled)" -ForegroundColor Gray
    }
}

# Install ccwn CLI (if available locally)
$ccwnCliSource = if ($scriptDir) { Join-Path $scriptDir "ccwn.ps1" } else { $null }
if ($ccwnCliSource -and (Test-Path $ccwnCliSource)) {
    $ccwnCliDest = Join-Path $claudeDir "ccwn.ps1"
    Copy-Item $ccwnCliSource $ccwnCliDest -Force
    Write-Host "Installed CLI: $ccwnCliDest" -ForegroundColor Green
    Write-Host ""
    Write-Host "CLI commands:" -ForegroundColor Yellow
    Write-Host "  powershell $ccwnCliDest test     - Send test notification" -ForegroundColor Gray
    Write-Host "  powershell $ccwnCliDest config   - Open config file" -ForegroundColor Gray
    Write-Host "  powershell $ccwnCliDest status   - Show status" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "Restart Claude Code to activate notifications." -ForegroundColor White
Write-Host ""
