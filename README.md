# 🔔 claude-desktop-code-bell

**Sound notifications for Claude Code on macOS** — never miss a permission prompt again.

Claude Code works silently by default. When it needs your approval (file edits, bash commands), there's no sound — you have to stare at the screen. This tiny tool fixes that with native macOS sounds, zero dependencies.

## The Problem

Claude Code asks for permission prompts **silently**. If you switch to another window, you miss them and Claude just... waits. This is a [known issue](https://github.com/anthropics/claude-code/issues/28774) with no built-in fix.

## The Fix

Two hooks in your Claude Code config:
- **🔔 Glass** (or your choice) — plays when Claude needs your permission
- **🔔 Ping** (or your choice) — plays when Claude finishes working

That's it. No background processes, no extra apps, no Node.js — just `afplay` and macOS built-in sounds.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Zubrock/claude-desktop-code-bell/main/install.sh | bash
```

Then **restart Claude Code**.

## What It Does

The installer adds two hooks to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Glass.aiff &",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Ping.aiff",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

## Available Sounds

During installation you can pick from all macOS built-in sounds:

| Sound | Vibe |
|-------|------|
| **Glass** (default for permissions) | Gentle chime |
| **Ping** (default for completion) | Quick ping |
| Basso | Deep alert |
| Blow | Soft blow |
| Bottle | Pop |
| Frog | Quirky |
| Funk | Funky error |
| Hero | Triumphant |
| Morse | Dot-dash |
| Pop | Quick pop |
| Purr | Soft purr |
| Sosumi | Classic Mac |
| Submarine | Sonar |
| Tink | Light tap |

Preview any sound: `afplay /System/Library/Sounds/Glass.aiff`

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/Zubrock/claude-desktop-code-bell/main/uninstall.sh | bash
```

## Requirements

- macOS (uses `afplay` — built into every Mac)
- Claude Code CLI installed (`~/.claude` directory exists)
- `jq` (installer will prompt to install via Homebrew if missing)

## How It Works

Claude Code has a [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks) that runs shell commands on events:

- **`PermissionRequest`** — fires when Claude needs user approval (file write, bash command, etc.)
- **`Stop`** — fires when Claude finishes its response

We simply run `afplay` (macOS built-in audio player) with a system sound file. The `&` on the permission sound makes it non-blocking so it doesn't slow down Claude.

## FAQ

**Q: Will this slow down Claude Code?**
A: No. `afplay` plays in the background (`&`) and takes <100ms to start. The timeout is 5 seconds as a safety net.

**Q: Does it work with Claude Desktop app?**
A: Yes! The hooks are in `~/.claude/settings.json` which is shared between Claude Code CLI and Claude Desktop.

**Q: Can I change sounds later?**
A: Yes — edit `~/.claude/settings.json` and change the sound file path. Or re-run the installer.

**Q: Does it work on Linux/Windows?**
A: No. This uses macOS-specific `afplay`. PRs welcome for cross-platform support!

## License

MIT

---

<p align="center">Made with 🤍 by <a href="https://github.com/Zubrock">Zubrock</a></p>
