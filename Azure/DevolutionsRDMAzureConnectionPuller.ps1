$ExportPath = ('C:\Temp\' + (Get-Date -Format yyyy-MM-dd) + '_' + 'PLACEHOLDER' + '.csv')
$Subscriptions = @('Dev', 'QA', 'UAT', 'Prod')
$pscustomobjects = @()
foreach ($subscription in $Subscriptions) {
  Try {
    $null = Set-AzContext -Subscription $subscription -ErrorAction Stop
  }
  Catch {
    $null = Login-AzAccount
    $null = Set-AzContext -Subscription $subscription -ErrorAction Stop
  }
  Write-Output "Subscription $($subscription)..."
  $ResourceGroups = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like '*-PLACEHOLDER-*' }).ResourceGroupName
  Foreach ($ResourceGroup in $ResourceGroups) {

    If ($ResourceGroup.Length -lt 14) {
      Throw "Expecting resource group name to be at least 14 characters: $ResourceGroup"
    }

    $CSVHeader = [pscustomobject]@{
      ConnectionType     = "ConnectionType"
      ConnectionSubType  = "ConnectionSubType"
      SubMode            = "SubMode"
      Name               = "Name"
      Group              = "Group"
      Description        = "Description"
      Expiration         = "Expiration"
      Parent             = "Parent"
      Host               = "Host"
      Port               = "Port"
      CredentialUserName = "CredentialUserName"
      CredentialDomain   = "CredentialDomain"
      CredentialPassword = "CredentialPassword"
      OpenInConsole      = "OpenInConsole"
    }

    Write-Output "Starting VM Import for" $ResourceGroup
  
    $vms = Get-AzVM -ResourceGroupName $ResourceGroup
    $networkInterfaceCollection = Get-AzNetworkInterface -ResourceGroupName $ResourceGroup
  
    $pscustomobjects += foreach ($vm in $vms) {
      $nic = $networkInterfaceCollection | Where-Object { $_.Id -ieq $vm.NetworkProfile.NetworkInterfaces[0].Id }
      $rg = $vm.ResourceGroupName
      $prvIP = $nic.IpConfigurations | select-object -ExpandProperty PrivateIpAddress
        
      If ($prvIP -isnot [System.String]) {
        $prvIP = $prvIP[0]
      }

      $displayName = "$($vm.Name) - $prvIP"

      $osType = $vm.StorageProfile.OsDisk.OsType

      switch ($osType) {
        'Linux' {
          $ConnectionType = "SSH Shell"
          $SubMode = "0"
        }
        'Microsoft' {
          $ConnectionType = "Microsoft Remote Desktop (RDP)"
          $SubMode = "0"
        }
      }

      [pscustomobject]@{
        ConnectionType     = $ConnectionType
        SubMode            = $SubMode
        Name               = $displayName
        Group              = "Azure\$Subscription\$rg"
        Description        = $($vm.Name)
        Host               = $prvIP
        CredentialUserName = "PLACEHOLDER"
        Domain             = ""
        Password           = ""
      }
    }
  }
}
Write-Output "Remote Desktop List: $ExportPath"

$pscustomobjects | Format-Table
$pscustomobjects | Export-Csv $ExportPath -NoTypeInformation

Write-Output( "Export complete..." )
