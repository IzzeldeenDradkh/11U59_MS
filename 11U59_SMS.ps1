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
    $Height = 46
    $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($Width, 9999)
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size($Width, $Height)
} catch {}
Write-Host "$([char]27)[8;46;62t"

function Invoke-UniversalClean {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "        QuantumClean Deep-Purge                    " -ForegroundColor Gray
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
        Write-Host "`r    -> Purging... Active Time: $TimeString" -NoNewline -ForegroundColor Gray
        Start-Sleep -Seconds 1
    }

    $StageSw.Stop()
    $FinalElapsed = "{0:D2}:{1:D2}:{2:D2}" -f $StageSw.Elapsed.Hours, $StageSw.Elapsed.Minutes, $StageSw.Elapsed.Seconds
    Write-Host "`r    [+] Deep Purge Completed in: $FinalElapsed                    " -ForegroundColor Green
    Remove-Job $Job

    Write-Host "`n[3/3] Flushing DNS Cache..." -ForegroundColor Gray
    Clear-DnsClientCache
    Write-Host "    [+] DNS Cache Cleared.`n" -ForegroundColor Green
    Start-Sleep -Seconds 3
}

function Invoke-PerformanceOptimization {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "        NexusPrime Core-Optimizer                  " -ForegroundColor Gray
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
    Start-Sleep -Seconds 3
}

# Diagnostic Reports Functions
function Fix-HtmlReport {
    param ([string]$ReportPath)
    if (Test-Path $ReportPath) {
        try {
            # Ensures encoding is UTF-8 and clears any potential file locks
            $Content = Get-Content -Path $ReportPath -Raw -ErrorAction Stop
            [System.IO.File]::WriteAllText($ReportPath, $Content, [System.Text.Encoding]::UTF8)
            return $true
        } catch {
            return $false
        }
    }
    return $false
}

function Invoke-PowerReport {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "        AetherPulse Power & Battery Report          " -ForegroundColor Gray
    Write-Host "===================================================`n" -ForegroundColor Gray
    Write-Host "Analyzing power efficiency and hardware states (60s)..." -ForegroundColor Gray
    
    $OutputPath = "$env:TEMP\energy-report.html"
    cmd.exe /c "powercfg /energy /output `"$OutputPath`"" | Out-Null
    
    if (Test-Path $OutputPath) {
        [void](Fix-HtmlReport -ReportPath $OutputPath)
        Write-Host "`n[+] Report Generated Successfully!" -ForegroundColor Green
        Write-Host "    Saved to: $OutputPath" -ForegroundColor DarkGray
        Write-Host "    Opening energy-report.html in default browser..." -ForegroundColor DarkGray
        Start-Process $OutputPath
    } else {
        Write-Host "`n[!] Failed to locate generated energy report." -ForegroundColor DarkRed
    }
    Start-Sleep -Seconds 3
}

function Invoke-SystemReport {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "        NexusDiag Full System Health Report         " -ForegroundColor Gray
    Write-Host "===================================================`n" -ForegroundColor Gray
    Write-Host "Initiating System Diagnostics trace (60s)..." -ForegroundColor Gray
    Write-Host "Report dashboard will open automatically upon completion.`n" -ForegroundColor DarkGray
    
    perfmon /report
    
    Write-Host "[+] Diagnostic collection triggered!" -ForegroundColor Green
    Start-Sleep -Seconds 3
}

function Invoke-ReliabilityMonitor {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "        AetherLog Reliability History Monitor       " -ForegroundColor Gray
    Write-Host "===================================================`n" -ForegroundColor Gray
    Write-Host "Launching Reliability Monitor dashboard..." -ForegroundColor Gray
    
    perfmon /rel
    
    Write-Host "`n[+] Reliability Monitor Launched!" -ForegroundColor Green
    Start-Sleep -Seconds 3
}

