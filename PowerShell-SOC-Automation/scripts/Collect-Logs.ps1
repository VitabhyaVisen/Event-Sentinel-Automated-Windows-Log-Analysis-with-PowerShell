<#
.SYNOPSIS
    Collects Windows Event Logs from multiple hosts and stores them in Data\raw_logs.
#>

# ==================== Initialization ====================
# Use MyInvocation.Path for robust resolution
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path $ScriptDir -Parent
$SettingsPath = Join-Path $ProjectRoot "Config\settings.json"

# Validate settings.json
if (-not (Test-Path $SettingsPath)) {
    Write-Host "[ERROR] settings.json not found at $SettingsPath" -ForegroundColor Red
    exit 1
}

$Settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json

# Paths from settings.json (fall back to defaults if missing)
$LogFile    = Join-Path $ProjectRoot ($Settings.paths.scriptLog   -replace '/', '\')
$HostList   = Join-Path $ProjectRoot ($Settings.paths.hostList   -replace '/', '\')
$RawLogsDir = Join-Path $ProjectRoot ($Settings.paths.rawLogDir  -replace '/', '\')

# Ensure directories exist
$logDir = Split-Path $LogFile -Parent
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $RawLogsDir)) { New-Item -Path $RawLogsDir -ItemType Directory -Force | Out-Null }

# Log helper
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$ts [$Level] $Message"
    Add-Content -Path $LogFile -Value $entry
    Write-Host $entry
}

Write-Log "==================== Collect-Logs.ps1 Started ===================="
Write-Log "Using Settings: $SettingsPath"
Write-Log "Using Host list: $HostList"
Write-Log "Raw logs dir: $RawLogsDir"
Write-Log "Script log: $LogFile"

# ==================== Load hosts ====================
if (-not (Test-Path $HostList)) {
    Write-Log "host_list.txt not found at $HostList" "ERROR"
    exit 1
}

$Hosts = Get-Content $HostList | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
if ($Hosts.Count -eq 0) {
    Write-Log "No hosts defined in host_list.txt" "ERROR"
    exit 1
}

# ==================== Collect logs ====================
foreach ($Target in $Hosts) {
    try {
        # create a safe filename from host value
        $SafeName = ($Target -replace '[^a-zA-Z0-9\-]', '_')
        $OutputFile = Join-Path $RawLogsDir ("{0}_Security.evtx" -f $SafeName)

        Write-Log "Collecting Security log from $Target ..."

        # Local vs remote export
        if ($Target -ieq "localhost" -or $Target -ieq $env:COMPUTERNAME) {
            wevtutil epl Security $OutputFile /ow:true
        } else {
            # Use remote export; requires permissions and remoting / proper credentials
            wevtutil epl Security $OutputFile /ow:true /r:$Target /u:$env:USERNAME /p:$env:USERDOMAIN
        }

        if (Test-Path $OutputFile) {
            $countInfo = ""  # optional: could inspect .evtx size or convert to json later
            Write-Log "Successfully exported log for $Target -> $OutputFile"
        } else {
            Write-Log "No event file created for $Target (maybe no events or permission issue)" "WARNING"
        }
    } catch {
        Write-Log "Failed to collect logs from ${Target}: $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "==================== Collect-Logs.ps1 Completed ===================="
