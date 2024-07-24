# Initialize an array to store the results
$results = @()

# Get all subscriptions
$subscriptions = az account list --query "[].{name:name, id:id}" | ConvertFrom-Json

foreach ($subscription in $subscriptions) {
    $subscriptionName = $subscription.name
    $subscriptionId = $subscription.id
    
    Write-Output "Processing Subscription: $subscriptionName"
    
    # Set the subscription context
    az account set --subscription $subscriptionId
    
    # Get all private DNS zones in the subscription
    $dnsZones = az network private-dns zone list --query "[].{name:name, resourceGroup:resourceGroup}" | ConvertFrom-Json
    
    # Initialize a hashtable to store all records by zone
    $allRecordsByZone = @{}
    
    # Loop through each DNS zone and list records
    foreach ($zone in $dnsZones) {
        $zoneName = $zone.name
        $resourceGroup = $zone.resourceGroup
        
        Write-Output "Fetching records for Zone: $zoneName, Resource Group: $resourceGroup"
        
        # List all records in the DNS zone
        $records = az network private-dns record-set list --zone-name $zoneName --resource-group $resourceGroup --query "[].{name:name, type:type}" | ConvertFrom-Json
        
        # Store the records in the hashtable
        $allRecordsByZone["$zoneName|$resourceGroup"] = $records
    }
    
    # Process the records from the hashtable
    foreach ($key in $allRecordsByZone.Keys) {
        $zoneName, $resourceGroup = $key -split '\|'
        $records = $allRecordsByZone[$key]
        
        foreach ($record in $records) {
            $recordName = $record.name
            $recordType = $record.type
            
            Write-Output "Processing Record Name: $recordName, Type: $recordType in Zone: $zoneName"
            
            # Get record details based on type
            switch ($recordType) {
                "Microsoft.Network/privateDnsZones/A" {
                    $details = az network private-dns record-set a show --zone-name $zoneName --resource-group $resourceGroup --name $recordName --query "{ttl:ttl, value:aRecords[].ipv4Address}" | ConvertFrom-Json
                }
                "Microsoft.Network/privateDnsZones/AAAA" {
                    $details = az network private-dns record-set aaaa show --zone-name $zoneName --resource-group $resourceGroup --name $recordName --query "{ttl:ttl, value:aaaaRecords[].ipv6Address}" | ConvertFrom-Json
                }
                "Microsoft.Network/privateDnsZones/CNAME" {
                    $details = az network private-dns record-set cname show --zone-name $zoneName --resource-group $resourceGroup --name $recordName --query "{ttl:ttl, value:cnameRecord.cname}" | ConvertFrom-Json
                }
                "Microsoft.Network/privateDnsZones/MX" {
                    $details = az network private-dns record-set mx show --zone-name $zoneName --resource-group $resourceGroup --name $recordName --query "{ttl:ttl, value:mxRecords[].exchange}" | ConvertFrom-Json
                }
                "Microsoft.Network/privateDnsZones/TXT" {
                    $details = az network private-dns record-set txt show --zone-name $zoneName --resource-group $resourceGroup --name $recordName --query "{ttl:ttl, value:txtRecords[].value}" | ConvertFrom-Json
                }
            }
            
            $ttl = $details.ttl
            $value = $details.value
            
            Write-Output "    TTL: $ttl, Value: $($value -join ', ')"
            
            # Add the result to the array
            $results += [pscustomobject]@{
                SubscriptionName = $subscriptionName
                ResourceGroup   = $resourceGroup
                RecordName      = $recordName
                ZoneName        = $zoneName
                Value           = ($value -join ', ')
                TTL             = $ttl
                RecordType      = $recordType
            }
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "PrivateDnsRecords.csv" -NoTypeInformation
