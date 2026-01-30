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

# Regex patterns for all known Acumatica screen declarations (case-insensitive)
$patterns = @(
    '(?i)screenid="([^"]+)"',
    '(?i)screen id="([^"]+)"',
    '(?i)page code="([^"]+)"',
    '(?i)code="([A-Z]{2}[0-9]{6})"',
    '(?i)screen code="([^"]+)"'
)

foreach ($pkg in Get-ChildItem $packagePath -Filter *.zip) {

    Write-Host "Package: $($pkg.Name)"
    $zip = [System.IO.Compression.ZipFile]::OpenRead($pkg.FullName)

    # Try Pages/*.xml first
    $pageEntries = $zip.Entries | Where-Object { $_.FullName -like "Pages/*.xml" }

    if ($pageEntries.Count -gt 0) {
        foreach ($entry in $pageEntries) {
            $stream = $entry.Open()
            $reader = New-Object System.IO.StreamReader($stream)
            $xml = $reader.ReadToEnd()

            foreach ($pattern in $patterns) {
                if ($xml -match $pattern) {
                    $results += [PSCustomObject]@{
                        Package = $pkg.Name
                        Screen  = $matches[1]
                    }
                }
            }
        }
    }
    else {
        # Fallback: read Project.xml
        $proj = $zip.Entries | Where-Object { $_.FullName -eq "Project.xml" }

        if ($proj) {
            $stream = $proj.Open()
            $reader = New-Object System.IO.StreamReader($stream)
            $xml = $reader.ReadToEnd()

            foreach ($pattern in $patterns) {
                foreach ($match in [regex]::Matches($xml, $pattern)) {
                    $results += [PSCustomObject]@{
                        Package = $pkg.Name
                        Screen  = $match.Groups[1].Value
                    }
                }
            }
        }
    }

    $zip.Dispose()
    Write-Host ""
}

$results | Sort-Object Package, Screen | Export-Csv -Path $outputCsv -NoTypeInformation

Write-Host "`nDone! Output saved to: $outputCsv"
