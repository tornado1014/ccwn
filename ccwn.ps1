# ccwn CLI - Claude Code Windows Notifications management tool
param(
    [Parameter(Position = 0)]
    [string]$Command,
    [Parameter(Position = 1)]
    [string]$Arg
)

$configPath = Join-Path $env:USERPROFILE ".claude\ccwn-config.json"

function Show-Help {
    Write-Host "ccwn - Claude Code Windows Notifications CLI" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: ccwn <command> [args]" -ForegroundColor White
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Yellow
    Write-Host "  config        Open configuration file in editor"
    Write-Host "  test          Send test notification"
    Write-Host "  status        Show current configuration status"
    Write-Host "  ntfy enable   Enable ntfy push notifications"
    Write-Host "  ntfy disable  Disable ntfy push notifications"
    Write-Host "  topic <name>  Change ntfy topic"
    Write-Host ""
}

function Get-Config {
    if (Test-Path $configPath) {
        try {
            return Get-Content $configPath -Raw | ConvertFrom-Json
        } catch {
            Write-Host "Error reading config file" -ForegroundColor Red
            return $null
        }
    }
    Write-Host "Config file not found. Run install.ps1 first." -ForegroundColor Yellow
    return $null
}

function Save-Config {
    param($config)
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
}

function Show-Status {
    $config = Get-Config
    if (-not $config) { return }

    Write-Host "ccwn Configuration Status" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Local Toast:" -ForegroundColor Yellow
    Write-Host "  Enabled: $($config.localToast.enabled)"
    Write-Host "  Silent:  $($config.localToast.silent)"
    Write-Host ""
    Write-Host "ntfy Push:" -ForegroundColor Yellow
    Write-Host "  Enabled: $($config.ntfy.enabled)"
    Write-Host "  Server:  $($config.ntfy.server)"
    Write-Host "  Topic:   $($config.ntfy.topic)"
    Write-Host ""
}

function Send-TestNotification {
    $config = Get-Config
    if (-not $config) { return }

    Write-Host "Sending test notifications..." -ForegroundColor Cyan

    # Local Toast
    if ($config.localToast.enabled) {
        try {
            Add-Type -AssemblyName System.Runtime.WindowsRuntime
            $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
            $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
            $xml = '<toast><visual><binding template="ToastText02"><text id="1">ccwn Test</text><text id="2">Local toast notification works!</text></binding></visual></toast>'
            $xdoc = New-Object Windows.Data.Xml.Dom.XmlDocument
            $xdoc.LoadXml($xml)
            $toast = New-Object Windows.UI.Notifications.ToastNotification $xdoc
            $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code")
            $notifier.Show($toast)
            Write-Host "  Local Toast: Sent" -ForegroundColor Green
        } catch {
            Write-Host "  Local Toast: Failed - $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  Local Toast: Disabled" -ForegroundColor Gray
    }

    # ntfy
    if ($config.ntfy.enabled -and $config.ntfy.topic) {
        try {
            $uri = "$($config.ntfy.server)/$($config.ntfy.topic)"
            $headers = @{
                "Title" = "ccwn Test"
                "Tags" = "test_tube,white_check_mark"
            }
            if ($config.ntfy.auth -and $config.ntfy.auth.type -eq "bearer" -and $config.ntfy.auth.token) {
                $headers["Authorization"] = "Bearer $($config.ntfy.auth.token)"
            }
            Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body "ntfy push notification works!" -TimeoutSec 10 | Out-Null
            Write-Host "  ntfy Push: Sent to $($config.ntfy.topic)" -ForegroundColor Green
        } catch {
            Write-Host "  ntfy Push: Failed - $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  ntfy Push: Disabled or no topic set" -ForegroundColor Gray
    }
}

function Set-NtfyEnabled {
    param([bool]$enabled)
    $config = Get-Config
    if (-not $config) { return }

    $config.ntfy.enabled = $enabled
    Save-Config $config

    $status = if ($enabled) { "enabled" } else { "disabled" }
    Write-Host "ntfy push notifications $status" -ForegroundColor Green
}

function Set-Topic {
    param([string]$topic)
    $config = Get-Config
    if (-not $config) { return }

    if (-not $topic) {
        Write-Host "Usage: ccwn topic <name>" -ForegroundColor Yellow
        return
    }

    $config.ntfy.topic = $topic
    Save-Config $config
    Write-Host "ntfy topic set to: $topic" -ForegroundColor Green
}

# Main
switch ($Command) {
    "config" {
        if (Test-Path $configPath) {
            Start-Process "notepad" $configPath
        } else {
            Write-Host "Config file not found. Run install.ps1 first." -ForegroundColor Yellow
        }
    }
    "test" { Send-TestNotification }
    "status" { Show-Status }
    "ntfy" {
        switch ($Arg) {
            "enable" { Set-NtfyEnabled $true }
            "disable" { Set-NtfyEnabled $false }
            default { Write-Host "Usage: ccwn ntfy [enable|disable]" -ForegroundColor Yellow }
        }
    }
    "topic" { Set-Topic $Arg }
    "help" { Show-Help }
    default { Show-Help }
}
