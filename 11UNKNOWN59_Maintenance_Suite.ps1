# Auto-Elevate to Administrator
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { $([scriptblock]::Create($MyInvocation.MyCommand.Definition)) }`"" -Verb RunAs
    Exit
}

# Set Background to Black
$Host.UI.RawUI.BackgroundColor = "Black"
Clear-Host

# Resize Window to Fit Menu + Extra Buffer Width
try {
    $Width = 62
    $Height = 12
    $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($Width, 9999)
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size($Width, $Height)
} catch {}

function Invoke-UniversalClean {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "    Universal Dynamic Cache Discovery & Purge      " -ForegroundColor Cyan
    Write-Host "===================================================`n" -ForegroundColor Gray

    $KnownTargets = @(
        "$env:TEMP", "$env:SystemRoot\Temp", "$env:SystemRoot\Prefetch",
        "$env:LocalAppData\Google\Chrome\User Data\*\Cache",
        "$env:LocalAppData\Microsoft\Edge\User Data\*\Cache",
        "$env:LocalAppData\BraveSoftware\Brave-Browser\User Data\*\Cache",
        "$env:AppData\Mozilla\Firefox\Profiles\*\cache2",
        "$env:AppData\Adobe\Common\Media Cache Files",
        "$env:LocalAppData\Adobe\DXMediaCache", "$env:LocalAppData\CapCut\User Data\Cache",
        "$env:LocalAppData\Steam\htmlcache", "$env:LocalAppData\EpicGamesLauncher\Saved\Webcache",
        "$env:LocalAppData\NVIDIA\DXCache", "$env:LocalAppData\AMD\DxCache", "$env:LocalAppData\D3DSCache"
    )

    Write-Host "[1/3] Scanning system for known and unknown app caches..." -ForegroundColor White
    $DiscoveredPaths = [System.Collections.Generic.List[string]]::new()

    foreach ($Target in $KnownTargets) {
        $Resolved = Resolve-Path -Path $Target -ErrorAction SilentlyContinue
        if ($Resolved) { foreach ($Item in $Resolved) { $DiscoveredPaths.Add($Item.Path) } }
    }

    $SearchRoots = @($env:LocalAppData, $env:AppData)
    foreach ($Root in $SearchRoots) {
        if (Test-Path $Root) {
            $GenericCaches = Get-ChildItem -Path $Root -Recurse -Depth 3 -Directory -Filter "*Cache*" -ErrorAction SilentlyContinue | 
                Where-Object { $_.FullName -notmatch "Microsoft\\Windows" }
            foreach ($Folder in $GenericCaches) {
                if (-not $DiscoveredPaths.Contains($Folder.FullName)) { $DiscoveredPaths.Add($Folder.FullName) }
            }
        }
    }

    Write-Host "    [+] Discovered $($DiscoveredPaths.Count) total cache locations.`n" -ForegroundColor Green

    Write-Host "[2/3] Executing High-Speed Purge with Live Timer..." -ForegroundColor White
    $PurgeBlock = [scriptblock]::Create("
        param(`$Targets)
        foreach (`$Path in `$Targets) { Remove-Item -Path `"`$Path\*`" -Recurse -Force -ErrorAction SilentlyContinue }
    ")

    $Job = Start-Job -ScriptBlock $PurgeBlock -ArgumentList (,$DiscoveredPaths)
    $StageSw = [System.Diagnostics.Stopwatch]::StartNew()

    while ($Job.State -eq "Running") {
        $Elapsed = $StageSw.Elapsed
        $TimeString = "{0:D2}:{1:D2}:{2:D2}" -f $Elapsed.Hours, $Elapsed.Minutes, $Elapsed.Seconds
        Write-Host "`r   -> Purging... Active Time: $TimeString" -NoNewline -ForegroundColor Gray
        Start-Sleep -Seconds 1
    }

    $StageSw.Stop()
    $FinalElapsed = "{0:D2}:{1:D2}:{2:D2}" -f $StageSw.Elapsed.Hours, $StageSw.Elapsed.Minutes, $StageSw.Elapsed.Seconds
    Write-Host "`r   [+] Deep Purge Completed in: $FinalElapsed                    " -ForegroundColor Green
    Remove-Job $Job

    Write-Host "`n[3/3] Flushing DNS Cache..." -ForegroundColor White
    Clear-DnsClientCache
    Write-Host "    [+] DNS Cache Cleared.`n" -ForegroundColor Green
    Pause
}

# Interactive Menu Loop
do {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "       11UNKNOWN59 SYSTEM MAINTENANCE SUITE        " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host " [1] Run Universal Search & Clean (Dynamic Deep Clean)" -ForegroundColor White
    Write-Host " [2] Flush Network & DNS Cache Only" -ForegroundColor White
    Write-Host " [Q] Quit" -ForegroundColor DarkRed
    Write-Host "===================================================" -ForegroundColor Gray
    
    $Selection = Read-Host "Select an option"

    switch ($Selection.ToUpper()) {
        "1" { Invoke-UniversalClean }
        "2" { Clear-DnsClientCache; Write-Host "DNS Cleared!" -ForegroundColor Green; Start-Sleep -Seconds 2 }
        "Q" { Write-Host "Exiting..."; Exit }
    }
} while ($true)
