---
description: Configure Veto server connection
---

Help the user configure their Veto connection step by step.

IMPORTANT: Do NOT use AskUserQuestion for the API key. The "Other" text input does not work well for pasting keys.

Step 1 - Use AskUserQuestion to ask for the fail policy:

Question 1 - Fail policy:
- header: "Fail policy"
- question: "What should happen if the Veto server is unreachable?"
- options: "open — allow tool calls (Recommended)" and "closed — deny tool calls"

Step 2 - Ask for the API key as a plain text message (NOT AskUserQuestion):
Say: "Please paste your Veto API key (find it in the Veto dashboard under Settings > API Keys). Or type 'skip' for local development without an API key."
Wait for the user to reply with their key or "skip".

Step 3 - After collecting all answers:

IMPORTANT: Claude Code always uses bash, even on Windows. Use only bash-compatible commands (mkdir, cat, curl). Never use PowerShell cmdlets like New-Item, Set-Content, or Invoke-WebRequest.

1. Create the directory: mkdir -p ~/.veto
2. Write the config file using bash:
   cat > ~/.veto/config.json << 'VETOEOF'
   {"api_key": "<KEY>", "fail_policy": "<POLICY>", "timeout": 25}
   VETOEOF
   Use the fail_policy value from the user's answer in Step 1 ("open" or "closed").
   If the user skipped the API key, set "api_key": ""
3. Test the connection by running: curl -s -o /dev/null -w "%{http_code}" https://api.vetoapp.io/health
4. Report success or failure
