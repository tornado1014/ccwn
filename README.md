# ccwn - Claude Code Windows Notifications

Windows toast notifications + ntfy push notifications for Claude Code events.

Get notified on your **desktop** and **phone** when Claude needs your attention or completes a task.

**No external dependencies** - Uses native Windows.UI.Notifications API + ntfy.sh HTTP API.

## Features

- **Local Toast Notifications**: Native Windows 10/11 notifications
- **ntfy Push Notifications**: Get alerts on your phone/tablet via [ntfy.sh](https://ntfy.sh/)
- **Configurable Events**: Customize which events trigger notifications
- **Event Types**:
  - `idle_prompt` - Claude is waiting for input
  - `permission_prompt` - Claude needs permission
  - `elicitation_dialog` - MCP tool requires input
  - `stop` - Task completed

## Requirements

- Windows 10/11
- [Claude Code](https://claude.ai/claude-code) CLI
- PowerShell 5.1+ (included in Windows)
- (Optional) ntfy app on your phone for push notifications

## Installation

### Quick Install (PowerShell)

```powershell
irm https://raw.githubusercontent.com/tornado1014/ccwn/master/install.ps1 | iex
```

### Manual Install

1. Clone the repository:
   ```powershell
   git clone https://github.com/tornado1014/ccwn.git
   cd ccwn
   ```

2. Run the install script:
   ```powershell
   .\install.ps1
   ```

3. Follow the prompts to configure ntfy push notifications (optional)

## ntfy Setup (Mobile Push Notifications)

### During Installation

The installer will ask if you want to enable ntfy push notifications. If you choose yes:

1. A unique topic name will be generated (e.g., `ccwn-847291-382917`)
2. Install the ntfy app on your phone:
   - **Android**: [Play Store](https://play.google.com/store/apps/details?id=io.heckel.ntfy) or [F-Droid](https://f-droid.org/packages/io.heckel.ntfy/)
   - **iOS**: [App Store](https://apps.apple.com/app/ntfy/id1625396347)
3. Open the app and tap **+** to subscribe
4. Enter your topic name
5. That's it! You'll now receive push notifications

### After Installation

Enable ntfy anytime by editing `~/.claude/ccwn-config.json`:

```json
{
  "ntfy": {
    "enabled": true,
    "server": "https://ntfy.sh",
    "topic": "your-unique-topic-name"
  }
}
```

Or use the CLI:
```powershell
# Enable ntfy
powershell ~/.claude/ccwn.ps1 ntfy enable

# Set topic
powershell ~/.claude/ccwn.ps1 topic my-unique-topic

# Test notifications
powershell ~/.claude/ccwn.ps1 test
```

## Configuration

Configuration file: `~/.claude/ccwn-config.json`

### Full Configuration Example

```json
{
  "version": "2.0",
  "localToast": {
    "enabled": true,
    "silent": true
  },
  "ntfy": {
    "enabled": true,
    "server": "https://ntfy.sh",
    "topic": "ccwn-123456-789012",
    "auth": {
      "type": "none",
      "token": ""
    },
    "defaults": {
      "priority": "default",
      "tags": ["computer", "claude"]
    }
  },
  "events": {
    "idle_prompt": {
      "localToast": true,
      "ntfy": true,
      "title": "Claude Code",
      "message": "Waiting for input",
      "priority": "default",
      "tags": ["hourglass"]
    },
    "permission_prompt": {
      "localToast": true,
      "ntfy": true,
      "title": "Claude Code",
      "message": "Permission required",
      "priority": "high",
      "tags": ["warning"]
    },
    "stop": {
      "localToast": true,
      "ntfy": true,
      "title": "Claude Code",
      "message": "Task completed",
      "priority": "low",
      "tags": ["white_check_mark"]
    }
  }
}
```

### Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `localToast.enabled` | Enable Windows toast notifications | `true` |
| `localToast.silent` | Suppress notification sound | `true` |
| `ntfy.enabled` | Enable ntfy push notifications | `false` |
| `ntfy.server` | ntfy server URL | `https://ntfy.sh` |
| `ntfy.topic` | Your unique topic name | `""` |
| `ntfy.auth.type` | Authentication type (`none` or `bearer`) | `none` |
| `ntfy.auth.token` | Bearer token for private topics | `""` |

### Event Configuration

Each event can be configured with:
- `localToast`: Enable/disable local toast for this event
- `ntfy`: Enable/disable ntfy push for this event
- `title`: Notification title
- `message`: Default message
- `priority`: ntfy priority (`min`, `low`, `default`, `high`, `urgent`)
- `tags`: ntfy tags (converted to emojis)

## CLI Commands

After installation, use the CLI tool:

```powershell
# Show help
powershell ~/.claude/ccwn.ps1

# Show configuration status
powershell ~/.claude/ccwn.ps1 status

# Open config file in editor
powershell ~/.claude/ccwn.ps1 config

# Send test notification
powershell ~/.claude/ccwn.ps1 test

# Enable/disable ntfy
powershell ~/.claude/ccwn.ps1 ntfy enable
powershell ~/.claude/ccwn.ps1 ntfy disable

# Change topic
powershell ~/.claude/ccwn.ps1 topic my-new-topic
```

## Uninstall

```powershell
.\uninstall.ps1
```

Or manually:
1. Remove hooks from `~/.claude/settings.json`
2. Delete `~/.claude/hooks/notification.ps1`
3. Delete `~/.claude/ccwn-config.json` (optional)
4. Delete `~/.claude/ccwn.ps1` (optional)

## How It Works

1. Claude Code triggers hooks on events (Notification, Stop)
2. `notification.ps1` receives event data via stdin
3. Based on config, it sends:
   - **Local Toast**: Windows.UI.Notifications API
   - **ntfy Push**: HTTP POST to ntfy server
4. You receive notifications on desktop and/or phone

## Security Notes

- **Topic names** act like passwords - use randomly generated names
- ntfy.sh is a public service - anyone who knows your topic can subscribe
- For sensitive use cases, consider:
  - Self-hosted ntfy server
  - Bearer token authentication
  - Private topics with access control

## Troubleshooting

### Notifications not appearing

1. Check Windows notification settings for "Claude Code"
2. Verify `~/.claude/ccwn-config.json` exists and is valid JSON
3. Run `powershell ~/.claude/ccwn.ps1 test` to test

### ntfy not working

1. Verify ntfy app is subscribed to the correct topic
2. Check internet connection
3. Run `powershell ~/.claude/ccwn.ps1 status` to see config
4. Try sending manual test: `curl -d "test" ntfy.sh/your-topic`

## Credits

Inspired by [ai-notifier-swift](https://github.com/sokojh/ai-notifier-swift) for macOS.

## License

MIT
