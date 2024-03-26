# Get the hostname of the system
$hostname = $env:COMPUTERNAME

# Get all installed software information
$softwareList = Get-WmiObject -Class Win32_Product

# Create an array to hold the software information
$softwareInfo = @()

# Loop through each software item and collect relevant properties
foreach ($software in $softwareList) {
    $softwareDetails = New-Object PSObject -Property @{
        Name        = $software.Name
        Publisher   = $software.Vendor
        InstalledOn = $software.InstallDate
    }
    $softwareInfo += $softwareDetails
}

# Export the software information to a CSV file named with the system hostname
$csvFilePath = "$hostname-InstalledSoftware.csv"
$softwareInfo | Export-Csv -Path $csvFilePath -NoTypeInformation

# Output the path of the generated CSV file
Write-Output "Installed software information exported to: $csvFilePath"
