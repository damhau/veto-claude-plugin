---
description: Check Veto server connection status and active rules
---

Check the Veto configuration at ~/.veto/config.json. If it exists, read the server_url (default: https://api.vetoapp.io) and api_key, then:

1. Call GET {server_url}/health to check connectivity
2. Call GET {server_url}/api/v1/rules with the API key to count active rules
3. Report: server URL, connection status (ok/unreachable), rule count, and fail policy
