#!/bin/bash
#
# Veto hook script for macOS: evaluates tool calls against the Veto server.
#
# Reads the hook input from stdin, sends it to the Veto API for evaluation,
# and outputs the decision (allow/deny) to stdout. Falls back to the configured
# fail policy (open or closed) if the server is unreachable.
#
# Dependencies: bash, curl, sed (all built into macOS)

CONFIG_PATH="$HOME/.veto/config.json"
LOG_PATH="$HOME/.veto/hook.log"

log() {
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
    mkdir -p "$(dirname "$LOG_PATH")" 2>/dev/null
    echo "[$ts] $1" >> "$LOG_PATH" 2>/dev/null
}

send_decision() {
    printf '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"%s"}}}\n' "$1"
}

# Extract a string value from simple flat JSON using sed
# Usage: json_str '{"key":"value"}' "key" -> value
json_str() {
    printf '%s' "$1" | sed -n 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

# Extract a number value from simple flat JSON using sed
# Usage: json_num '{"key":25}' "key" -> 25
json_num() {
    printf '%s' "$1" | sed -n 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -1
}

main() {
    log "start"

    # Read hook input from stdin
    local raw_input
    raw_input=$(cat)
    if [ -z "$raw_input" ]; then
        log "failed to read stdin"
        exit 0
    fi

    # Extract fields for logging (best effort from raw JSON)
    local session_id tool_name
    session_id=$(json_str "$raw_input" "session_id")
    tool_name=$(json_str "$raw_input" "tool_name")
    log "hook_input: session=$session_id tool=$tool_name"

    # Load config
    if [ ! -f "$CONFIG_PATH" ]; then
        log "missing config -> fail open"
        exit 0
    fi

    local config
    config=$(cat "$CONFIG_PATH" 2>/dev/null)
    if [ -z "$config" ]; then
        log "load_config failed: empty or unreadable"
        exit 0
    fi

    local server_url api_key fail_policy timeout
    server_url=$(json_str "$config" "server_url")
    api_key=$(json_str "$config" "api_key")
    fail_policy=$(json_str "$config" "fail_policy")
    timeout=$(json_num "$config" "timeout")

    : "${server_url:=https://api.vetoapp.io}"
    : "${fail_policy:=open}"
    : "${timeout:=25}"

    # Build payload: the hook input already contains session_id, tool_name,
    # tool_input, cwd, permission_mode, hook_event_name — we just append raw_hook.
    # We strip the trailing } from the input and append ,"raw_hook":<input>}
    local trimmed payload
    trimmed=$(printf '%s' "$raw_input" | tr -d '\n')
    payload="${trimmed%\}},\"raw_hook\":${trimmed}}"

    log "sending request to $server_url"

    # Send request using curl
    local response curl_exit http_code body
    response=$(curl -s -w "\n%{http_code}" \
        --max-time "$timeout" \
        -X POST \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$server_url/api/v1/hooks/evaluate" 2>/dev/null)
    curl_exit=$?

    if [ $curl_exit -ne 0 ]; then
        log "request failed: curl exit code $curl_exit"
        if [ "$fail_policy" = "closed" ]; then
            log "fail_policy=closed -> deny"
            send_decision "deny"
        fi
        exit 0
    fi

    body=$(printf '%s' "$response" | sed '$d')
    http_code=$(printf '%s' "$response" | tail -1)

    if [ "$http_code" -lt 200 ] 2>/dev/null || [ "$http_code" -ge 300 ] 2>/dev/null; then
        log "request failed: HTTP $http_code"
        if [ "$fail_policy" = "closed" ]; then
            log "fail_policy=closed -> deny"
            send_decision "deny"
        fi
        exit 0
    fi

    log "response: $body"

    # Extract decision from response (flat JSON)
    local decision
    decision=$(json_str "$body" "decision")
    : "${decision:=ask}"

    log "decision: $decision"

    if [ "$decision" = "allow" ]; then
        send_decision "allow"
    elif [ "$decision" = "deny" ]; then
        send_decision "deny"
    else
        log "decision=ask -> no output"
    fi

    exit 0
}

main
