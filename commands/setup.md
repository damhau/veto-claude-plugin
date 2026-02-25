---
description: Configure Veto server connection
---

Help the user configure their Veto connection step by step.

IMPORTANT: Do NOT use AskUserQuestion for the API key. The "Other" text input does not work well for pasting keys.

Step 1 - Use AskUserQuestion to ask for server URL and fail policy together:

Question 1 - Server URL:
- header: "Server URL"
- question: "What is your Veto server URL?"
- options: "http://localhost:8000 (Recommended)" and "http://localhost:3000"

Question 2 - Fail policy:
- header: "Fail policy"
- question: "What should happen if the Veto server is unreachable?"
- options: "open — allow tool calls (Recommended)" and "closed — deny tool calls"

Step 2 - Ask for the API key as a plain text message (NOT AskUserQuestion):
Say: "Please paste your Veto API key (find it in the Veto dashboard under Settings > API Keys). Or type 'skip' for local development without an API key."
Wait for the user to reply with their key or "skip".

Step 3 - After collecting all answers:
1. Create the directory ~/.veto/ if it doesn't exist
2. Write the config to ~/.veto/config.json: {"server_url": "...", "api_key": "...", "fail_policy": "open", "timeout": 25}
   If the user skipped the API key, set "api_key": ""
3. Test the connection by running: curl -s -o /dev/null -w "%{http_code}" {server_url}/health
4. Report success or failure
