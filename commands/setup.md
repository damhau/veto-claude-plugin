---
description: Configure Veto server connection
---

Help the user configure their Veto connection. Ask all questions in a single AskUserQuestion call with multiple questions:

Question 1 - Server URL:
- header: "Server URL"
- question: "What is your Veto server URL?"
- options: "http://localhost:8000 (Recommended)" and "http://localhost:3000"
- The user can also type a custom URL via the "Other" option

Question 2 - API key:
- header: "API key"
- question: "Paste your Veto API key (find it in the Veto dashboard under Settings > API Keys). Select 'Other' and paste your key, or skip for local dev."
- options: "No API key (local dev)" and "I'll paste my key (select Other below)"

Question 3 - Fail policy:
- header: "Fail policy"
- question: "What should happen if the Veto server is unreachable?"
- options: "open — allow tool calls (Recommended)" and "closed — deny tool calls"

After collecting answers:
1. Create the directory ~/.veto/ if it doesn't exist
2. Write the config to ~/.veto/config.json: {"server_url": "...", "api_key": "...", "fail_policy": "open", "timeout": 25}
3. Test the connection by running: curl -s -o /dev/null -w "%{http_code}" {server_url}/health
4. Report success or failure
