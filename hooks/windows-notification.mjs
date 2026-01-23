#!/usr/bin/env node
// Windows Toast Notification Hook for Claude Code
// Sends Windows notifications when Claude needs attention or completes work
// No external dependencies - uses native Windows.UI.Notifications API

import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

async function readStdin() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString('utf-8');
}

async function showNotification(title, message) {
  // Escape special characters for PowerShell
  const escapedTitle = title.replace(/"/g, '`"').replace(/'/g, "''");
  const escapedMessage = message.replace(/"/g, '`"').replace(/'/g, "''");

  // PowerShell script using Windows.UI.Notifications (no external dependencies)
  const psScript = `
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

    $xml = '<toast><visual><binding template="ToastText02"><text id="1">${escapedTitle}</text><text id="2">${escapedMessage}</text></binding></visual><audio silent="true"/></toast>'

    $xdoc = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xdoc.LoadXml($xml)
    $toast = New-Object Windows.UI.Notifications.ToastNotification $xdoc
    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code')
    $notifier.Show($toast)
  `.replace(/\r?\n/g, ' ').trim();

  try {
    await execAsync(`powershell -NoProfile -ExecutionPolicy Bypass -Command "${psScript}"`, {
      timeout: 5000,
      windowsHide: true
    });
  } catch (error) {
    // Silently fail - don't block Claude operations
  }
}

async function main() {
  try {
    const input = await readStdin();
    let data = {};
    try {
      data = JSON.parse(input);
    } catch {
      // Invalid JSON, just continue
    }

    const hookEvent = data.hook_event_name;
    const notificationType = data.notification_type;
    const message = data.message;

    // Handle Notification events
    if (hookEvent === 'Notification') {
      switch (notificationType) {
        case 'idle_prompt':
          await showNotification('Claude Code', 'Waiting for input');
          break;
        case 'permission_prompt':
          await showNotification('Claude Code', message || 'Permission required');
          break;
        case 'elicitation_dialog':
          await showNotification('Claude Code', 'MCP tool requires input');
          break;
        default:
          if (message) {
            await showNotification('Claude Code', message);
          }
      }
    }
    // Handle Stop event (work completed)
    else if (hookEvent === 'Stop') {
      await showNotification('Claude Code', 'Task completed');
    }

    // Always output continue: true to not block Claude
    console.log(JSON.stringify({ continue: true }));
  } catch (error) {
    // Notification failure should never block Claude
    console.log(JSON.stringify({ continue: true }));
  }
}

main();
