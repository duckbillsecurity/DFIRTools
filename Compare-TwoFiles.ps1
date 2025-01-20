<#
.SYNOPSIS
  Compare two text files using native PowerShell and output only the lines
  that differ in File2.

.DESCRIPTION
  This script uses Compare-Object to find differences between File1 (the
  "ReferenceObject") and File2 (the "DifferenceObject"). It filters out
  all lines that are identical or belong only to File1, leaving only lines
  that are different in File2. The results are written to 'diff.txt'.

.\Compare-TwoFiles.ps1 -File1 file1.js -File2 File2.js
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$File1,

    [Parameter(Mandatory=$true)]
    [string]$File2,

    [string]$Output = "diff.txt"
)

if (-not (Test-Path $File1)) {
    Write-Host "ERROR: $File1 not found."
    exit 1
}
if (-not (Test-Path $File2)) {
    Write-Host "ERROR: $File2 not found."
    exit 1
}

Write-Host "Comparing '$File1' to '$File2'..."
Write-Host "Only differences from File2 will be saved to '$Output'."

# Get the differences
# -ReferenceObject => lines from File1
# -DifferenceObject => lines from File2
# We then filter for lines whose SideIndicator is '=>' (i.e., "new" in File2).
Compare-Object -ReferenceObject (Get-Content $File1) `
               -DifferenceObject (Get-Content $File2) `
    | Where-Object { $_.SideIndicator -eq '=>' } `
    | Select-Object -ExpandProperty InputObject `
    | Out-File $Output

Write-Host "Done. Differences saved in '$Output'."
