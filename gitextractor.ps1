param(
    [Parameter(Mandatory=$true)]
    [string]$GitDir,
    
    [Parameter(Mandatory=$true)]
    [string]$DestDir
)

# Define the full path to git.exe
$GitExe = "C:\Users\fred.AND\Downloads\PortableGit\bin\git.exe"

function Init-Header {
@"
###########
# Extractor is part of https://github.com/internetwache/GitTools
#
# Developed and maintained by @gehaxelt from @internetwache
#
# Use at your own risk. Usage might be illegal in certain circumstances.
# Only for educational purposes!
###########
"@ | Write-Host
}

Init-Header

# Validate that the .git directory exists
if (-not (Test-Path (Join-Path $GitDir ".git"))) {
    Write-Host "[-] There's no .git folder" -ForegroundColor Red
    exit 1
}

# Create the destination folder if it does not exist
if (-not (Test-Path $DestDir)) {
    Write-Host "[*] Destination folder does not exist" -ForegroundColor Yellow
    Write-Host "[*] Creating..." -ForegroundColor Green
    New-Item -ItemType Directory -Path $DestDir | Out-Null
}

function Traverse-Tree {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Tree,
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    # Get tree data using git ls-tree via the full path
    $treeOutput = & $GitExe ls-tree $Tree
    foreach ($line in $treeOutput) {
        # Parse each line using regex:
        # Expected format: <mode> <type> <hash><TAB><name>
        if ($line -match '^(?<mode>\d+)\s+(?<type>\w+)\s+(?<hash>[0-9a-f]{40})\s+(?<name>.+)$') {
            $type = $Matches['type']
            $hash = $Matches['hash']
            $name = $Matches['name']

            # Verify the git object exists
            try {
                & $GitExe cat-file -e $hash 2>$null
            }
            catch {
                continue
            }
            
            $targetPath = Join-Path $Path $name

            if ($type -eq "blob") {
                Write-Host "[+] Found file: $targetPath" -ForegroundColor Green
                & $GitExe cat-file -p $hash | Out-File -FilePath $targetPath -Encoding utf8
            }
            else {
                Write-Host "[+] Found folder: $targetPath" -ForegroundColor Green
                if (-not (Test-Path $targetPath)) {
                    New-Item -ItemType Directory -Path $targetPath | Out-Null
                }
                # Recursively traverse the subtree
                Traverse-Tree -Tree $hash -Path $targetPath
            }
        }
    }
}

function Traverse-Commit {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Base,
        [Parameter(Mandatory=$true)]
        [string]$Commit,
        [Parameter(Mandatory=$true)]
        [int]$Count
    )
    Write-Host "[+] Found commit: $Commit" -ForegroundColor Green
    $commitDirName = "$Count-$Commit"
    $commitPath = Join-Path $Base $commitDirName
    New-Item -ItemType Directory -Path $commitPath | Out-Null
    # Save commit meta information
    & $GitExe cat-file -p $Commit | Out-File -FilePath (Join-Path $commitPath "commit-meta.txt") -Encoding utf8
    # Attempt to extract the tree contents of the commit
    Traverse-Tree -Tree $Commit -Path $commitPath
}

# Save current directory so we can return later
$OldDir = Get-Location

# If the destination folder is not an absolute path, convert it
if (-not [System.IO.Path]::IsPathRooted($DestDir)) {
    $DestDir = Join-Path $OldDir.Path $DestDir
}

Set-Location $GitDir
$CommitCount = 0

# Get all files under .git\objects recursively
Get-ChildItem -Path ".git\objects" -Recurse -File | ForEach-Object {
    # In Git, objects are stored in a two-level directory.
    # Combine the directory name (first two characters) with the filename (remaining 38 characters)
    $objectHash = "$($_.Directory.Name)$($_.Name)"
    $type = (& $GitExe cat-file -t $objectHash 2>$null).Trim()
    
    # Only process commit objects
    if ($type -eq "commit") {
        $currentDir = Get-Location
        Traverse-Commit -Base $DestDir -Commit $objectHash -Count $CommitCount
        Set-Location $currentDir
        $CommitCount++
    }
}

# Return to the original directory
Set-Location $OldDir
