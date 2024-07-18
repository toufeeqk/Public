# Get all subscriptions
$subscriptions = az account list --query '[].{id:id, name:name}' -o json | ConvertFrom-Json

# Initialize an empty array to store public IP details
$allPublicIpDetails = @()

# Iterate through each subscription
foreach ($subscription in $subscriptions) {
    Write-Host "Processing subscription: $($subscription.name)"
    
    # Set the current subscription
    az account set --subscription $subscription.id
    
    # Get all public IP addresses and their details for the current subscription
    $publicIpDetails = az network public-ip list --query '[].{Name:name, ResourceGroup:resourceGroup, Location:location, IPAddress:ipAddress, AllocationMethod:publicIPAllocationMethod, SKU:sku.name, IPVersion:ipAddressVersion, AssociatedTo:ipConfiguration.id}' -o json
    
    # Process the details to extract the resource name from the associated resource ID
    $publicIpDetailsProcessed = $publicIpDetails | ConvertFrom-Json | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name AssociatedResourceName -Value ($_.AssociatedTo -split '/')[-3]
        $_ | Add-Member -MemberType NoteProperty -Name SubscriptionName -Value $subscription.name
        $_
    }
    
    # Add the processed details to the allPublicIpDetails array
    $allPublicIpDetails += $publicIpDetailsProcessed
}

# Output the processed details of all public IPs
$allPublicIpDetails | Format-Table Name, ResourceGroup, Location, IPAddress, AllocationMethod, SKU, IPVersion, AssociatedResourceName, SubscriptionName -AutoSize

# Export the combined results to a CSV file
$allPublicIpDetails | Export-Csv -Path "Public_IPs.csv" -NoTypeInformation