# ==================== Main.ps1 ====================
# SOC Automation Framework (Final Stable Version)

$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigPath = Join-Path $ScriptRoot "Config\settings.json"
$ScriptName = "Main.ps1"

# --- Function to log messages ---
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logDir = Join-Path $ScriptRoot "Logs"
    if (!(Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }
    $logFile = Join-Path $logDir "script_execution.log"
    Add-Content -Path $logFile -Value "$timestamp [$Level] $Message"
}

try {
    Write-Log "==================== $ScriptName Started ===================="

    # --- Load Configuration ---
    if (!(Test-Path $ConfigPath)) {
        throw "Configuration file not found at $ConfigPath"
    }
    $settings = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
    Write-Log "[+] Configuration loaded successfully."

    # --- Ensure Output Directories Exist ---
    $pathsToEnsure = @(
        "Output\raw_logs",
        "Output\parsed_logs",
        "Output\reports\daily",
        "Output\reports\weekly",
        "Output\reports\monthly"
    )
    foreach ($path in $pathsToEnsure) {
        $fullPath = Join-Path $ScriptRoot $path
        if (!(Test-Path $fullPath)) { New-Item -Path $fullPath -ItemType Directory | Out-Null }
    }

    # --- Step 1: Collect Logs ---
    Write-Log "[*] Collecting event logs..."
    & "$ScriptRoot\scripts\Collect-Logs.ps1" -Settings $settings -RootPath $ScriptRoot
    Write-Log "[+] Log collection completed successfully."

    # --- Step 2: Parse Logs ---
    Write-Log "[*] Parsing logs..."
    & "$ScriptRoot\scripts\Parse-Events.ps1" -Settings $settings -RootPath $ScriptRoot
    Write-Log "[+] Log parsing completed successfully."

    # --- Step 3: Generate Reports ---
    Write-Log "[*] Generating reports..."
    & "$ScriptRoot\scripts\Generate-Reports.ps1" -Settings $settings -RootPath $ScriptRoot
    Write-Log "[+] Report generation completed successfully."

    # --- Step 4: Send Alerts (optional) ---
    if ($settings.alerting.enabled -eq $true) {
        Write-Log "[*] Sending alerts..."
        & "$ScriptRoot\scripts\Send-Alerts.ps1" -Settings $settings -RootPath $ScriptRoot
        Write-Log "[+] Alerts sent successfully."
    }
    else {
        Write-Log "[i] Email alerting is disabled in settings.json. Skipping alert step."
    }

    Write-Log "==================== $ScriptName Completed ===================="
}
catch {
    Write-Log "Error running ${ScriptName}: $_" "ERROR"
}
