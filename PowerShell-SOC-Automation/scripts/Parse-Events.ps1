<#
.SYNOPSIS
    Parse raw Windows Event Log JSON files into structured CSV files.
.DESCRIPTION
    - Reads raw logs from data/raw_logs
    - Filters only relevant Event IDs defined in event_ids.csv
    - Saves parsed logs to data/parsed_logs
#>

# --- Directories ---
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir   = Split-Path $scriptDir -Parent
$configDir = Join-Path $rootDir "Config"
$dataDir   = Join-Path $rootDir "Data"
$rawDir    = Join-Path $dataDir "raw_logs"
$parsedDir = Join-Path $dataDir "parsed_logs"
$logFile   = Join-Path $rootDir "Logs\script_execution.log"

# --- Logging ---
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts [$Level] $Message" | Out-File -Append -Encoding utf8 -FilePath $logFile
    Write-Host "$ts [$Level] $Message"
}

Write-Log "==================== Parse-Events.ps1 Started ===================="

# --- Load config ---
try {
    $settingsPath = Join-Path $configDir "settings.json"
    $config = Get-Content $settingsPath -Raw | ConvertFrom-Json
    Write-Log "Loaded settings.json successfully."
} catch {
    Write-Log "Failed to load settings.json: $($_.Exception.Message)" "ERROR"
    exit 1
}

# --- Load Event IDs ---
$eventIdFile = Join-Path $configDir "event_ids.csv"
if (-not (Test-Path $eventIdFile)) {
    Write-Log "event_ids.csv not found at $eventIdFile" "ERROR"
    exit 1
}
$eventMap = Import-Csv $eventIdFile | Group-Object -Property EventID -AsHashTable

# --- Ensure parsed_logs directory exists ---
if (-not (Test-Path $parsedDir)) {
    New-Item -ItemType Directory -Force -Path $parsedDir | Out-Null
}

# --- Process each raw log file ---
$rawFiles = Get-ChildItem -Path $rawDir -Filter "*.json" -ErrorAction SilentlyContinue
if ($rawFiles.Count -eq 0) {
    Write-Log "No raw log files found in $rawDir" "WARNING"
    exit 0
}

$parsedEvents = @()
foreach ($file in $rawFiles) {
    try {
        $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
        foreach ($event in $json) {
            if ($null -ne $event.Id -and $eventMap.ContainsKey($event.Id)) {
                $parsedEvents += [PSCustomObject]@{
                    TimeCreated = $event.TimeCreated
                    EventID     = $event.Id
                    Level       = $event.LevelDisplayName
                    Provider    = $event.ProviderName
                    Message     = $event.Message -replace "`r`n", " "
                    Computer    = $event.MachineName
                }
            }
        }
        Write-Log "Parsed $($parsedEvents.Count) matching events from $($file.Name)"
    } catch {
        Write-Log "Failed to parse $($file.Name): $($_.Exception.Message)" "ERROR"
    }
}

if ($parsedEvents.Count -gt 0) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outFile = Join-Path $parsedDir "parsed_events_$timestamp.csv"
    $parsedEvents | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8
    Write-Log "Saved parsed events to $outFile"
} else {
    Write-Log "No matching events found. Parsed logs remain empty." "WARNING"
}

Write-Log "==================== Parse-Events.ps1 Completed ===================="