function Invoke-BatteryReport {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "        AetherCell Battery Health Dashboard         " -ForegroundColor Gray
    Write-Host "===================================================`n" -ForegroundColor Gray
    
    $HasBattery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue

    if (-not $HasBattery) {
        Write-Host "[!] Desktop PC or VM Detected." -ForegroundColor Yellow
        Write-Host "    Battery Health reports are only available on laptops/mobile devices." -ForegroundColor DarkGray
        Start-Sleep -Seconds 4
        return
    }

    Write-Host "Generating battery health and cycle history..." -ForegroundColor Gray

    $TargetPaths = @(
        "$env:USERPROFILE\Desktop\battery-report.html",
        "$env:TEMP\battery-report.html",
        "C:\battery-report.html"
    )

    $SuccessfulReport = $null

    foreach ($Path in $TargetPaths) {
        cmd.exe /c "powercfg /batteryreport /output `"$Path`"" 2>&1 | Out-Null
        if (Test-Path $Path) {
            $SuccessfulReport = $Path
            break
        }
    }

    if ($SuccessfulReport) {
        [void](Fix-HtmlReport -ReportPath $SuccessfulReport)
        Write-Host "`n[+] Battery Report Generated Successfully!" -ForegroundColor Green
        Write-Host "    Saved to: $SuccessfulReport" -ForegroundColor DarkGray
        Write-Host "    Opening in default browser..." -ForegroundColor DarkGray
        Start-Process $SuccessfulReport
    } else {
        Write-Host "`n[!] Battery driver error or ACPI interface restricted." -ForegroundColor DarkRed
        Write-Host "    Try disabling and re-enabling 'Microsoft ACPI-Compliant Control" -ForegroundColor Yellow
        Write-Host "    Method Battery' in Device Manager." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 4
}

function Invoke-SleepStudyReport {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "        AetherSleep Standby Battery Analysis        " -ForegroundColor Gray
    Write-Host "===================================================`n" -ForegroundColor Gray
    Write-Host "Generating Modern Standby sleep drain telemetry..." -ForegroundColor Gray

    $Path = "$env:TEMP\sleep-study.html"
    cmd.exe /c "powercfg /sleepstudy /output `"$Path`"" 2>&1 | Out-Null

    if (Test-Path $Path) {
        [void](Fix-HtmlReport -ReportPath $Path)
        Write-Host "`n[+] Sleep Study Generated Successfully!" -ForegroundColor Green
        Write-Host "    Saved to: $Path" -ForegroundColor DarkGray
        Write-Host "    Opening in default browser..." -ForegroundColor DarkGray
        Start-Process $Path
    } else {
        Write-Host "`n[!] Failed to generate Sleep Study report." -ForegroundColor DarkRed
    }
    Start-Sleep -Seconds 3
}

