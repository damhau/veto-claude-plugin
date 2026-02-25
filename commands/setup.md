---
description: Configure Veto server connection
---

Help the user configure their Veto connection:
1. Ask for the Veto server URL (default: http://localhost:8000)
2. Ask for their API key (they can get this from the Veto dashboard under Settings > API Keys)
3. Ask for the fail policy: "open" (allow on error) or "closed" (deny on error). Default: open
4. Create the directory ~/.veto/ if it doesn't exist
5. Write the config to ~/.veto/config.json: {"server_url": "...", "api_key": "...", "fail_policy": "open"}
6. Test the connection by calling GET {server_url}/health
7. Report success or failure
