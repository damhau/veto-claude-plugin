---
description: Configure Veto server connection
---

Help the user configure their Veto connection step by step.

IMPORTANT: Do NOT use AskUserQuestion for the API key. The "Other" text input does not work well for pasting keys.

Step 0 - OS Detection:
1. Run `uname -s` via the Bash tool
2. If the result contains "Darwin" → macOS
3. If the result contains "Linux" → Linux
4. If the command fails or returns something else → ask the user via AskUserQuestion with options: "Windows", "Linux", "macOS"
Remember the detected OS for later steps.

Step 1 - Use AskUserQuestion to ask for the fail policy:

Question 1 - Fail policy:
- header: "Fail policy"
- question: "What should happen if the Veto server is unreachable?"
- options: "open — allow tool calls (Recommended)" and "closed — deny tool calls"

Step 2 - Ask for the API key as a plain text message (NOT AskUserQuestion):
Say: "Please paste your Veto API key (find it in the Veto dashboard under Settings > API Keys). Or type 'skip' for local development without an API key."
Wait for the user to reply with their key or "skip".

Step 3 - After collecting all answers:
1. Create the directory ~/.veto/ if it doesn't exist
2. Write the config to ~/.veto/config.json: {"api_key": "...", "fail_policy": "...", "timeout": 25}
   Use the fail_policy value from the user's answer in Step 1 ("open" or "closed").
   If the user skipped the API key, set "api_key": ""
3. Test the connection:
   - Linux/macOS: run `curl -s -o /dev/null -w "%{http_code}" https://api.vetoapp.io/health`
   - Windows: run `powershell -Command "(Invoke-WebRequest -Uri 'https://api.vetoapp.io/health' -UseBasicParsing).StatusCode"`
4. Report success or failure

Step 4 - Configure hooks for the detected OS:
Write the correct hooks.json to `~/.claude/plugins/marketplaces/veto-marketplace/hooks/hooks.json` based on the detected OS:

- Linux: command = `${HOME}/.claude/plugins/marketplaces/veto-marketplace/scripts/evaluate.py`
- macOS: command = `bash ${HOME}/.claude/plugins/marketplaces/veto-marketplace/scripts/evaluate.sh`
- Windows: command = `powershell -ExecutionPolicy Bypass -File "${HOME}/.claude/plugins/marketplaces/veto-marketplace/scripts/evaluate.ps1"`

The hooks.json format is:
```json
{
  "description": "Veto permission gateway hooks",
  "hooks": {
    "PermissionRequest": [
      {
        "matcher": "^(?!ExitPlanMode$|AskUserQuestion$).*",
        "hooks": [
          {
            "type": "command",
            "command": "<OS-specific command from above>",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

Report the detected OS and confirm that hooks have been configured.
