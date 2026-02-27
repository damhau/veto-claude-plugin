# Veto — Claude Code Plugin

Centralized permission gateway for Claude Code. Evaluate every tool call against server-side rules and optional AI-powered risk scoring before it executes.

## What it does

When installed, this plugin intercepts all Claude Code tool calls (Bash, Write, Edit, etc.) and sends them to your Veto server for evaluation. The server checks the call against your configured rules (whitelist/blacklist patterns) and optionally runs AI-based risk scoring. The result — **allow**, **deny**, or **ask** — is returned to Claude Code before the tool executes.

**Hooks:**
- `PermissionRequest` — evaluates every tool call against the Veto server

**Commands:**
- `/veto:setup` — configure API key and fail policy
- `/veto:status` — check server connectivity and active rule count

## Prerequisites

- A [Veto](https://github.com/damhau/veto) account
- An API key from the Veto dashboard (Settings > API Keys)
- Python 3.8+ (uses only stdlib — no pip dependencies)

## Installation

### From the marketplace

```
/plugin marketplace add damhau/veto-claude-plugin
/plugin install veto
```

### Local development

```bash
claude --plugin-dir /path/to/veto-claude-plugin
```

## Setup

After installing, run the setup command:

```
/veto:setup
```

This will prompt you for:
1. **API key** — from the Veto dashboard
2. **Fail policy** — `open` (allow on error) or `closed` (deny on error)

Configuration is saved to `~/.veto/config.json`.

## How it works

```
Claude Code tool call
        │
        ▼
  PermissionRequest hook
        │
        ▼
  evaluate.py reads stdin
        │
        ▼
  POST /api/v1/hooks/evaluate
        │
        ▼
  Veto server checks rules
  + optional AI scoring
        │
        ▼
  Decision: allow / deny / ask
        │
        ▼
  Claude Code proceeds or blocks
```

### Fail policy

If the Veto server is unreachable:
- **open** (default) — tool calls are allowed (fail-open)
- **closed** — tool calls are denied (fail-closed)

### Logging

All hook activity is logged to `~/.veto/hook.log` for debugging.

## Configuration

`~/.veto/config.json`:

```json
{
  "server_url": "https://api.vetoapp.io",
  "api_key": "veto_...",
  "fail_policy": "open",
  "timeout": 25
}
```

| Field | Default | Description |
|-------|---------|-------------|
| `server_url` | `https://api.vetoapp.io` | Veto server URL |
| `api_key` | — | API key from the dashboard |
| `fail_policy` | `open` | `open` or `closed` |
| `timeout` | `25` | Request timeout in seconds |

## License

MIT
