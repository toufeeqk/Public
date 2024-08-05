Add-Type -AssemblyName System.Windows.Forms

# Function to create a multi-selection form with a select all option
function Show-MultiSelectForm {
    param (
        [string]$title,
        [string[]]$options
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Width = 400
    $form.Height = 350

    $checkedListBox = New-Object System.Windows.Forms.CheckedListBox
    $checkedListBox.Width = 350
    $checkedListBox.Height = 250
    $checkedListBox.Location = New-Object System.Drawing.Point(20, 20)
    $checkedListBox.Items.AddRange($options)
    $form.Controls.Add($checkedListBox)

    $selectAllButton = New-Object System.Windows.Forms.Button
    $selectAllButton.Text = "Select All"
    $selectAllButton.Width = 100
    $selectAllButton.Height = 30
    $selectAllButton.Location = New-Object System.Drawing.Point(20, 280)
    $selectAllButton.Add_Click({
        for ($i = 0; $i -lt $checkedListBox.Items.Count; $i++) {
            $checkedListBox.SetItemChecked($i, $true)
        }
    })
    $form.Controls.Add($selectAllButton)

    $button = New-Object System.Windows.Forms.Button
    $button.Text = "OK"
    $button.Width = 100
    $button.Height = 30
    $button.Location = New-Object System.Drawing.Point(250, 280)
    $button.Add_Click({ $form.Tag = $true; $form.Close() })
    $form.Controls.Add($button)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Width = 100
    $cancelButton.Height = 30
    $cancelButton.Location = New-Object System.Drawing.Point(140, 280)
    $cancelButton.Add_Click({ $form.Tag = $false; $form.Close() })
    $form.Controls.Add($cancelButton)

    $form.ShowDialog()
    return [PSCustomObject]@{
        SelectedItems = $checkedListBox.CheckedItems
        IsConfirmed = $form.Tag
    }
}

# Get all subscriptions
$subscriptions = az account list --query "[].{Name:name, Id:id}" -o json | ConvertFrom-Json
$subscriptionOptions = $subscriptions | ForEach-Object { "$($_.Name) ($($_.Id))" }

# Show subscription selection form
$subscriptionSelection = Show-MultiSelectForm -title "Select Subscriptions" -options $subscriptionOptions
if (-not $subscriptionSelection.IsConfirmed -or $subscriptionSelection.SelectedItems.Count -eq 0) {
    Write-Host "No subscriptions selected or selection was canceled. Exiting."
    exit
}
$subscriptionIds = $subscriptionSelection.SelectedItems | ForEach-Object { $_ -match '\((.*?)\)' | Out-Null; $matches[1] }

# Initialize an array to hold the output
$output = @()

foreach ($subscriptionId in $subscriptionIds) {
    Write-Host "Processing subscription: $subscriptionId"
    az account set --subscription $subscriptionId

    # Get all resource groups in the selected subscription
    $resourceGroups = az group list --query "[].{Name:name}" -o json | ConvertFrom-Json
    $resourceGroupOptions = $resourceGroups | ForEach-Object { $_.Name }

    # Show resource group selection form
    $resourceGroupSelection = Show-MultiSelectForm -title "Select Resource Groups for Subscription $subscriptionId" -options $resourceGroupOptions
    if (-not $resourceGroupSelection.IsConfirmed -or $resourceGroupSelection.SelectedItems.Count -eq 0) {
        Write-Host "No resource groups selected for subscription $subscriptionId or selection was canceled. Skipping."
        continue
    }

    foreach ($resourceGroupName in $resourceGroupSelection.SelectedItems) {
        Write-Host "Processing resource group: $resourceGroupName"
        # Get all resources in the resource group
        $resources = az resource list --resource-group $resourceGroupName --query "[].{Name:name, Type:type, ID:id}" -o json | ConvertFrom-Json

        # Iterate through each resource
        foreach ($resource in $resources) {
            Write-Host "Processing resource: $($resource.Name)"
            # Get the provisioning state of the resource
            $provisioningState = az resource show --ids $resource.ID --query "properties.provisioningState" -o tsv
            Write-Host "Resource: $($resource.Name), Provisioning State: $provisioningState"
            $output += [pscustomobject]@{
                SubscriptionId   = $subscriptionId
                ResourceGroupName = $resourceGroupName
                ResourceName     = $resource.Name
                ResourceType     = $resource.Type
                ProvisioningState = $provisioningState
            }
            
            # Check if the resource has dependencies
            $dependencies = az resource show --ids $resource.ID --query "properties.dependencies" -o json | ConvertFrom-Json
            if ($dependencies) {
                foreach ($dependency in $dependencies) {
                    $dependencyId = $dependency.id
                    $dependencyState = az resource show --ids $dependencyId --query "properties.provisioningState" -o tsv
                    Write-Host "Dependency: $dependencyId, Provisioning State: $dependencyState"
                    $output += [pscustomobject]@{
                        SubscriptionId   = $subscriptionId
                        ResourceGroupName = $resourceGroupName
                        ResourceName     = $dependencyId
                        ResourceType     = "Dependency"
                        ProvisioningState = $dependencyState
                    }
                }
            }
        }
    }
}

# Save output to CSV
$output | Export-Csv -Path "ProvisioningStates.csv" -NoTypeInformation
