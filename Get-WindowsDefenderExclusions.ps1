function Get-WindowsDefenderExclusions {
    # Registry paths for Windows Defender exclusions
    $pathRegistry = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths"
    $extensionRegistry = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Extensions"
    $processRegistry = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes"

    try {
        # Function to retrieve exclusion names from registry
        function Get-ExclusionNames {
            param (
                [string]$registryPath
            )

            $exclusions = Get-ItemProperty -Path $registryPath -ErrorAction Stop
            if ($exclusions) {
                $exclusionNames = $exclusions.PSObject.Properties.Name | Where-Object { $_ -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider') }
                return $exclusionNames
            }
            return @()
        }

        # Get Path exclusions
        $pathExclusions = Get-ExclusionNames -registryPath $pathRegistry

        # Get Extension exclusions
        $extensionExclusions = Get-ExclusionNames -registryPath $extensionRegistry

        # Get Process exclusions
        $processExclusions = Get-ExclusionNames -registryPath $processRegistry

        # Display results
        Write-Host "Windows Defender Exclusions:"
        Write-Host "-----------------------------"
        
        if ($pathExclusions) {
            Write-Host "Path Exclusions:"
            $pathExclusions | ForEach-Object { Write-Host $_ }
                        Write-Host ""
        } else {
            Write-Host "No Extension Exclusions found."
        }

        if ($extensionExclusions) {
            Write-Host "Extension Exclusions:"
            $extensionExclusions | ForEach-Object { Write-Host $_ }
            Write-Host ""
        } else {
            Write-Host "No Extension Exclusions found."
        }

        if ($processExclusions) {
            Write-Host "Process Exclusions:"
            $processExclusions | ForEach-Object { Write-Host $_ }
            Write-Host ""
        } else {
            Write-Host "No Process Exclusions found."
        }
    }
    catch {
        Write-Host "Error occurred while retrieving Windows Defender exclusions: $_"
    }
}

# Call the function to retrieve and display Windows Defender exclusions
Get-WindowsDefenderExclusions

