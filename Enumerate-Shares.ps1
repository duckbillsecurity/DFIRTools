<#
.SYNOPSIS
    Enumerates network shares in an Active Directory domain excluding Windows 10/11 clients,
    and reports if the current user can access them.

.DESCRIPTION
    - Uses ADSISearcher to query all computer accounts in the domain.
    - Filters out Windows 10 and 11 clients.
    - Enumerates shares via WMI (Win32_Share).
    - Checks if the current user can access each share using Test-Path.
    - Outputs results in a table and can export to CSV.
#>

Write-Host "Querying domain for computers..."

# Step 1: Get all computers from AD
$allComputers = ([adsisearcher]"(&(objectCategory=computer))").FindAll() |
    ForEach-Object { $_.Properties.name } |
    Sort-Object -Unique

Write-Host "Found $($allComputers.Count) computers. Filtering out Windows 10/11 clients..."

# Step 2: Filter out Windows 10/11 clients
$computers = @()
foreach ($computer in $allComputers) {
    try {
        $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computer -ErrorAction Stop
        if ($os.Caption -notmatch "Windows 10|Windows 11") {
            $computers += $computer
        }
    } catch {
        Write-Host " -> $computer unreachable or WMI failed, skipping."
    }
}

Write-Host "Scanning $($computers.Count) non-client machines for shares..."

$results = @()

# Step 3: Enumerate shares and check access
foreach ($computer in $computers) {
    Write-Host "-> $computer ..." -NoNewline

    try {
        if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
            Write-Host " UNREACHABLE"
            continue
        }

        $shares = Get-WmiObject -Class Win32_Share -ComputerName $computer -ErrorAction Stop

        if ($shares) {
            Write-Host " SUCCESS ($($shares.Count) shares)"
            foreach ($share in $shares) {
                $access = ""
                try {
                    if (Test-Path "\\$computer\$($share.Name)") {
                        $access = "Accessible"
                    } else {
                        $access = "Not Accessible"
                    }
                } catch {
                    $access = "Access Denied"
                }

                $results += [PSCustomObject]@{
                    Computer    = $computer
                    ShareName   = $share.Name
                    Path        = $share.Path
                    Description = $share.Description
                    UserAccess  = $access
                }
            }
        }
        else {
            Write-Host " NO SHARES"
        }
    }
    catch {
        Write-Host " FAILED ($_)" -ForegroundColor Yellow
    }
}

Write-Host "`n=== ENUMERATION RESULTS ==="
$results | Format-Table -AutoSize

# Optional: export to CSV
# $results | Export-Csv -NoTypeInformation -Path .\ShareEnumeration.csv
