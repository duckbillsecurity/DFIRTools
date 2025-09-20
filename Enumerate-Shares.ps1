<#
.SYNOPSIS
    Enumerates network shares in an Active Directory domain without requiring RSAT.

.DESCRIPTION
    - Uses ADSISearcher to query all computer accounts in the domain.
    - Enumerates shares via WMI (Win32_Share).
    - Gracefully handles unreachable hosts or access errors.
    - Outputs results in a table and can export to CSV.
#>

Write-Host "Querying domain for computers..."

$computers = ([adsisearcher]"(&(objectCategory=computer))").FindAll() |
    ForEach-Object { $_.Properties.name } |
    Sort-Object -Unique

Write-Host "Found $($computers.Count) computers. Enumerating shares..."

$results = @()

foreach ($computer in $computers) {
    Write-Host "-> $computer ..." -NoNewline

    try {
        # Quick ping test before enumeration
        if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
            Write-Host " UNREACHABLE"
            continue
        }

        # Query shares
        $shares = Get-WmiObject -Class Win32_Share -ComputerName $computer -ErrorAction Stop

        if ($shares) {
            Write-Host " SUCCESS ($($shares.Count) shares)"
            foreach ($share in $shares) {
                $results += [PSCustomObject]@{
                    Computer    = $computer
                    ShareName   = $share.Name
                    Path        = $share.Path
                    Description = $share.Description
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
