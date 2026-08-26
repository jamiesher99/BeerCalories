# Starts the Connect IQ simulator if it isn't already running, then waits until
# it is accepting connections on port 1234.
#
# The Monkey C extension does NOT launch the simulator - its debug adapter only
# probes for an already-running one (ShellUtils.findSimulatorPort) and pushes
# the .prg into it. With no simulator up, F5 builds and then quietly does
# nothing. This runs as a preLaunchTask so F5 works from cold.
$ErrorActionPreference = "Stop"

$sdk = Get-ChildItem "$env:APPDATA\Garmin\ConnectIQ\Sdks" -Directory |
       Sort-Object Name -Descending | Select-Object -First 1
if (-not $sdk) { Write-Error "No Connect IQ SDK found."; exit 1 }

if (-not (Get-Process simulator -ErrorAction SilentlyContinue)) {
    Write-Host "Starting Connect IQ simulator..."
    Start-Process "$($sdk.FullName)\bin\simulator.exe"
} else {
    Write-Host "Simulator already running."
}

foreach ($i in 1..60) {
    try {
        $c = New-Object Net.Sockets.TcpClient
        $c.Connect("127.0.0.1", 1234)
        $c.Close()
        Write-Host "Simulator ready on port 1234."
        exit 0
    } catch {
        Start-Sleep -Seconds 1
    }
}

Write-Error "Simulator never opened port 1234."
exit 1
