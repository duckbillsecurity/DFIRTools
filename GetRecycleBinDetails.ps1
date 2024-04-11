function Get-RecycleBinDetails {
    param (
        [string]$driveLetter
    )
    
    # Create a COM object to interact with the Shell
    $shellApp = New-Object -ComObject Shell.Application
    
    # Get the Recycle Bin folder using its Shell special folder ID, 0xA
    $recycleBinFolder = $shellApp.Namespace(0xA)
    
    # Iterate through items in the Recycle Bin
    foreach ($item in $recycleBinFolder.Items()) {
        # Filter items by the specified drive letter
        if ($item.Path.StartsWith($driveLetter, [StringComparison]::OrdinalIgnoreCase)) {
            $originalPath = $item.Path
            $nameInRecycleBin = $item.Name
            $size = $item.Size
            $dateModified = $item.ModifyDate

            # Construct and output a custom PowerShell object with the desired details
            [PSCustomObject]@{
                OriginalPath     = $originalPath                # The original path of the file
                NameInRecycleBin = $nameInRecycleBin            # The name of the file in the Recycle Bin
                Size             = $size                        # The size of the file in bytes
                DateModified     = $dateModified                # The date the file was last modified
            } | Format-Table -AutoSize  # Formatting output for better readability
        }
    }
}

# Example Usage:
# Replace "C:" with the drive letter you want to analyze. 
# Run this script with administrative privileges to ensure complete access to all Recycle Bin contents.
Get-RecycleBinDetails -driveLetter "C:"
