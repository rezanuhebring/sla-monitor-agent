# ==============================================================================
# SLA Monitor - Agent Setup Script for Windows (with Dependency Installation)
# ==============================================================================
# This script MUST be run with Administrator privileges.

# --- Pre-run Check ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as an Administrator." -ForegroundColor Red
    Write-Host "Please right-click the script and select 'Run as administrator'." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

# --- Helper Function ---
function Ensure-Dependency {
    param(
        [string]$Command,
        [string]$WingetPackageId
    )
    
    Write-Host "Checking for dependency: $Command..."
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Host "$Command is already installed." -ForegroundColor Green
        return
    }
    
    Write-Host "$Command not found. Attempting to install..." -ForegroundColor Yellow
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Using winget to install $WingetPackageId..." -ForegroundColor Cyan
        winget install --id $WingetPackageId -e --source winget --accept-package-agreements --accept-source-agreements
        
        # Special PATH handling for Python
        if ($Command -eq "python") {
            Write-Host "Python installed. You may need to RESTART this PowerShell session for it to be found in your PATH." -ForegroundColor Yellow
            Write-Host "Please close and re-open this Administrator PowerShell window and run the script again." -ForegroundColor Yellow
            Read-Host "Press Enter to exit"
            exit
        }

        # Re-check after install
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            Write-Host "$Command installed successfully." -ForegroundColor Green
        } else {
            Write-Host "Winget installation of $Command may have finished, but the command is not in the PATH." -ForegroundColor Red
            Write-Host "Please restart your terminal and try again. If the problem persists, install manually." -ForegroundColor Red
            Read-Host "Press Enter to exit"
            exit
        }
    } else {
        Write-Host "Error: winget package manager not found." -ForegroundColor Red
        Write-Host "Please install '$Command' manually and re-run this script." -ForegroundColor Yellow
        if ($Command -eq "git") { Write-Host "Download from: https://git-scm.com/download/win" }
        if ($Command -eq "python") { Write-Host "Download from: https://www.python.org/downloads/windows/" }
        Read-Host "Press Enter to exit"
        exit
    }
}


# --- Main Script ---
Write-Host "Starting SLA Monitor Agent Setup..." -ForegroundColor Green
Write-Host "------------------------------------"

# 1. Check and Install Dependencies
Ensure-Dependency -Command "git" -WingetPackageId "Git.Git"
Ensure-Dependency -Command "python" -WingetPackageId "Python.Python.3"

# 2. Clone Repository (if not already in it)
$ProjectDir = Get-Location
if (-not (Test-Path -Path ".git")) {
    $RepoUrl = Read-Host "Please enter the git clone URL for your sla-monitor-agent repository"
    Write-Host "Cloning agent repository into a new folder..."
    git clone $RepoUrl "sla-monitor-agent"
    cd "sla-monitor-agent"
    $ProjectDir = Get-Location
}

# 3. Create Python Virtual Environment & Install Packages
Write-Host "Setting up Python environment..."
if (-not (Test-Path -Path "venv")) { python -m venv venv }
& ".\venv\Scripts\pip.exe" install -r requirements.txt
Write-Host "Python packages installed." -ForegroundColor Green

# 4. Configure config.ini
Write-Host "Configuring the agent..." -ForegroundColor Cyan
$ServerIp = Read-Host "Enter the IP address of your central monitoring server"
$AgentId = Read-Host "Enter a unique ID for this agent (e.g., 'internal-office-pc')"
$ApiUrl = "http://${ServerIp}:8000/api/submit"
(Get-Content -Path "config.ini.example") -replace 'YOUR_API_URL', $ApiUrl -replace 'YOUR_AGENT_ID', $AgentId | Set-Content -Path "config.ini"
Write-Host "config.ini created successfully." -ForegroundColor Green

# 5. Final Instructions (same as before)
$PythonExecutable = (Resolve-Path ".\venv\Scripts\python.exe").Path
$MainScriptPath = (Resolve-Path ".\main.py").Path
Write-Host "`nTest setup: `"$PythonExecutable`" `"$MainScriptPath`"" -ForegroundColor Yellow
Write-Host "`nTo run automatically every 5 minutes, run this command in this same Administrator PowerShell:" -ForegroundColor Yellow
Write-Host "Register-ScheduledTask -Action (New-ScheduledTaskAction -Execute `"$PythonExecutable`" -Argument `"$MainScriptPath`" -WorkingDirectory `"$ProjectDir`") -Trigger (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 9999)) -TaskName 'SLA_Monitor_Agent' -Description 'Runs the Internet SLA monitor agent.' -RunLevel Highest -Force" -ForegroundColor Cyan