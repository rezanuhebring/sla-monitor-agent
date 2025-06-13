# SLA Monitor - Agent

This is the client-side agent for the distributed internet quality monitor. It performs network tests (speed, ping, jitter, packet loss) and sends the results to a central server.

## Quick Setup on a Windows Machine

1.  **Prerequisites:** Ensure `git` and `python` are installed and in your system PATH.
2.  Clone this repository:
    ```powershell
    git clone https://github.com/your-username/sla-monitor-agent.git
    cd sla-monitor-agent
    ```
3.  Run the setup script in PowerShell:
    ```powershell
    .\setup-agent.ps1
    ```
4.  Follow the prompts to enter your server's IP address and a unique ID for this agent.
5.  The script will provide a final command to create a Windows Scheduled Task to run the agent automatically.