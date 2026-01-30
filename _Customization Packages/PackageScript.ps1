# Automatically use the folder where this script is located
$rootPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Path to the _Released folder containing customization packages
$packagePath = Join-Path $rootPath "_Released"

# Output CSV saved in the same root folder
$outputCsv = Join-Path $rootPath "CustomizationScreenMap.csv"
$results = @()

Write-Host "Scanning customization packages in: $packagePath`n"

# Load .NET ZIP library
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Loop through all ZIP files in _Released
foreach ($pkg in Get-ChildItem $packagePath -Filter *.zip) {

    Write-Host "Package: $($pkg.Name)"
    $zip = [System.IO.Compression.ZipFile]::OpenRead($pkg.FullName)

    foreach ($entry in $zip.Entries) {

        # Only look at screen XML files
        if ($entry.FullName -like "Pages/*.xml") {

            $stream = $entry.Open()
            $reader = New-Object System.IO.StreamReader($stream)
            $xml = $reader.ReadToEnd()

            # Extract screen ID
            if ($xml -match 'ScreenID="([^"]+)"') {
                $screen = $matches[1]
                Write-Host "  - $screen"

                # Add to results for CSV
                $results += [PSCustomObject]@{
                    Package = $pkg.Name
                    Screen  = $screen
                }
            }
        }
    }

    $zip.Dispose()
    Write-Host ""
}

# Export results to CSV
$results | Sort-Object Package, Screen | Export-Csv -Path $outputCsv -NoTypeInformation

Write-Host "`nDone! Output saved to: $outputCsv"