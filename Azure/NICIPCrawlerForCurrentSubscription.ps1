# Get all network interfaces and their details
$nics = az network nic list --query '[].{Name:name, ResourceGroup:resourceGroup, IpConfigurations:ipConfigurations, VMId:virtualMachine.id, PrivateEndpoint:privateEndpoint.id}' -o json | ConvertFrom-Json

# Get all public IP addresses
$publicIps = az network public-ip list --query '[].{Id:id, PublicIP:ipAddress}' -o json | ConvertFrom-Json

# Get all private endpoints and their linked resources
$privateEndpoints = az network private-endpoint list --query '[].{Name:name, ResourceGroup:resourceGroup, LinkedResource:privateLinkServiceConnections[0].privateLinkServiceId}' -o json | ConvertFrom-Json

# Get all resources in the subscription
$allResources = az resource list --query '[].{Id:id, Type:type}' -o json | ConvertFrom-Json

# Initialize an array to hold the combined results
$combinedResults = @()

# Combine NIC details with public IP addresses and private endpoints
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
    $VMId = ($nic.VMId -split '/')[-1]
    $PrivateEndpointName = ($nic.PrivateEndpoint -split '/')[-1]

    # Get the linked resource for the private endpoint
    $linkedResource = $privateEndpoints | Where-Object { $_.Name -eq $PrivateEndpointName } | Select-Object -ExpandProperty LinkedResource -ErrorAction SilentlyContinue
    if (-not $linkedResource) {
        $linkedResource = "None"
    }

    # Cross reference the linked resource or VM with all resources to get the resource type
    $linkedResourceType = "None"
    if ($linkedResource -ne "None") {
        $resourceType = $allResources | Where-Object { $_.Id -eq $linkedResource } | Select-Object -ExpandProperty Type -ErrorAction SilentlyContinue
        if (-not $resourceType) {
            $linkedResourceType = "Unknown"
        } else {
            $linkedResourceType = $resourceType
        }
    } elseif ($VMId -ne "None") {
        $resourceType = $allResources | Where-Object { $_.Id -eq $nic.VMId } | Select-Object -ExpandProperty Type -ErrorAction SilentlyContinue
        if (-not $resourceType) {
            $linkedResourceType = "Unknown"
        } else {
            $linkedResourceType = $resourceType
        }
    }

    
    # Create a custom object with the combined details
    $combinedResult = [PSCustomObject]@{
        NicName          = $nic.Name
        ResourceGroup    = $nic.ResourceGroup
        PrivateIP        = $privateIp
        PublicIP         = $publicIp
        LinkedVM         = $VMId
        PrivateEndpoint  = $PrivateEndpointName
        LinkedResource   = ($linkedResource -split '/')[-1]
        LinkedResourceType = $linkedResourceType
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
