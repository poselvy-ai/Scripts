# Weekly Maintenance Script
# Author: Patrick Selvy
# Date: 2026-07-22
#Functions for weekly maintenance tasks

#Warning Mesage
$loggedIn = (query user) -match "Active"

if ($loggedIn) {
    msg * "Weekly Maintenance will begin in 60 seconds. Please save your work."
    Start-Sleep -Seconds 60
    shutdown.exe /l
}


# Check the Windows image health
function Test-WindowsImageHealth {
    [CmdletBinding()]
    param ()

    Write-Host "Checking Windows image health..." -ForegroundColor Cyan
    Repair-WindowsImage -Online -Verbose -ScanHealth
}

# Flush DNS Cache
function Flush-DNSCache {
    [CmdletBinding()]
    param ()

    Write-Host "Flushing DNS cache..." -ForegroundColor Cyan
    ipconfig /flushdns
}

# Check for Windows Updates
function Update-Windows {
    [CmdletBinding()]
    param()

    Write-Host "Checking for Windows Updates..." -ForegroundColor Cyan

    $session  = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $result   = $searcher.Search("IsInstalled=0 and Type='Software'")

    if ($result.Updates.Count -eq 0) {
        Write-Host "No updates available." -ForegroundColor Yellow
        return
    }

    Write-Host "Updates found: $($result.Updates.Count)" -ForegroundColor Green
    foreach ($update in $result.Updates) {
        Write-Host " - $($update.Title)"
    }

    Write-Host "Installing updates (reboots suppressed)..." -ForegroundColor Cyan

    $installer = $session.CreateUpdateInstaller()
    $installer.Updates = $result.Updates
    $installer.ForceQuiet = $true

    $installation = $installer.Install()

    Write-Host "Installation Result: $($installation.ResultCode)" -ForegroundColor Green
    Write-Host "Reboot Required: $($installation.RebootRequired)" -ForegroundColor Yellow
    Write-Host "Reboot suppressed. Script will continue." -ForegroundColor Yellow
}

# Disk Cleanup
function Run-DiskCleanup {
    [CmdletBinding()]
    param ()

    Write-Host "Running disk cleanup..." -ForegroundColor Cyan
    cleanmgr /sagerun:1
}

# Clear Browser Cache
function Clear-BrowserCache {
    [CmdletBinding()]
    param()

    Write-Host "Cleaning Chrome and Edge cache..." -ForegroundColor Cyan

    $cachePaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache\*",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache\*",

        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache\*"
    )

    foreach ($path in $cachePaths) {
        try {
            Remove-Item $path -Force -Recurse -ErrorAction Stop
            Write-Host "Cleared: $path" -ForegroundColor Green
        }
        catch {
            Write-Host "FAILED to clear: $path" -ForegroundColor Red
        }
    }
}

# Commands
Test-WindowsImageHealth
Flush-DNSCache
Update-Windows
Run-DiskCleanup
Clear-BrowserCache
#restart computer to apply updates and complete maintenance
Restart-Computer -Force
#end of script
