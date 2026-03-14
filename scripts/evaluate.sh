#!/usr/bin/env bash
#
# Veto hook script: evaluates tool calls against the Veto server (macOS/bash version).
#
# Reads the hook input from stdin, sends it to the Veto API for evaluation,
# and outputs the decision (allow/deny) to stdout. Falls back to the configured
# fail policy (open or closed) if the server is unreachable.
#

set -euo pipefail

CONFIG_PATH="${HOME}/.veto/config.json"
LOG_PATH="${HOME}/.veto/hook.log"

log() {
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    echo "[$ts] $1" >> "$LOG_PATH" 2>/dev/null || true
}

send_decision() {
    local decision="$1"
    cat <<ENDJSON
{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"${decision}"}}}
ENDJSON
}

main() {
    log "start"

    # Read hook input from stdin
    local raw_input
    raw_input=$(cat) || {
        log "failed to read stdin"
        exit 0
    }

    # Extract fields from hook input using python3
    local session_id tool_name
    session_id=$(echo "$raw_input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id','unknown'))" 2>/dev/null) || session_id="unknown"
    tool_name=$(echo "$raw_input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null) || tool_name=""

    log "hook_input: session=${session_id} tool=${tool_name}"

    # Load config
    if [ ! -f "$CONFIG_PATH" ]; then
        log "missing config -> fail open"
        exit 0
    fi

    local config
    config=$(cat "$CONFIG_PATH" 2>/dev/null) || {
        log "failed to read config -> fail open"
        exit 0
    }

    local server_url api_key fail_policy timeout verify_ssl
    server_url=$(echo "$config" | python3 -c "import sys,json; print(json.load(sys.stdin).get('server_url','https://api.vetoapp.io'))" 2>/dev/null) || server_url="https://api.vetoapp.io"
    api_key=$(echo "$config" | python3 -c "import sys,json; print(json.load(sys.stdin).get('api_key',''))" 2>/dev/null) || api_key=""
    fail_policy=$(echo "$config" | python3 -c "import sys,json; print(json.load(sys.stdin).get('fail_policy','open'))" 2>/dev/null) || fail_policy="open"
    timeout=$(echo "$config" | python3 -c "import sys,json; print(json.load(sys.stdin).get('timeout',25))" 2>/dev/null) || timeout=25
    verify_ssl=$(echo "$config" | python3 -c "import sys,json; print(json.load(sys.stdin).get('verify_ssl',True))" 2>/dev/null) || verify_ssl="True"

    # Build curl SSL flags
    local curl_ssl_flags=""
    if [ "$verify_ssl" = "False" ] || [ "$verify_ssl" = "false" ]; then
        log "SSL verification disabled"
        curl_ssl_flags="--insecure"
    fi

    local ca_file
    ca_file=$(echo "$config" | python3 -c "import sys,json; v=json.load(sys.stdin).get('ca_file'); print(v if v else '')" 2>/dev/null) || ca_file=""
    if [ -n "$ca_file" ]; then
        log "SSL verification enabled with custom CA file: ${ca_file}"
        curl_ssl_flags="--cacert ${ca_file}"
    fi

    # Build payload using python3
    local payload
    payload=$(echo "$raw_input" | python3 -c "
import sys, json
hook = json.load(sys.stdin)
payload = {
    'session_id': hook.get('session_id', 'unknown'),
    'tool_name': hook.get('tool_name', ''),
    'tool_input': hook.get('tool_input', {}),
    'cwd': hook.get('cwd'),
    'permission_mode': hook.get('permission_mode'),
    'hook_event_name': hook.get('hook_event_name'),
    'raw_hook': hook,
}
print(json.dumps(payload))
" 2>/dev/null) || {
        log "failed to build payload"
        if [ "$fail_policy" = "closed" ]; then
            log "fail_policy=closed -> deny"
            send_decision "deny"
        fi
        exit 0
    }

    log "sending request to ${server_url}"

    # Send request
    local response http_code body
    response=$(curl -s -w "\n%{http_code}" \
        --max-time "$timeout" \
        $curl_ssl_flags \
        -X POST \
        -H "Authorization: Bearer ${api_key}" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "${server_url}/api/v1/hooks/evaluate" 2>/dev/null) || {
        log "request failed: curl error"
        if [ "$fail_policy" = "closed" ]; then
            log "fail_policy=closed -> deny"
            send_decision "deny"
        fi
        exit 0
    }

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" -lt 200 ] || [ "$http_code" -ge 300 ]; then
        log "request failed: HTTP ${http_code}"
        if [ "$fail_policy" = "closed" ]; then
            log "fail_policy=closed -> deny"
            send_decision "deny"
        fi
        exit 0
    fi

    log "response: ${body}"

    # Extract decision
    local decision
    decision=$(echo "$body" | python3 -c "import sys,json; print(json.load(sys.stdin).get('decision','ask'))" 2>/dev/null) || decision="ask"

    log "decision: ${decision}"

    if [ "$decision" = "allow" ]; then
        send_decision "allow"
    elif [ "$decision" = "deny" ]; then
        send_decision "deny"
    else
        # ask -> no output, Claude will prompt user
        log "decision=ask -> no output"
    fi

    exit 0
}

main
