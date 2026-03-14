---
description: Configure Veto server connection
---

Help the user configure their Veto connection step by step.

IMPORTANT: Do NOT use AskUserQuestion for the API key. The "Other" text input does not work well for pasting keys.

Step 0 - OS Detection and Home Path Resolution:
1. Run `uname -s` via the Bash tool
2. If the result contains "Darwin" → macOS
3. If the result contains "Linux" → Linux
4. If the command fails or returns something else → ask the user via AskUserQuestion with options: "Windows", "Linux", "macOS"
5. Resolve the absolute home directory path and store it for all subsequent steps:
   - Linux/macOS: run `echo $HOME`
   - Windows: run `powershell -Command 'Write-Output $HOME'`
   Store the result (e.g. `/home/user` or `C:\Users\user`) as HOME_PATH. Use this literal value everywhere below — NEVER use `~`, `$HOME`, or `$env:USERPROFILE` in file paths.

Remember the detected OS for ALL subsequent steps. On Windows, ALL Bash commands MUST use PowerShell syntax. NEVER use Unix commands (mkdir -p, curl, cat) on Windows.

Step 1 - Use AskUserQuestion to ask for the fail policy:

Question 1 - Fail policy:
- header: "Fail policy"
- question: "What should happen if the Veto server is unreachable?"
- options: "closed — deny tool calls" and "open — allow tool calls (Recommended)"

Step 2 - Ask for the API key as a plain text message (NOT AskUserQuestion):
Say: "Please paste your Veto API key (find it in the Veto dashboard under Settings > API Keys). Or type 'skip' for local development without an API key."
Wait for the user to reply with their key or "skip".

Step 3 - After collecting all answers:

1. Create the config directory if it doesn't exist:
   - Linux/macOS: `mkdir -p ~/.veto`
   - Windows: `mkdir $HOME\.veto -Force`

2. Write the config file using the Write tool with the absolute path `{HOME_PATH}/.veto/config.json`:
   Content: {"api_key": "...", "fail_policy": "...", "timeout": 25}
   Use the fail_policy value from the user's answer in Step 1 ("open" or "closed").
   If the user skipped the API key, set "api_key": ""

4. Report success or failure
