# Auto-Elevate to Administrator
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { $([scriptblock]::Create($MyInvocation.MyCommand.Definition)) }`"" -Verb RunAs
    Exit
}

# Set Background to Black
$Host.UI.RawUI.BackgroundColor = "Black"
Clear-Host

# Force Window Size
try {
    $Width = 62
    $Height = 17
    $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($Width, 9999)
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size($Width, $Height)
} catch {}
Write-Host "$([char]27)[8;17;62t"

function Invoke-UniversalClean {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "    QuantumClean Deep-Purge                        " -ForegroundColor Gray
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

    Write-Host "[1/3] Scanning system for known and unknown app caches..." -ForegroundColor Gray
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

    Write-Host "[2/3] Executing High-Speed Purge with Live Timer..." -ForegroundColor Gray
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

    Write-Host "`n[3/3] Flushing DNS Cache..." -ForegroundColor Gray
    Clear-DnsClientCache
    Write-Host "    [+] DNS Cache Cleared.`n" -ForegroundColor Green
    Pause
}

function Invoke-PerformanceOptimization {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "       NexusPrime Core-Optimizer                   " -ForegroundColor Gray
    Write-Host "===================================================`n" -ForegroundColor Gray

    $Stages = @(
        @{ Name = "[1/5] Flushing DNS & Resetting Network"; Script = { ipconfig /flushdns | Out-Null; netsh winsock reset | Out-Null } },
        @{ Name = "[2/5] Repairing System Files (DISM & SFC)"; Script = { DISM.exe /Online /Cleanup-Image /RestoreHealth /LimitAccess | Out-Null; sfc /scannow | Out-Null } },
        @{ Name = "[3/5] Cleaning Component Store (WinSxS)"; Script = { DISM.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null } },
        @{ Name = "[4/5] Optimizing Storage Drives"; Script = { defrag /C /O | Out-Null } },
        @{ Name = "[5/5] Rebuilding Search Index Cache"; Script = { Stop-Service "Windows Search" -Force -ErrorAction SilentlyContinue; Remove-Item "$env:ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb" -Force -ErrorAction SilentlyContinue; Start-Service "Windows Search" -ErrorAction SilentlyContinue } }
    )

    $TotalSw = [System.Diagnostics.Stopwatch]::StartNew()

    foreach ($Stage in $Stages) {
        Write-Host "$($Stage.Name)..." -ForegroundColor Gray
        
        $Job = Start-Job -ScriptBlock $Stage.Script
        $StageSw = [System.Diagnostics.Stopwatch]::StartNew()

        while ($Job.State -eq "Running") {
            $Elapsed = $StageSw.Elapsed
            $TimeString = "{0:D2}:{1:D2}:{2:D2}" -f $Elapsed.Hours, $Elapsed.Minutes, $Elapsed.Seconds
            Write-Host "`r    -> Running time: $TimeString" -NoNewline -ForegroundColor Gray
            Start-Sleep -Seconds 1
        }

        $StageSw.Stop()
        $FinalElapsed = "{0:D2}:{1:D2}:{2:D2}" -f $StageSw.Elapsed.Hours, $StageSw.Elapsed.Minutes, $StageSw.Elapsed.Seconds
        Write-Host "`r    [+] Finished in: $FinalElapsed                    " -ForegroundColor Green
        Remove-Job $Job
        Write-Host ""
    }

    $TotalSw.Stop()
    $TotalElapsed = "{0:D2}:{1:D2}:{2:D2}" -f $TotalSw.Elapsed.Hours, $TotalSw.Elapsed.Minutes, $TotalSw.Elapsed.Seconds
    Write-Host "---------------------------------------------------" -ForegroundColor Gray
    Write-Host "Done! Total Optimization Time: $TotalElapsed" -ForegroundColor Gray
    Pause
}

function Invoke-ExternalTool1 {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://get.activated.win | iex; Pause`""
    Write-Host "Microsoft Office & Windows Activator launched in a new window." -ForegroundColor Gray
    Start-Sleep -Seconds 2
}

function Invoke-ExternalTool2 {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iex(irm is.gd/idm_reset); Pause`""
    Write-Host "Internet Download Manager Activator launched in a new window." -ForegroundColor Gray
    Start-Sleep -Seconds 2
}

# Interactive Menu Loop
do {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "       11UNKNOWN59 SYSTEM MAINTENANCE SUITE        " -ForegroundColor Gray
    Write-Host "===================================================`n" -ForegroundColor Gray
    Write-Host " [1] QuantumClean Deep-Purge" -ForegroundColor Gray
    Write-Host "     (Universal Dynamic Cache Discovery & Purge)" -ForegroundColor DarkGray
    Write-Host " [2] NexusPrime Core-Optimizer" -ForegroundColor Gray
    Write-Host "     (Windows Performance Optimization)" -ForegroundColor DarkGray
    Write-Host " [3] AetherFlush Network-Reset" -ForegroundColor Gray
    Write-Host "     (Flush Network & DNS Cache Only)" -ForegroundColor DarkGray
    Write-Host " [4] Run External Tool 1 (MAS Activation)" -ForegroundColor Gray
    Write-Host " [5] Run External Tool 2 (is.gd)" -ForegroundColor Gray
    Write-Host " [Q] Quit" -ForegroundColor DarkRed
    Write-Host "===================================================" -ForegroundColor Gray
    
    $Selection = Read-Host "Select an option"

    switch ($Selection.ToUpper()) {
        "1" { Invoke-UniversalClean }
        "2" { Invoke-PerformanceOptimization }
        "3" { Clear-DnsClientCache; Write-Host "AetherFlush: DNS Cache Cleared!" -ForegroundColor Gray; Start-Sleep -Seconds 2 }
        "4" { Invoke-ExternalTool1 }
        "5" { Invoke-ExternalTool2 }
        "Q" { Write-Host "Exiting..."; Exit }
    }
} while ($true)
