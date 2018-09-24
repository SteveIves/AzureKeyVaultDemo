
#--------------------------------------------------------------------------
# Name things

$location = "West US"
$resourceGroupName = "Miscellaneous"
$keyVaultName = "SteveIvesKeyVault"
$secretName = "EncryptionPassword"
$adApplicationName = "SteveIvesKeyVaultApp"

#--------------------------------------------------------------------------
# Login to your Azure account

Login-AzureRmAccount

#--------------------------------------------------------------------------
# Create a new Resource Group
#
$resourceGroup = New-AzureRmResourceGroup –Name $resourceGroupName –Location $location
#
#--------------------------------------------------------------------------
# Create a new Key Vault

$keyVault = New-AzureRmKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceGroup.Location

#--------------------------------------------------------------------------
# Add a secret to the key vault

$encryptionPassword = ConvertTo-SecureString ([guid]::NewGuid()) -AsPlainText -Force
$secret = Set-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name $secretName -SecretValue $encryptionPassword

#--------------------------------------------------------------------------
#Create new AD Application
#
# This is based on this: https://stackoverflow.com/questions/36833464/azure-ad-application-adding-a-key-via-powershell
# but modified with a new type: Microsoft.Azure.Graph.RBAC.Version1_6.ActiveDirectory.PSADPa‌​sswordCredential

Import-Module AzureRM.Resources
$adCredential = New-Object Microsoft.Azure.Graph.RBAC.Version1_6.ActiveDirectory.PSADPasswordCredential
$adCredential.KeyId = [guid]::NewGuid()
$adCredential.StartDate = Get-Date
$adCredential.EndDate = (Get-Date).AddYears(100)
$adCredential.Password = [guid]::NewGuid()

$adApplication = New-AzureRmADApplication –DisplayName $adApplicationName -IdentifierUris $keyvault.VaultUri -PasswordCredentials $adCredential

#--------------------------------------------------------------------------
# Assign AD Application to Role

# Create a Service Principal for the app
$svcprincipal = New-AzureRmADServicePrincipal -ApplicationId $adApplication.ApplicationId

# Assign the Contributor RBAC role to the service principal

Sleep 20 #Need retry logic here?

$roleassignment = New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $adApplication.ApplicationId.Guid

#--------------------------------------------------------------------------
# Authorize the application to access the Key Vault

Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVault.VaultName -ServicePrincipalName $adApplication.ApplicationId -PermissionsToSecrets get,list,set,delete,backup,restore,recover,purge -ResourceGroupName $resourceGroup.ResourceGroupName
 
#--------------------------------------------------------------------------
# Display the results

"--------------------------------------------------------------------------"
"RESULTS:"

"Key vault URI  : " + $keyVault.VaultUri
"Secret name    : " + $secret.Name
"Secret version : " + $secret.Version
"Secret value   : " + $secret.SecretValueText
"AD Tenant ID   : " + (Get-AzureRmContext).Tenant.TenantId
"AD App ID      : " + $adApplication.ApplicationId
"AD App Secret  : " + $adCredential.Password

"--------------------------------------------------------------------------"