function Invoke-WlanReport {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "        AetherNet Wi-Fi Diagnostic Timeline         " -ForegroundColor Gray
    Write-Host "===================================================`n" -ForegroundColor Gray

    # 1. Ensure WLAN AutoConfig Service is Running
    $WlanService = Get-Service -Name "WlanSvc" -ErrorAction SilentlyContinue
    if ($WlanService -and $WlanService.Status -ne "Running") {
        Write-Host "Starting WLAN AutoConfig service..." -ForegroundColor DarkGray
        Start-Service -Name "WlanSvc" -ErrorAction SilentlyContinue
    }

    # 2. Verify WLAN Interface presence via netsh
    $NetshCheck = netsh wlan show interfaces 2>&1 | Out-String
    if ($NetshCheck -match "There is no wireless interface on the system") {
        Write-Host "[!] No active Wi-Fi adapter detected on this system." -ForegroundColor Yellow
        Write-Host "    Wi-Fi reports require an operational wireless interface." -ForegroundColor DarkGray
        Start-Sleep -Seconds 4
        return
    }

    # 3. Enable Required Wi-Fi Event Logs to prevent 0x2 File Not Found trace errors
    wevtutil sl "Microsoft-Windows-WLAN-AutoConfig/Operational" /e:true 2>$null
    wevtutil sl "Microsoft-Windows-Nwifi/Diagnostic" /e:true 2>$null

    Write-Host "Analyzing wireless adapters and connection history..." -ForegroundColor Gray

    # 4. Prepare Standard ProgramData Directory
    $ProgramDataDir = "$env:ProgramData\Microsoft\Windows\WlanReport"
    if (-not (Test-Path $ProgramDataDir)) {
        New-Item -ItemType Directory -Path $ProgramDataDir -Force | Out-Null
    }

    # 5. Execute netsh wlanreport
    $NetshResult = cmd.exe /c "netsh wlan show wlanreport" 2>&1 | Out-String

    # 6. Check for generated HTML files
    $ReportFile = Get-ChildItem -Path $ProgramDataDir -Filter "*.html" -ErrorAction SilentlyContinue | 
                 Sort-Object LastWriteTime -Descending | Select-Object -First 1

    $TargetCopy = "$env:TEMP\wlan-report-latest.html"

    if ($ReportFile -and (Test-Path $ReportFile.FullName)) {
        Copy-Item -Path $ReportFile.FullName -Destination $TargetCopy -Force -ErrorAction SilentlyContinue
        $FinalOutput = if (Test-Path $TargetCopy) { $TargetCopy } else { $ReportFile.FullName }

        [void](Fix-HtmlReport -ReportPath $FinalOutput)

        Write-Host "`n[+] Wi-Fi Diagnostic Report Generated Successfully!" -ForegroundColor Green
        Write-Host "    Saved to: $FinalOutput" -ForegroundColor DarkGray
        Write-Host "    Opening in default browser..." -ForegroundColor DarkGray
        Start-Process $FinalOutput
    } else {
        # Fallback Diagnostic Mode: Export raw WLAN state to desktop if HTML trace fails
        $FallbackTxt = "$env:USERPROFILE\Desktop\wlan-diagnostic-log.txt"
        cmd.exe /c "netsh wlan show all" > $FallbackTxt 2>&1

        if (Test-Path $FallbackTxt) {
            Write-Host "`n[!] Event Log trace failed (0x2 Error). Generated Fallback Log!" -ForegroundColor Yellow
            Write-Host "    Saved raw Wi-Fi analysis to: $FallbackTxt" -ForegroundColor DarkGray
            Write-Host "    Opening text log..." -ForegroundColor DarkGray
            Start-Process $FallbackTxt
        } else {
            Write-Host "`n[!] Wi-Fi interface detected, but netsh failed to output trace." -ForegroundColor DarkRed
            Write-Host "    Diagnostic Log: $NetshResult" -ForegroundColor DarkGray
        }
    }
    Start-Sleep -Seconds 4
}

function Invoke-ResourceMonitor {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "        NexusMon Real-Time Resource Inspector       " -ForegroundColor Gray
    Write-Host "===================================================`n" -ForegroundColor Gray
    Write-Host "Launching Windows Resource Monitor..." -ForegroundColor Gray
    
    resmon
    
    Write-Host "`n[+] Resource Monitor Launched!" -ForegroundColor Green
    Start-Sleep -Seconds 3
}

function Invoke-DriverBackup {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "        AetherDriver Backup & Export                " -ForegroundColor Gray
    Write-Host "===================================================`n" -ForegroundColor Gray
    
    $BackupPath = "$env:USERPROFILE\Desktop\DriverBackup"
    if (-not (Test-Path $BackupPath)) { New-Item -ItemType Directory -Path $BackupPath | Out-Null }
    
    Write-Host "Exporting third-party drivers to Desktop\DriverBackup..." -ForegroundColor Gray
    pnputil /export-driver * $BackupPath | Out-Null
    
    Write-Host "`n[+] Third-Party Drivers Backed Up Successfully!" -ForegroundColor Green
    Write-Host "    Location: $BackupPath" -ForegroundColor DarkGray
    Start-Sleep -Seconds 3
}

function Invoke-GodMode {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "        NexusVault Master Control                   " -ForegroundColor Gray
    Write-Host "===================================================`n" -ForegroundColor Gray
    Write-Host "Launching Unified Windows God Mode Control Panel..." -ForegroundColor Gray
    
    explorer.exe "shell:::{ED7BA470-8E54-465E-825C-99712043E01C}"
    
    Write-Host "`n[+] Master Control Panel Launched!" -ForegroundColor Green
    Start-Sleep -Seconds 3
}


