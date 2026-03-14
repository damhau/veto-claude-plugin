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
Remember the detected OS for ALL subsequent steps. On Windows, ALL Bash commands MUST use PowerShell syntax (prefix with `powershell -Command "..."`). NEVER use Unix commands (mkdir -p, curl, cat) on Windows.

Step 1 - Use AskUserQuestion to ask for the fail policy:

Question 1 - Fail policy:
- header: "Fail policy"
- question: "What should happen if the Veto server is unreachable?"
- options: "open — allow tool calls (Recommended)" and "closed — deny tool calls"

Step 2 - Ask for the API key as a plain text message (NOT AskUserQuestion):
Say: "Please paste your Veto API key (find it in the Veto dashboard under Settings > API Keys). Or type 'skip' for local development without an API key."
Wait for the user to reply with their key or "skip".

Step 3 - After collecting all answers:

1. Create the config directory if it doesn't exist:
   - Linux/macOS: `mkdir -p ~/.veto`
   - Windows: `powershell -Command "New-Item -ItemType Directory -Force -Path (Join-Path $env:USERPROFILE '.veto')"`

2. Write the config file. IMPORTANT: use ABSOLUTE paths, not `~`:
   - Linux/macOS: use the Write tool with path `$HOME/.veto/config.json` (resolve $HOME first with `echo $HOME`)
   - Windows: use the Write tool with path `$USERPROFILE/.veto/config.json` (resolve first with `powershell -Command "echo $env:USERPROFILE"`)
   Content: {"api_key": "...", "fail_policy": "...", "timeout": 25}
   Use the fail_policy value from the user's answer in Step 1 ("open" or "closed").
   If the user skipped the API key, set "api_key": ""

3. Test the connection:
   - Linux/macOS: `curl -s -o /dev/null -w "%{http_code}" https://api.vetoapp.io/health`
   - Windows: `powershell -Command "(Invoke-WebRequest -Uri 'https://api.vetoapp.io/health' -UseBasicParsing).StatusCode"`

4. Report success or failure
