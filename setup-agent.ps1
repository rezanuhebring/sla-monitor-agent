# ==============================================================================
# SLA Monitor - Agent Setup Script for Windows
# ==============================================================================
$RepoUrl = "https://github.com/$(git config --get remote.origin.url | Select-String -Pattern '(?<=github.com\/).*' | ForEach-Object { $_.Matches.Value -replace '\.git$','' })"
$ProjectDir = "." # Install in the current directory

function Check-Dependency { param ($Command)
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        Write-Host "Error: Dependency '$Command' not found." -ForegroundColor Red; exit 1
    }
}

Write-Host "Starting SLA Monitor Agent Setup..." -ForegroundColor Green
Check-Dependency "git"; Check-Dependency "python"

cd $ProjectDir
if (-not (Test-Path -Path "venv")) { python -m venv venv }
& ".\venv\Scripts\pip.exe" install -r requirements.txt

Write-Host "Configuring the agent..." -ForegroundColor Cyan
$ServerIp = Read-Host "Enter the IP address of your central monitoring server"
$AgentId = Read-Host "Enter a unique ID for this agent (e.g., 'internal-office-pc')"
$ApiUrl = "http://${ServerIp}:8000/api/submit"

(Get-Content -Path "config.ini.example") -replace 'YOUR_API_URL', $ApiUrl -replace 'YOUR_AGENT_ID', $AgentId | Set-Content -Path "config.ini"
Write-Host "config.ini created successfully." -ForegroundColor Green

$PythonExecutable = (Resolve-Path ".\venv\Scripts\python.exe").Path
$MainScriptPath = (Resolve-Path ".\main.py").Path

Write-Host "`nTest setup: $PythonExecutable $MainScriptPath`n" -ForegroundColor Yellow
Write-Host "To run automatically every 5 minutes, open PowerShell as an ADMINISTRATOR and run:" -ForegroundColor Yellow
Write-Host "Register-ScheduledTask -Action (New-ScheduledTaskAction -Execute '$PythonExecutable' -Argument '$MainScriptPath' -WorkingDirectory '$(Get-Location)') -Trigger (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 9999)) -TaskName 'SLA_Monitor_Agent' -Description 'Runs the Internet SLA monitor agent.' -RunLevel Highest -Force" -ForegroundColor Cyan