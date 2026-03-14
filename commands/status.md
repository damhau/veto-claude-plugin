---
description: Check Veto server connection status and active rules
---

Check the Veto configuration at ~/.veto/config.json. If it exists, read the server_url (default: https://api.vetoapp.io) and api_key, then:

Step 0 - OS Detection:
1. Run `uname -s` via the Bash tool
2. If the result contains "Darwin" → macOS
3. If the result contains "Linux" → Linux
4. If the command fails or returns something else → assume Windows

Step 1 - Health check:
- Linux/macOS: run `curl -s -o /dev/null -w "%{http_code}" {server_url}/health`
- Windows: run `powershell -Command "(Invoke-WebRequest -Uri '{server_url}/health' -UseBasicParsing).StatusCode"`

Step 2 - Rules check:
- Linux/macOS: run `curl -s -H "Authorization: Bearer {api_key}" {server_url}/api/v1/rules`
- Windows: run `powershell -Command "Invoke-RestMethod -Uri '{server_url}/api/v1/rules' -Headers @{'Authorization'='Bearer {api_key}'}"`

Step 3 - Report: server URL, connection status (ok/unreachable), rule count, and fail policy.
