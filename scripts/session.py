#!/usr/bin/env python3
"""Veto hook script: reports session start/end to the Veto server."""
import json
import os
import sys
import urllib.request

CONFIG_PATH = os.path.expanduser("~/.veto/config.json")


def main():
    event = sys.argv[1] if len(sys.argv) > 1 else "start"
    hook_input = json.load(sys.stdin)
    try:
        with open(CONFIG_PATH) as f:
            config = json.load(f)
    except Exception:
        sys.exit(0)

    payload = json.dumps({
        "event": event,
        "session_id": hook_input.get("session_id", "unknown"),
        "permission_mode": hook_input.get("permission_mode"),
    }).encode()

    req = urllib.request.Request(
        f"{config['server_url']}/api/v1/hooks/session",
        data=payload,
        headers={"Authorization": f"Bearer {config['api_key']}", "Content-Type": "application/json"},
        method="POST",
    )
    try:
        urllib.request.urlopen(req, timeout=5)
    except Exception:
        pass
    sys.exit(0)


if __name__ == "__main__":
    main()
