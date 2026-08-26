<#
    Build BeerCalories and run it in the Connect IQ simulator.

    Usage:  .\run-sim.ps1 fr265
            .\run-sim.ps1            # defaults to fenixe
            .\run-sim.ps1 -List      # show every device this app supports
#>
param(
    [string]$Device = "fenixe",
    [switch]$List
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

# Newest installed SDK
$sdk = Get-ChildItem "$env:APPDATA\Garmin\ConnectIQ\Sdks" -Directory |
       Sort-Object Name -Descending | Select-Object -First 1
if (-not $sdk) { throw "No Connect IQ SDK found. Install one with the SDK Manager." }

$supported = Select-String -Path "$root\manifest.xml" -Pattern 'iq:product id="([^"]+)"' -AllMatches |
             ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value }

if ($List) {
    Write-Host "$($supported.Count) supported devices:"
    $supported | Sort-Object | Format-Wide -Column 6 -Property { $_ }
    exit 0
}

if ($supported -notcontains $Device) {
    throw "'$Device' is not in manifest.xml. Run '.\run-sim.ps1 -List' to see the options."
}

if (-not (Get-Process simulator -ErrorAction SilentlyContinue)) {
    Write-Host "Starting simulator..."
    Start-Process "$($sdk.FullName)\bin\simulator.exe"
}

# monkeydo needs the simulator listening on 1234. A fixed sleep is not enough -
# a cold start can take 20s+, and monkeydo exits quietly if it connects too
# early, which looks exactly like "nothing happened".
Write-Host -NoNewline "Waiting for simulator"
$ready = $false
foreach ($i in 1..60) {
    try {
        $c = New-Object Net.Sockets.TcpClient
        $c.Connect("127.0.0.1", 1234)
        $c.Close()
        $ready = $true
        break
    } catch {
        Write-Host -NoNewline "."
        Start-Sleep -Seconds 1
    }
}
Write-Host ""
if (-not $ready) {
    throw "Simulator never opened port 1234. Kill any stuck simulator.exe and retry."
}

$key = "$env:USERPROFILE\.Garmin\ConnectIQ\developer_key.der"
$prg = "$root\bin\BeerCalories-$Device.prg"

Write-Host "Building for $Device..."
& "$($sdk.FullName)\bin\monkeyc.bat" -f "$root\monkey.jungle" -o $prg -y $key -d $Device
if ($LASTEXITCODE -ne 0) { throw "Build failed." }

Write-Host "Launching on $Device - stays attached while the app runs, Ctrl+C to detach."
& "$($sdk.FullName)\bin\monkeydo.bat" $prg $Device
