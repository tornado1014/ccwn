# ccwn v2.0 - Claude Code Windows Notifications with ntfy support
# Uses native Windows.UI.Notifications API + ntfy push notifications
param()

$inputData = $input | Out-String
$configPath = Join-Path $env:USERPROFILE ".claude\ccwn-config.json"

# Load configuration
function Get-CcwnConfig {
    if (Test-Path $configPath) {
        try {
            return Get-Content $configPath -Raw | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

# Get default config
function Get-DefaultConfig {
    return @{
        localToast = @{ enabled = $true; silent = $true }
        ntfy = @{ enabled = $false }
    }
}

# Windows Toast Notification
function Show-ToastNotification {
    param(
        [string]$Title,
        [string]$Message,
        [bool]$Silent = $true
    )
    try {
        Add-Type -AssemblyName System.Runtime.WindowsRuntime
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

        $audioXml = if ($Silent) { '<audio silent="true"/>' } else { '' }
        $xml = "<toast><visual><binding template=`"ToastText02`"><text id=`"1`">$Title</text><text id=`"2`">$Message</text></binding></visual>$audioXml</toast>"

        $xdoc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xdoc.LoadXml($xml)
        $toast = New-Object Windows.UI.Notifications.ToastNotification $xdoc
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code")
        $notifier.Show($toast)
    } catch {}
}

# ntfy Push Notification
function Send-NtfyNotification {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Priority = "default",
        [string[]]$Tags = @()
    )

    $config = Get-CcwnConfig
    if (-not $config -or -not $config.ntfy.enabled -or -not $config.ntfy.topic) {
        return
    }

    $uri = "$($config.ntfy.server)/$($config.ntfy.topic)"
    $headers = @{
        "Title" = $Title
        "Priority" = $Priority
    }

    if ($Tags.Count -gt 0) {
        $headers["Tags"] = ($Tags -join ",")
    }

    # Authentication
    if ($config.ntfy.auth -and $config.ntfy.auth.type -eq "bearer" -and $config.ntfy.auth.token) {
        $headers["Authorization"] = "Bearer $($config.ntfy.auth.token)"
    }

    try {
        Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $Message -TimeoutSec 5 -ErrorAction SilentlyContinue | Out-Null
    } catch {}
}

# Send notification to all configured channels
function Send-Notification {
    param(
        [string]$EventType,
        [string]$CustomMessage = ""
    )

    $config = Get-CcwnConfig
    if (-not $config) { $config = Get-DefaultConfig }

    # Default event settings
    $eventDefaults = @{
        idle_prompt = @{ title = "Claude Code"; message = "Waiting for input"; priority = "default"; tags = @("hourglass") }
        permission_prompt = @{ title = "Claude Code"; message = "Permission required"; priority = "high"; tags = @("warning") }
        elicitation_dialog = @{ title = "Claude Code"; message = "MCP tool requires input"; priority = "default"; tags = @("question") }
        stop = @{ title = "Claude Code"; message = "Task completed"; priority = "low"; tags = @("white_check_mark") }
    }

    # Get event config
    $eventConfig = if ($config.events -and $config.events.$EventType) {
        $config.events.$EventType
    } else {
        $eventDefaults[$EventType]
    }

    if (-not $eventConfig) {
        $eventConfig = @{ title = "Claude Code"; message = $CustomMessage; priority = "default"; tags = @("computer") }
    }

    $title = if ($eventConfig.title) { $eventConfig.title } else { "Claude Code" }
    $message = if ($CustomMessage) { $CustomMessage } else { $eventConfig.message }
    $priority = if ($eventConfig.priority) { $eventConfig.priority } else { "default" }
    $tags = if ($eventConfig.tags) { $eventConfig.tags } else { @() }

    # Local Toast
    $toastEnabled = if ($config.localToast -and $null -ne $config.localToast.enabled) { $config.localToast.enabled } else { $true }
    $eventToastEnabled = if ($null -ne $eventConfig.localToast) { $eventConfig.localToast } else { $true }

    if ($toastEnabled -and $eventToastEnabled) {
        $silent = if ($config.localToast -and $null -ne $config.localToast.silent) { $config.localToast.silent } else { $true }
        Show-ToastNotification -Title $title -Message $message -Silent $silent
    }

    # ntfy Push
    $ntfyEnabled = $config.ntfy -and $config.ntfy.enabled
    $eventNtfyEnabled = if ($null -ne $eventConfig.ntfy) { $eventConfig.ntfy } else { $true }

    if ($ntfyEnabled -and $eventNtfyEnabled) {
        Send-NtfyNotification -Title $title -Message $message -Priority $priority -Tags $tags
    }
}

# Main logic
try {
    $data = $inputData | ConvertFrom-Json
} catch {
    Write-Output '{"continue":true}'
    exit 0
}

$hookEvent = $data.hook_event_name
$notificationType = $data.notification_type
$message = $data.message

switch ($hookEvent) {
    "Notification" {
        switch ($notificationType) {
            "idle_prompt" { Send-Notification -EventType "idle_prompt" }
            "permission_prompt" { Send-Notification -EventType "permission_prompt" -CustomMessage $message }
            "elicitation_dialog" { Send-Notification -EventType "elicitation_dialog" }
            default { if ($message) { Send-Notification -EventType "default" -CustomMessage $message } }
        }
    }
    "Stop" { Send-Notification -EventType "stop" }
}

Write-Output '{"continue":true}'
