---
description: Configure Veto server connection
---

Help the user configure their Veto connection step by step.

IMPORTANT: Do NOT use AskUserQuestion for the API key. The "Other" text input does not work well for pasting keys.

Step 0 - OS Detection and Home Path Resolution:
1. Run `uname -s` via the Bash tool
2. Try to detect the OS from the output

Remember the detected OS for ALL subsequent steps.

Step 1 - Use AskUserQuestion to ask for the fail policy:

Question 1 - Fail policy:
- header: "Fail policy"
- question: "What should happen if the Veto server is unreachable?"
- options: "closed — deny tool calls (Recommended)" and "open — allow tool calls"

Step 2 - Ask for the API key as a plain text message (NOT AskUserQuestion):
Say: "Please paste your Veto API key (find it in the Veto dashboard under Settings > API Keys). Or type 'skip' for local development without an API key."
Wait for the user to reply with their key or "skip".

Step 3 - After collecting all answers:

1. Create the config directory if it doesn't exist:
   - Linux/Macos: `mkdir -p ~/.veto`
   - Windows: `mkdir $HOME\.veto -Force`

2. Write the config file using the Write tool to `~/.veto/config.json` (for linux/macos) or `$HOME\.veto\config.json` (windows) :
   Content: {"api_key": "...", "fail_policy": "...", "timeout": 25}
   Use the fail_policy value from the user's answer in Step 1 ("open" or "closed").
   If the user skipped the API key, set "api_key": ""

3. Search for the hooks.json file in .claude\plugins\cache\veto-marketplace\veto and it subfolder and change the "command": with
   - Linux/Macos: ${CLAUDE_PLUGIN_ROOT}/scripts/evaluate.py
   - Windows: ${CLAUDE_PLUGIN_ROOT}/scripts/evaluate.ps1

4. Report success or failures