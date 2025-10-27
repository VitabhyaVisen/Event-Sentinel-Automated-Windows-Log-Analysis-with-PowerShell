<#
.SYNOPSIS
    Generate HTML report from parsed log CSV files.
.DESCRIPTION
    - Aggregates parsed logs from data/parsed_logs
    - Generates summary metrics and an HTML report
#>

# --- Directory setup ---
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir   = Split-Path $scriptDir -Parent
$dataDir   = Join-Path $rootDir "Data"
$parsedDir = Join-Path $dataDir "parsed_logs"
$reportsDir = Join-Path $dataDir "reports"
$logFile   = Join-Path $rootDir "Logs\script_execution.log"

# --- Logging ---
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts [$Level] $Message" | Out-File -Append -Encoding utf8 -FilePath $logFile
    Write-Host "$ts [$Level] $Message"
}

Write-Log "==================== Generate-Reports.ps1 Started ===================="

# --- Create report folder if missing ---
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Force -Path $reportsDir | Out-Null
}

# --- Load latest parsed log ---
$latestParsed = Get-ChildItem -Path $parsedDir -Filter "parsed_events_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $latestParsed) {
    Write-Log "No parsed CSV files found in $parsedDir" "ERROR"
    exit 1
}

$events = Import-Csv $latestParsed.FullName
if ($events.Count -eq 0) {
    Write-Log "Parsed log file $($latestParsed.Name) is empty." "ERROR"
    exit 1
}

# --- Build summary stats ---
$totalEvents = $events.Count
$byEventID = $events | Group-Object -Property EventID | Sort-Object Count -Descending
$byLevel = $events | Group-Object -Property Level | Sort-Object Count -Descending

# --- Build HTML report ---
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportName = "SOC_Report_$timestamp.html"
$reportPath = Join-Path $reportsDir $reportName

$html = @"
<html>
<head>
<title>SOC Report - $timestamp</title>
<style>
body { font-family: Arial; margin: 20px; }
h1 { color: #2E8B57; }
table { border-collapse: collapse; width: 80%; margin-bottom: 20px; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #4CAF50; color: white; }
tr:nth-child(even) { background-color: #f2f2f2; }
</style>
</head>
<body>
<h1>SOC Event Summary - $timestamp</h1>
<p><strong>Total Events Parsed:</strong> $totalEvents</p>

<h2>Events by ID</h2>
<table>
<tr><th>Event ID</th><th>Count</th></tr>
"@

foreach ($g in $byEventID) {
    $html += "<tr><td>$($g.Name)</td><td>$($g.Count)</td></tr>"
}

$html += @"
</table>
<h2>Events by Level</h2>
<table>
<tr><th>Level</th><th>Count</th></tr>
"@

foreach ($g in $byLevel) {
    $html += "<tr><td>$($g.Name)</td><td>$($g.Count)</td></tr>"
}

$html += @"
</table>
</body>
</html>
"@

$html | Out-File -FilePath $reportPath -Encoding utf8
Write-Log "Report generated successfully at $reportPath"

Write-Log "==================== Generate-Reports.ps1 Completed ===================="
