# Claude Code Windows Notifications - Installer
# Run: irm https://raw.githubusercontent.com/tornado1014/ccwn/master/install.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host "Claude Code Windows Notifications - Installer" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Paths
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$hooksDir = Join-Path $claudeDir "hooks"
$settingsPath = Join-Path $claudeDir "settings.json"
$scriptPath = Join-Path $hooksDir "notification.ps1"

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
        Write-Host "Hook already exists for: Notification" -ForegroundColor Yellow
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
        Write-Host "Hook already exists for: Stop" -ForegroundColor Yellow
    } else {
        $settings.hooks.Stop += (New-HookEntry)
        Write-Host "Added hook: Stop" -ForegroundColor Green
    }
}

# Save settings
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "Updated: $settingsPath" -ForegroundColor Green

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Cyan
Write-Host "Restart Claude Code to activate notifications." -ForegroundColor White
