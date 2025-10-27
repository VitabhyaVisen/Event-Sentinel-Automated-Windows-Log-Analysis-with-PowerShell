# Event-Sentinel-Automated-Windows-Log-Analysis-with-PowerShell
Event Sentinel – Automated Windows Log Analysis with PowerShell: Built a PowerShell script to automate collection and parsing of Windows event logs from Security, System, and Application channels. Extracted key Event IDs (4624, 4625, 4688, etc.) and generated CSV reports to enhance SOC visibility and streamline threat detection.

#🧠 Overview

Event Sentinel is a PowerShell-based automation tool designed to collect, parse, and analyze critical Windows Event Logs. It helps security analysts and SOC teams streamline log investigation by automatically exporting and parsing important event data such as logon attempts, process creation, and system activities.

This project demonstrates intermediate-level PowerShell scripting skills, covering automation, error handling, and Windows event management.

#⚙️ Features

Automated Log Collection from Security, System, and Application channels.
Exports Logs into structured .evtx and .csv formats.
Parses Critical Event IDs:
4624 – Successful Logon
4625 – Failed Logon
4688 – Process Creation
4720 – User Account Creation
Error Handling & Access Validation for smooth execution.
CSV Report Generation for easy visualization or SIEM ingestion.

#🚀 How to Run

1. Open PowerShell as Administrator.
2. Clone the repository or copy the scripts to your desired directory.
3. Run the scripts in order:
     .\Collect-Logs.ps1
     .\Parse-Events.ps1
     .\Generate-Report.ps1
4. The final CSV report will be available inside the output/ folder.

#⚡ Requirements

Windows 10 or later
PowerShell 5.1+
Administrative privileges to access Security logs

#🧩 Use Cases

Security Operations Center (SOC) investigations
Incident Response and threat hunting
Windows system audit and compliance reviews
Log analysis automation

#📈 Future Enhancements

Integrate with Splunk or Microsoft Sentinel for real-time dashboarding.
Add email notifications for critical alerts.
Introduce PowerShell GUI for easier execution.
Automate scheduled log collection via Task Scheduler.


#🧑‍💻 Author
Vitabhya Visen
Cybersecurity & PowerShell Automation Enthusiast
