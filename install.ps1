# Claude Code Windows Notifications - Installer
# Run: irm https://raw.githubusercontent.com/tornado1014/claude-code-windows-notify/master/install.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host "Claude Code Windows Notifications - Installer" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Check Node.js
$nodeVersion = node --version 2>$null
if (-not $nodeVersion) {
    Write-Host "Error: Node.js is required. Install from https://nodejs.org" -ForegroundColor Red
    exit 1
}
Write-Host "Node.js: $nodeVersion" -ForegroundColor Green

# Paths
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$hooksDir = Join-Path $claudeDir "hooks"
$settingsPath = Join-Path $claudeDir "settings.json"
$scriptPath = Join-Path $hooksDir "windows-notification.mjs"

# Create directories
if (-not (Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    Write-Host "Created: $hooksDir" -ForegroundColor Gray
}

# Determine source path (local or remote)
$scriptDir = if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { $null }
$localSource = if ($scriptDir) { Join-Path $scriptDir "hooks\windows-notification.mjs" } else { $null }

if ($localSource -and (Test-Path $localSource)) {
    # Local install
    Copy-Item $localSource $scriptPath -Force
    Write-Host "Installed: $scriptPath" -ForegroundColor Green
} else {
    # Remote install - download from GitHub
    $repoUrl = "https://raw.githubusercontent.com/tornado1014/claude-code-windows-notify/master/hooks/windows-notification.mjs"
    try {
        Invoke-WebRequest -Uri $repoUrl -OutFile $scriptPath -UseBasicParsing
        Write-Host "Downloaded: $scriptPath" -ForegroundColor Green
    } catch {
        Write-Host "Error downloading script: $_" -ForegroundColor Red
        exit 1
    }
}

# Update settings.json
$hookCommand = "node `"%USERPROFILE%\.claude\hooks\windows-notification.mjs`""
$newHooks = @{
    Notification = @(
        @{
            hooks = @(
                @{
                    type = "command"
                    command = $hookCommand
                    timeout = 10
                }
            )
        }
    )
    Stop = @(
        @{
            hooks = @(
                @{
                    type = "command"
                    command = $hookCommand
                    timeout = 10
                }
            )
        }
    )
}

if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable
} else {
    $settings = @{}
}

# Merge hooks
if (-not $settings.ContainsKey("hooks")) {
    $settings["hooks"] = @{}
}

foreach ($event in $newHooks.Keys) {
    if ($settings["hooks"].ContainsKey($event)) {
        # Check if already installed
        $existing = $settings["hooks"][$event] | ConvertTo-Json -Compress
        if ($existing -match "windows-notification\.mjs") {
            Write-Host "Hook already exists for: $event" -ForegroundColor Yellow
            continue
        }
        # Append to existing hooks
        $settings["hooks"][$event] += $newHooks[$event]
    } else {
        $settings["hooks"][$event] = $newHooks[$event]
    }
    Write-Host "Added hook: $event" -ForegroundColor Green
}

# Save settings
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "Updated: $settingsPath" -ForegroundColor Green

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Cyan
Write-Host "Restart Claude Code to activate notifications." -ForegroundColor White
