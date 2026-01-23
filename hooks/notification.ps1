# Claude Code Notification Hook
# Uses native Windows.UI.Notifications API (no external dependencies)
param()

$inputData = $input | Out-String

try {
    $data = $inputData | ConvertFrom-Json
} catch {
    Write-Output '{"continue":true}'
    exit 0
}

$hookEvent = $data.hook_event_name
$notificationType = $data.notification_type
$message = $data.message

function Show-ToastNotification {
    param([string]$Title, [string]$Message)
    try {
        Add-Type -AssemblyName System.Runtime.WindowsRuntime
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
        $xml = "<toast><visual><binding template=`"ToastText02`"><text id=`"1`">$Title</text><text id=`"2`">$Message</text></binding></visual><audio silent=`"true`"/></toast>"
        $xdoc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xdoc.LoadXml($xml)
        $toast = New-Object Windows.UI.Notifications.ToastNotification $xdoc
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code")
        $notifier.Show($toast)
    } catch {}
}

switch ($hookEvent) {
    "Notification" {
        switch ($notificationType) {
            "idle_prompt" { Show-ToastNotification -Title "Claude Code" -Message "Waiting for input" }
            "permission_prompt" {
                $msg = if ($message) { $message } else { "Permission required" }
                Show-ToastNotification -Title "Claude Code" -Message $msg
            }
            "elicitation_dialog" { Show-ToastNotification -Title "Claude Code" -Message "MCP tool requires input" }
            default { if ($message) { Show-ToastNotification -Title "Claude Code" -Message $message } }
        }
    }
    "Stop" { Show-ToastNotification -Title "Claude Code" -Message "Task completed" }
}

Write-Output '{"continue":true}'
