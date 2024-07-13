
login-azurermaccount
select-azurermsubscription -SubscriptionName "Pay-As-You-Go"

$allWebApps = Get-AzureRmWebApp
$resourceGroups = $allWebApps | Select-Object 'ResourceGroup' -Unique
foreach($r in $resourceGroups)
{
    $rgName = $r.ResourceGroup    
    $webApps = Get-AzureRmWebApp -ResourceGroupName $rgName

    foreach($w in $webApps)
    {
        $webAppName = $w.Name        
        Write-Host Processing Webapp : $webAppName

        $webApp = Get-AzureRmWebApp -ResourceGroupName $rgName -Name $webAppName
        $appSettings = $webApp.SiteConfig.AppSettings

        # Extract AppSettings to CSV
        $appSettings.GetEnumerator() | 
                Sort-Object -Property Name -Descending |
                Select-Object -Property @{n='Key';e={$_.Name}},Value |
                Export-Csv -Path ~\$rgName-$webAppName.csv -NoTypeInformation -Append
    }    
}