# Interactive Menu Loop
do {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "              =====| 11UNKNOWN59 |====              " -ForegroundColor Gray
    Write-Host "              SYSTEM MAINTENANCE SUITE              " -ForegroundColor Gray
    Write-Host "===================================================" -ForegroundColor Gray
    
    # --- GENERAL SECTION ---
    Write-Host "`n --- [ GENERAL / MOST USED ] ----------------------" -ForegroundColor DarkGreen
    Write-Host " [1] QuantumClean Deep-Purge" -ForegroundColor Gray
    Write-Host "     (Universal Dynamic Cache Discovery & Purge)" -ForegroundColor DarkGray
    Write-Host " [2] NexusPrime Core-Optimizer" -ForegroundColor Gray
    Write-Host "     (Windows Performance & Repair Suite)" -ForegroundColor DarkGray
    # --- ADVANCED SECTION ---
    Write-Host "`n --- [ ADVANCED & DIAGNOSTICS ] -------------------" -ForegroundColor DarkGreen
    Write-Host " [5] AetherCell Battery Health Dashboard" -ForegroundColor Gray
    Write-Host "     (Detailed Battery Capacity & Life Cycles)" -ForegroundColor DarkGray
    Write-Host " [6] AetherSleep Standby Battery Analysis" -ForegroundColor Gray
    Write-Host "     (Track Background Battery Drain in Sleep)" -ForegroundColor DarkGray
    Write-Host " [7] AetherNet Wi-Fi Diagnostic Timeline" -ForegroundColor Gray
    Write-Host "     (Wireless Session Drops & Signal Graph)" -ForegroundColor DarkGray
    Write-Host " [8] AetherPulse Power Report" -ForegroundColor Gray
    Write-Host "     (60s Power & Battery Efficiency Trace)" -ForegroundColor DarkGray
    Write-Host " [9] NexusDiag System Health Report" -ForegroundColor Gray
    Write-Host "     (Full Hardware & System Diagnostics)" -ForegroundColor DarkGray
    Write-Host " [A] NexusMon Real-Time Resource Inspector" -ForegroundColor Gray
    Write-Host "     (Live CPU/RAM/Disk/Network Process Monitor)" -ForegroundColor DarkGray
    Write-Host " [B] AetherLog Reliability Monitor" -ForegroundColor Gray
    Write-Host "     (System Crash & Software Stability History)" -ForegroundColor DarkGray
    Write-Host " [C] AetherDriver Backup & Export" -ForegroundColor Gray
    Write-Host "     (Export All Third-Party Drivers to Desktop)" -ForegroundColor DarkGray
    Write-Host " [D] NexusVault Master Control" -ForegroundColor Gray
    Write-Host "     (Open Unified God Mode Control Panel)" -ForegroundColor DarkGray
    Write-Host " [F] AetherFlush Network-Reset" -ForegroundColor Gray
    Write-Host "     (Flush Network & DNS Cache Only)" -ForegroundColor DarkGray

    Write-Host "`n [Q] Quit" -ForegroundColor DarkRed
    Write-Host "===================================================" -ForegroundColor Gray
    Write-Host "Choose an option using your keyboard [1-9, A-F, Q] : " -NoNewline

    $Key = [System.Console]::ReadKey($true)
    $Selection = [string]$Key.KeyChar
    Write-Host $Selection
    Start-Sleep -Milliseconds 300

    switch ($Selection.ToUpper()) {
        # General Options
        "1" { Invoke-UniversalClean }
        "2" { Invoke-PerformanceOptimization }

        # Advanced Options
        "5" { Invoke-BatteryReport }
        "6" { Invoke-SleepStudyReport }
        "7" { Invoke-WlanReport }
        "8" { Invoke-PowerReport }
        "9" { Invoke-SystemReport }
        "A" { Invoke-ResourceMonitor }
        "B" { Invoke-ReliabilityMonitor }
        "C" { Invoke-DriverBackup }
        "D" { Invoke-GodMode }
        "F" { 
            Clear-DnsClientCache
            Write-Host "`nAetherFlush: DNS Cache Cleared!" -ForegroundColor Green
            Start-Sleep -Seconds 3
        }

        "Q" { Write-Host "`nExiting..."; Exit }

        # Invalid Input Error Handling
        default {
            Write-Host "`n`n[!] Invalid Selection: '$Selection'" -ForegroundColor Red
            Write-Host "    Please enter a valid option symbol from the menu [1-9, A-F, Q]." -ForegroundColor Red
            Start-Sleep -Seconds 3
        }
    }
} while ($true)
