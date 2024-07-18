# Get all network interfaces and their details
$nics = az network nic list --query '[].{Name:name, ResourceGroup:resourceGroup, IpConfigurations:ipConfigurations, VMId:virtualMachine.id, LinkedResource:privateEndpoint.id}' -o json | ConvertFrom-Json

# Get all public IP addresses
$publicIps = az network public-ip list --query '[].{Id:id, PublicIP:ipAddress}' -o json | ConvertFrom-Json

# Initialize an array to hold the combined results
$combinedResults = @()

# Combine NIC details with public IP addresses
foreach ($nic in $nics) {
    # Extract the private IP from the first ipConfiguration
    $privateIp = $nic.IpConfigurations[0].privateIPAddress

    # Get public IP if available
    $publicIpId = $nic.IpConfigurations[0].publicIPAddress.id
    $publicIp = $publicIps | Where-Object { $_.Id -eq $publicIpId } | Select-Object -ExpandProperty PublicIP -ErrorAction SilentlyContinue
    if (-not $publicIp) {
        $publicIp = "None"
    }

    # Extract the resource name from the LinkedResource
    $VMId               = ($nic.VMId -split '/')[-1]
    $linkedResourceName = ($nic.LinkedResource -split '/')[-1]

    # Create a custom object with the combined details
    $combinedResult = [PSCustomObject]@{
        NicName         = $nic.Name
        ResourceGroup   = $nic.ResourceGroup
        PrivateIP       = $privateIp
        PublicIP        = $publicIp
        LinkedVM        = $VMId
        LinkedResource  = $linkedResourceName
    }

    # Add the custom object to the results array
    $combinedResults += $combinedResult
}

# Export the combined results to a CSV file
$combinedResults | Export-Csv -Path "network_interfaces.csv" -NoTypeInformation

# Display a message indicating that the export is complete
Write-Output "The network interface details have been exported to network_interfaces.csv"

# Display the combined results in a table format
$combinedResults | Format-Table -AutoSize
