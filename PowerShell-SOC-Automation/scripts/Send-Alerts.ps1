<#
.SYNOPSIS
    Sends SOC alert emails based on detections found in parsed logs or reports.

.DESCRIPTION
    This script checks for recent detections stored in parsed logs or reports,
    compares them against thresholds in settings.json, and sends an email
    alert through SMTP if anomalies or critical events are found.

.NOTES
    Author: Vitabhya Visen (SOC Automation Project)
    Version: 1.0
#>

param (
    [string]$SettingsPath = "../Config/settings.json",
    [string]$ParsedLogDir = "../data/parsed_logs",
    [string]$ReportDir = "../data/reports"
)

# --- Load Config ---
try {
    $config = Get-Content $SettingsPath | ConvertFrom-Json
    Write-Host "[+] Configuration loaded successfully."
}
catch {
    Write-Error "[-] Failed to read configuration file. $_"
    exit 1
}

# --- Define Paths ---
$logFile = $config.paths.scriptLog
$alertEnabled = $config.alerting.enabled
$smtpServer = $config.alerting.smtpServer
$smtpPort = $config.alerting.smtpPort
$emailFrom = $config.alerting.emailFrom
$emailTo = $config.alerting.emailTo
$emailUsername = $config.alerting.emailUsername
$reportFormat = $config.reporting.reportFormat
$reportFiles = Get-ChildItem -Path $ReportDir -Filter "*.$reportFormat" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending

if (-not $alertEnabled) {
    Write-Host "[i] Email alerting is disabled in settings.json. Skipping alert step."
    exit 0
}

if (-not $reportFiles) {
    Write-Host "[!] No reports found in $ReportDir. Nothing to send."
    exit 0
}

# --- Select Latest Report ---
$latestReport = $reportFiles[0].FullName
Write-Host "[+] Latest report found: $($latestReport)"

# --- Check for Detection Keywords ---
$detections = @()
try {
    $content = Get-Content $latestReport -Raw
    if ($content -match "Critical|High|Brute Force|Failed Logon|Suspicious|Privilege Escalation") {
        $detections += "Critical or Suspicious Activity Detected"
    }
}
catch {
    Write-Warning "Unable to analyze report content. $_"
}

if ($detections.Count -eq 0) {
    Write-Host "[i] No critical detections found. No alert will be sent."
    exit 0
}

# --- Compose Email Body ---
$emailBody = @"
<html>
<body style='font-family:Segoe UI;'>
    <h2 style='color:#d9534f;'>SOC Alert - Critical Activity Detected</h2>
    <p>The following detections have been identified by the SOC automation system:</p>
    <ul>
"@
foreach ($det in $detections) {
    $emailBody += "        <li>$det</li>`n"
}
$emailBody += @"
    </ul>
    <p>Refer to the attached report for more details.</p>
    <p><b>Timestamp:</b> $(Get-Date)</p>
</body>
</html>
"@

# --- Send Email via SMTP ---
try {
    $securePwd = Read-Host "Enter password for $emailUsername" -AsSecureString
    $cred = New-Object System.Management.Automation.PSCredential ($emailUsername, $securePwd)
    Send-MailMessage -From $emailFrom -To $emailTo -Subject "⚠ SOC Alert: Critical Detections Found" `
        -BodyAsHtml -Body $emailBody -Attachments $latestReport `
        -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential $cred

    "[+] Alert email sent successfully at $(Get-Date)" | Tee-Object -FilePath $logFile -Append
    Write-Host "[+] Alert email sent successfully."
}
catch {
    Write-Error "[-] Failed to send email alert. $_"
}
