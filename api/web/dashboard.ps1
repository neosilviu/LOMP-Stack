# LOMP Stack v3.0 - Web Dashboard Launcher (PowerShell)
# Launch the web-based API administration dashboard

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "install", "status")]
    [string]$Action = "start",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 5001,
    
    [Parameter(Mandatory=$false)]
    [string]$HostAddress = "0.0.0.0"
)

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ApiDir = Split-Path -Parent $ScriptDir
$RequirementsFile = Join-Path $ScriptDir "requirements.txt"
$DashboardScript = Join-Path $ScriptDir "admin_dashboard.py"
$PidFile = Join-Path $ScriptDir "dashboard.pid"

# Colors for output
function Write-Info {
    param([string]$Message)
    Write-Host "[WEB-DASHBOARD] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[WEB-DASHBOARD] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WEB-DASHBOARD] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[WEB-DASHBOARD] $Message" -ForegroundColor Red
}

#########################################################################
# Install Dependencies
#########################################################################
function Install-Dependencies {
    Write-Info "Installing web dashboard dependencies..."
    
    # Check if Python is installed
    try {
        $pythonVersion = python --version 2>$null
        Write-Info "Found Python: $pythonVersion"
    }
    catch {
        Write-Error "Python is not installed or not in PATH"
        Write-Info "Please install Python 3.7+ and try again"
        exit 1
    }
    
    # Check if pip is available
    try {
        pip --version | Out-Null
        Write-Info "pip is available"
    }
    catch {
        Write-Error "pip is not available"
        Write-Info "Please install pip and try again"
        exit 1
    }
    
    # Create requirements.txt if it doesn't exist
    if (!(Test-Path $RequirementsFile)) {
        Write-Info "Creating requirements.txt..."
        @"
Flask==2.3.3
Flask-Limiter==3.5.0
Werkzeug==2.3.7
Jinja2==3.1.2
MarkupSafe==2.1.3
"@ | Out-File -FilePath $RequirementsFile -Encoding UTF8
    }
    
    # Install Python packages
    Write-Info "Installing Python packages..."
    try {
        pip install -r $RequirementsFile
        Write-Success "Dependencies installed successfully"
    }
    catch {
        Write-Error "Failed to install dependencies: $_"
        exit 1
    }
}

#########################################################################
# Start Dashboard
#########################################################################
function Start-Dashboard {
    Write-Info "Starting LOMP Stack Web Dashboard..."
    
    # Check if already running
    if (Test-Path $PidFile) {
        $processId = Get-Content $PidFile -ErrorAction SilentlyContinue
        if ($processId -and (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
            Write-Warning "Dashboard is already running (PID: $processId)"
            Write-Info "Dashboard URL: http://localhost:$Port"
            return
        }
        else {
            # Remove stale PID file
            Remove-Item $PidFile -ErrorAction SilentlyContinue
        }
    }
    
    # Create required directories
    $configDir = Join-Path $ApiDir "config"
    $logsDir = Join-Path $ApiDir "logs"
    $authDir = Join-Path $ApiDir "auth"
    
    if (!(Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    if (!(Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }
    if (!(Test-Path $authDir)) { New-Item -ItemType Directory -Path $authDir -Force | Out-Null }
    
    # Set environment variables
    $env:FLASK_ENV = "development"
    $env:DASHBOARD_PORT = $Port
    $env:DASHBOARD_HOST = $HostAddress
    
    # Start the dashboard
    try {
        Write-Info "Starting dashboard on ${HostAddress}:${Port}..."
        $process = Start-Process -FilePath "python" -ArgumentList $DashboardScript -PassThru -WindowStyle Hidden
        
        # Save PID
        $process.Id | Out-File -FilePath $PidFile -Encoding UTF8
        
        # Wait a moment and check if process is still running
        Start-Sleep -Seconds 2
        if ($process.HasExited) {
            Write-Error "Dashboard failed to start"
            Remove-Item $PidFile -ErrorAction SilentlyContinue
            exit 1
        }
        
        Write-Success "Dashboard started successfully!"
        Write-Info "Dashboard URL: http://localhost:$Port"
        Write-Info "Default Login: admin / admin123"
        Write-Warning "Please change the default password after first login!"
        Write-Info "PID: $($process.Id)"
        
        # Open browser
        try {
            Start-Process "http://localhost:$Port"
        }
        catch {
            Write-Info "Could not open browser automatically"
        }
    }
    catch {
        Write-Error "Failed to start dashboard: $_"
        Remove-Item $PidFile -ErrorAction SilentlyContinue
        exit 1
    }
}

#########################################################################
# Stop Dashboard
#########################################################################
function Stop-Dashboard {
    Write-Info "Stopping LOMP Stack Web Dashboard..."
    
    if (!(Test-Path $PidFile)) {
        Write-Warning "Dashboard is not running (no PID file found)"
        return
    }
    
    $processId = Get-Content $PidFile -ErrorAction SilentlyContinue
    if (!$processId) {
        Write-Warning "Invalid PID file"
        Remove-Item $PidFile -ErrorAction SilentlyContinue
        return
    }
    
    try {
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($process) {
            Stop-Process -Id $processId -Force
            Write-Success "Dashboard stopped (PID: $processId)"
        }
        else {
            Write-Warning "Dashboard process not found (PID: $processId)"
        }
    }
    catch {
        Write-Error "Failed to stop dashboard: $_"
    }
    finally {
        Remove-Item $PidFile -ErrorAction SilentlyContinue
    }
}

#########################################################################
# Check Status
#########################################################################
function Get-DashboardStatus {
    Write-Info "Checking dashboard status..."
    
    if (!(Test-Path $PidFile)) {
        Write-Info "Dashboard is not running"
        return
    }
    
    $processId = Get-Content $PidFile -ErrorAction SilentlyContinue
    if (!$processId) {
        Write-Warning "Invalid PID file"
        Remove-Item $PidFile -ErrorAction SilentlyContinue
        return
    }
    
    try {
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($process) {
            Write-Success "Dashboard is running (PID: $processId)"
            Write-Info "Dashboard URL: http://localhost:$Port"
            Write-Info "Process Name: $($process.ProcessName)"
            Write-Info "Start Time: $($process.StartTime)"
        }
        else {
            Write-Warning "Dashboard process not found (PID: $processId)"
            Remove-Item $PidFile -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to check status: $_"
    }
}

#########################################################################
# Main Execution
#########################################################################

Write-Host ""
Write-Host "LOMP Stack v3.0 - Web Administration Dashboard" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta
Write-Host ""

switch ($Action.ToLower()) {
    "install" {
        Install-Dependencies
    }
    "start" {
        Install-Dependencies
        Start-Dashboard
    }
    "stop" {
        Stop-Dashboard
    }
    "status" {
        Get-DashboardStatus
    }
    default {
        Write-Host "Usage: .\dashboard.ps1 [start|stop|install|status]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Cyan
        Write-Host "  start   - Install dependencies and start dashboard" -ForegroundColor White
        Write-Host "  stop    - Stop the dashboard" -ForegroundColor White
        Write-Host "  install - Install dependencies only" -ForegroundColor White
        Write-Host "  status  - Check dashboard status" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Cyan
        Write-Host "  .\dashboard.ps1 start" -ForegroundColor White
        Write-Host "  .\dashboard.ps1 -Action start -Port 8080" -ForegroundColor White
        Write-Host "  .\dashboard.ps1 stop" -ForegroundColor White
    }
}
