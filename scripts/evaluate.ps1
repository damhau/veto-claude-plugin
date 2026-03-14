<#
.SYNOPSIS
    Veto hook script for Windows: evaluates tool calls against the Veto server.

.DESCRIPTION
    Reads the hook input from stdin, sends it to the Veto API for evaluation,
    and outputs the decision (allow/deny) to stdout. Falls back to the configured
    fail policy (open or closed) if the server is unreachable.
#>

$ErrorActionPreference = "SilentlyContinue"

$ConfigPath = Join-Path $env:USERPROFILE ".veto" "config.json"
$LogPath = Join-Path $env:USERPROFILE ".veto" "hook.log"

function Write-Log {
    param([string]$Message)
    try {
        $ts = (Get-Date).ToUniversalTime().ToString("o")
        $logDir = Split-Path $LogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -Path $LogPath -Value "[$ts] $Message"
    } catch {
        # never break execution because of logging
    }
}

function Send-Decision {
    param([string]$Decision)
    $output = @{
        hookSpecificOutput = @{
            hookEventName = "PermissionRequest"
            decision = @{
                behavior = $Decision
            }
        }
    } | ConvertTo-Json -Depth 5 -Compress
    Write-Output $output
}

function Main {
    Write-Log "start"

    # Read hook input from stdin
    try {
        $rawInput = [Console]::In.ReadToEnd()
        $hookInput = $rawInput | ConvertFrom-Json
        Write-Log "hook_input: session=$($hookInput.session_id) tool=$($hookInput.tool_name)"
    } catch {
        Write-Log "failed to read stdin: $_"
        exit 0
    }

    # Load config
    try {
        if (-not (Test-Path $ConfigPath)) {
            Write-Log "missing config -> fail open"
            exit 0
        }
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Log "load_config failed: $_"
        exit 0
    }

    $serverUrl = if ($config.server_url) { $config.server_url } else { "https://api.vetoapp.io" }
    $apiKey = if ($config.api_key) { $config.api_key } else { "" }
    $failPolicy = if ($config.fail_policy) { $config.fail_policy } else { "open" }
    $timeout = if ($config.timeout) { $config.timeout } else { 25 }

    $payload = @{
        session_id       = if ($hookInput.session_id) { $hookInput.session_id } else { "unknown" }
        tool_name        = if ($hookInput.tool_name) { $hookInput.tool_name } else { "" }
        tool_input       = if ($hookInput.tool_input) { $hookInput.tool_input } else { @{} }
        cwd              = $hookInput.cwd
        permission_mode  = $hookInput.permission_mode
        hook_event_name  = $hookInput.hook_event_name
        raw_hook         = $hookInput
    } | ConvertTo-Json -Depth 10 -Compress

    Write-Log "sending request to $serverUrl"

    try {
        $headers = @{
            "Authorization" = "Bearer $apiKey"
            "Content-Type"  = "application/json"
        }
        $response = Invoke-RestMethod `
            -Uri "$serverUrl/api/v1/hooks/evaluate" `
            -Method Post `
            -Headers $headers `
            -Body $payload `
            -TimeoutSec $timeout

        Write-Log "response: $($response | ConvertTo-Json -Depth 5 -Compress)"
    } catch {
        Write-Log "request failed: $_"
        if ($failPolicy -eq "closed") {
            Write-Log "fail_policy=closed -> deny"
            Send-Decision "deny"
        }
        exit 0
    }

    $decision = if ($response.decision) { $response.decision } else { "ask" }
    Write-Log "decision: $decision"

    if ($decision -eq "allow") {
        Send-Decision "allow"
    } elseif ($decision -eq "deny") {
        Send-Decision "deny"
    } else {
        Write-Log "decision=ask -> no output"
    }

    exit 0
}

Main
