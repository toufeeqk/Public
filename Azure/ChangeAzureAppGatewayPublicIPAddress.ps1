# Define variables
$resourceGroupName = "resourceGroupName"
$appGatewayName = "appGatewayName"
$newPublicIpName = "newPublicIpName"

# Get the App Gateway
$appGateway = Get-AzApplicationGateway -ResourceGroupName $resourceGroupName -Name $appGatewayName

# Stop the Application Gateway
Stop-AzApplicationGateway -ApplicationGateway $appGateway

# Get the new Public IP
$newPublicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name $newPublicIpName

# Create a new frontend IP configuration with the new Public IP
$newFrontendIpConfig = New-AzApplicationGatewayFrontendIPConfig -Name "newFrontendIpConfig" -PublicIPAddress $newPublicIp

# Update the frontend IP configuration
$appGateway.FrontendIPConfigurations[0] = $newFrontendIpConfig

# Set the updated App Gateway
Set-AzApplicationGateway -ApplicationGateway $appGateway

# Start the Application Gateway
Start-AzApplicationGateway -ApplicationGateway $appGateway
