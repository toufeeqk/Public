# Get all subscriptions
$subscriptions = az account list --query '[].{Name:name, Id:id}' -o json | ConvertFrom-Json

# Initialize progress counter
$totalSubscriptions = $subscriptions.Count
$currentSubscriptionIndex = 0

# Initialize an array to hold the combined results for all subscriptions
$allCombinedResults = @()

# Iterate through each subscription
foreach ($subscription in $subscriptions) {
    $currentSubscriptionIndex++
    
    # Set the current subscription
    az account set --subscription $subscription.Id

    # Get all network interfaces and their details
    $nics = az network nic list --query '[].{Name:name, ResourceGroup:resourceGroup, IpConfigurations:ipConfigurations, VMId:virtualMachine.id, LinkedResource:privateEndpoint.id}' -o json | ConvertFrom-Json

    # Get all public IP addresses
    $publicIps = az network public-ip list --query '[].{Id:id, PublicIP:ipAddress}' -o json | ConvertFrom-Json

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
            Subscription    = $subscription.Name
            NicName         = $nic.Name
            ResourceGroup   = $nic.ResourceGroup
            PrivateIP       = $privateIp
            PublicIP        = $publicIp
            LinkedVM        = $VMId
            LinkedResource  = $linkedResourceName
        }

        # Add the custom object to the results array
        $allCombinedResults += $combinedResult
    }

    # Display a message indicating the current progress
    Write-Output "Processed network interface details for subscription '$($subscription.Name)' ($currentSubscriptionIndex of $totalSubscriptions)"
}

# Export the combined results to a single CSV file
$allCombinedResults | Export-Csv -Path "network_interfaces.csv" -NoTypeInformation

# Display a message indicating that the export is complete
Write-Output "The network interface details for all subscriptions have been exported to network_interfaces.csv"

# Display the combined results in a table format
$allCombinedResults | Format-Table -AutoSize
