---
description: Check Veto server connection status and active rules
---

Check the Veto configuration at ~/.veto/config.json. If it exists, read the server_url (default: https://api.vetoapp.io) and api_key, then:

IMPORTANT: Claude Code always uses bash, even on Windows. Use only bash-compatible commands (cat, curl). Never use PowerShell cmdlets.

1. Read the config: cat ~/.veto/config.json
2. Call GET {server_url}/health to check connectivity using curl
3. Call GET {server_url}/api/v1/rules with the API key to count active rules using curl
4. Report: server URL, connection status (ok/unreachable), rule count, and fail policy
