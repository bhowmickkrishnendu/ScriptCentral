<#
.SYNOPSIS
    Cleans temporary files from the C: drive to free up disk space.

.DESCRIPTION
    Safely removes temp files, cache, and junk from standard Windows locations:
      - User temp folder (%TEMP%)
      - Windows temp folder (C:\Windows\Temp)
      - Windows Update cache (SoftwareDistribution\Download)
      - Windows error reporting / crash dumps
      - Recycle Bin
      - Browser caches (Edge, Chrome, Firefox) - cache only, not history/bookmarks/passwords
      - Windows Prefetch (optional, off by default)
      - Old Windows.old folder (if present, prompts before deleting - can be 10-20+ GB)
      - Delivery Optimization cache
      - Thumbnail cache

    It does NOT touch Documents, Desktop, Pictures, Downloads, or any other personal
    files/folders. It only targets known temp/cache directories.

.NOTES
    Run this in an elevated (Administrator) PowerShell window for best results.
    Some files may be skipped because they are currently in use - that's normal
    and safe to ignore.

.EXAMPLE
    .\Clean-TempFiles.ps1
    Runs with confirmation prompts for the big/risky items (Windows.old, Recycle Bin).

.EXAMPLE
    .\Clean-TempFiles.ps1 -Force
    Runs everything without prompts (still skips Windows.old unless -IncludeWindowsOld is passed).
#>

[CmdletBinding()]
param(
    [switch]$Force,                # skip confirmation prompts
    [switch]$IncludeWindowsOld,    # also remove C:\Windows.old if present (frees a LOT of space)
    [switch]$IncludePrefetch       # also clear C:\Windows\Prefetch (usually not needed)
)

# ---- Setup ------------------------------------------------------------

$ErrorActionPreference = 'SilentlyContinue'
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "Not running as Administrator. Some system temp locations may be skipped."
    Write-Warning "For best results, right-click PowerShell and 'Run as Administrator', then re-run this script."
}

function Get-FreeSpaceGB {
    (Get-PSDrive C).Free / 1GB
}

function Remove-FolderContents {
    param(
        [string]$Path,
        [string]$Label
    )
    if (-not (Test-Path $Path)) {
        Write-Host "  [skip] $Label - path not found: $Path" -ForegroundColor DarkGray
        return
    }

    $before = 0
    try {
        $before = (Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue |
                   Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    } catch {}

    Write-Host "  [clean] $Label ..." -ForegroundColor Cyan

    Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue |
        Sort-Object -Property FullName -Descending |
        ForEach-Object {
            try {
                Remove-Item -LiteralPath $_.FullName -Force -Recurse -ErrorAction SilentlyContinue
            } catch {
                # file in use or protected - safe to skip
            }
        }

    $freedMB = if ($before) { [math]::Round($before / 1MB, 1) } else { 0 }
    Write-Host "    -> attempted cleanup (~$freedMB MB of items found)" -ForegroundColor DarkCyan
}

# ---- Start --------------------------------------------------------------

Write-Host "=====================================================" -ForegroundColor Green
Write-Host " Windows Temp File Cleanup" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green

$freeBefore = Get-FreeSpaceGB
Write-Host ("Free space on C: before cleanup: {0:N2} GB" -f $freeBefore)
Write-Host ""

# 1. User temp folder
Remove-FolderContents -Path $env:TEMP -Label "User Temp folder ($env:TEMP)"

# 2. Windows temp folder
Remove-FolderContents -Path "C:\Windows\Temp" -Label "Windows Temp folder"

# 3. Windows Update download cache (safe - Windows re-downloads as needed)
try {
    Write-Host "  [clean] Windows Update cache ..." -ForegroundColor Cyan
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Remove-FolderContents -Path "C:\Windows\SoftwareDistribution\Download" -Label "SoftwareDistribution\Download"
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
} catch {}

# 4. Delivery Optimization cache
Remove-FolderContents -Path "C:\Windows\SoftwareDistribution\DeliveryOptimization" -Label "Delivery Optimization cache"

# 5. Windows Error Reporting
Remove-FolderContents -Path "C:\ProgramData\Microsoft\Windows\WER\ReportArchive" -Label "Error Reporting archive"
Remove-FolderContents -Path "C:\ProgramData\Microsoft\Windows\WER\ReportQueue" -Label "Error Reporting queue"

# 6. Memory dump / minidump files
Remove-FolderContents -Path "C:\Windows\Minidump" -Label "Minidump files"

# 7. Thumbnail cache
Remove-FolderContents -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Label "Thumbnail cache"

# 8. Browser caches (cache only - NOT bookmarks, passwords, history, or saved logins)
$edgeCache   = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
$chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
$ffCacheRoot = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"

Remove-FolderContents -Path $edgeCache -Label "Edge cache"
Remove-FolderContents -Path $chromeCache -Label "Chrome cache"

if (Test-Path $ffCacheRoot) {
    Get-ChildItem -Path $ffCacheRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $ffCache = Join-Path $_.FullName "cache2"
        Remove-FolderContents -Path $ffCache -Label "Firefox cache ($($_.Name))"
    }
}

# 9. Prefetch (optional - off by default, rarely needed and can slightly affect boot caching)
if ($IncludePrefetch) {
    Remove-FolderContents -Path "C:\Windows\Prefetch" -Label "Prefetch"
} else {
    Write-Host "  [skip] Prefetch (use -IncludePrefetch to include)" -ForegroundColor DarkGray
}

# 10. Recycle Bin
if ($Force -or (Read-Host "Empty the Recycle Bin too? (y/n)") -eq 'y') {
    Write-Host "  [clean] Recycle Bin ..." -ForegroundColor Cyan
    Clear-RecycleBin -DriveLetter C -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "  [skip] Recycle Bin" -ForegroundColor DarkGray
}

# 11. Windows.old (previous Windows install after upgrade) - big but optional/risky
if (Test-Path "C:\Windows.old") {
    if ($IncludeWindowsOld -or ($Force -eq $false -and (Read-Host "C:\Windows.old found. This holds your PREVIOUS Windows install and can be 10-20+ GB. Delete it? (y/n)") -eq 'y')) {
        Write-Host "  [clean] C:\Windows.old ..." -ForegroundColor Cyan
        # Use the built-in cleanup tool which handles permissions correctly
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -ErrorAction SilentlyContinue
        Remove-FolderContents -Path "C:\Windows.old" -Label "Windows.old"
    } else {
        Write-Host "  [skip] C:\Windows.old (contains your previous Windows install - kept)" -ForegroundColor DarkGray
    }
}

# 12. Run built-in Disk Cleanup for anything else safe to purge
Write-Host ""
Write-Host "Launching Windows Disk Cleanup for additional system cleanup..." -ForegroundColor Cyan
try {
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/verylowdisk" -ErrorAction SilentlyContinue
} catch {}

# ---- Summary --------------------------------------------------------------

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
$freeAfter = Get-FreeSpaceGB
$freed = $freeAfter - $freeBefore
Write-Host ("Free space on C: after cleanup:  {0:N2} GB" -f $freeAfter)
Write-Host ("Approx. space freed:             {0:N2} GB" -f $freed) -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Done. Your Documents, Desktop, Pictures, Downloads, and other personal files were not touched." -ForegroundColor Green