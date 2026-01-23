# Claude Code Windows Notifications

Windows toast notifications for Claude Code events. Get notified when Claude needs your attention or completes a task.

## Features

- **Idle Prompt**: Notifies when Claude is waiting for input
- **Permission Prompt**: Notifies when Claude needs permission
- **Task Complete**: Notifies when Claude finishes work

## Requirements

- Windows 10/11
- [Claude Code](https://claude.ai/claude-code) CLI
- Node.js 18+ (for .mjs version)

## Installation

### Quick Install (PowerShell)

```powershell
irm https://raw.githubusercontent.com/tornado1014/ccwn/master/install.ps1 | iex
```

### Manual Install

1. Clone the repository:
   ```powershell
   git clone https://github.com/tornado1014/ccwn.git
   cd claude-code-windows-notify
   ```

2. Run the install script:
   ```powershell
   .\install.ps1
   ```

## Configuration

The installer automatically adds hooks to your Claude Code settings. You can customize notifications by editing:

- `~/.claude/hooks/windows-notification.mjs` - Notification messages
- `~/.claude/settings.json` - Hook configuration

### Notification Events

| Event | Default Message |
|-------|-----------------|
| `idle_prompt` | "Waiting for input" |
| `permission_prompt` | "Permission required" |
| `Stop` | "Task completed" |

## Uninstall

```powershell
.\uninstall.ps1
```

Or manually:
1. Remove hooks from `~/.claude/settings.json`
2. Delete `~/.claude/hooks/windows-notification.mjs`

## How It Works

This uses Claude Code's [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks) to trigger Windows toast notifications via the native `Windows.UI.Notifications` API.

## License

MIT
