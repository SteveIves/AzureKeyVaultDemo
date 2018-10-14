
# AzureKeyVaultDemo

This repository contains a sample Traditional Synergy application that
demonstrates how to encrypt one or more fields in a Synergy record,
using XCALL DATA_ENCRYT and XCALL DATA_DECRYPT. The encryption cipher
used by the code in this sample is AES256.

The encryption "password" is securely stored in and retrieved from an
instance of the Microsoft Azure Key Vault service.

Authentication with the Key Vault service is via an OAUTH2 bearer token
which is obtained from an instance of Microsoft Azure Active Directory.

In order to build and run the code in this example you will need:

- Microsoft Visual Studio 2017 (or later).
- Synergy/DE 10.3.3d (or later) including Synergy DBL Integration for Visual Studio.
- OpenSSL installed and the OpenSSL binaries correctly deployed to your DBL\BIN folders.

## Azure Key Vault Resources

- [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-whatis)
- [Getting Started with Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-get-started)
- [Key Vault Pricing](https://azure.microsoft.com/en-us/pricing/details/key-vault)
- [Installing and Configuring Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps?view=azurermps-5.1.1)
- [Use portal to create an Azure Active Directory application and service principal that can access resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal)
- [AzureRM.Resources Reference](https://docs.microsoft.com/en-us/powershell/module/azurerm.resources/?view=azurermps-5.1.1)

## Setting Up an Azure Key Vault

The following instructions will help you configure a new Key Vault endpoint, as well
as the required Azure Active Directory components required to authenticate to that
service. These instructions assume that you have an existing Azure subscription with
Active Directory already configured. This will be the case if your Azure subscription
is associated with an MSDN developer account.

- Check that you have the Azure PowerShell modules installed. Click [HERE](https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps?view=azurermps-5.1.1) for instructions.

- Open a PowerShell window and sign in to your Azure account with the following command:
  ```
  PS> Login-AzureRmAccount
  ```
- Create a new resource group
  ```
  PS> New-AzureRmResourceGroup –Name 'KeyVaultResourceGroup' –Location 'East US'
  ```
- Create a new key vault
  ```
  PS> New-AzureRmKeyVault -VaultName 'MyAppSecretsVault' -ResourceGroupName 'KeyVaultResourceGroup' -Location 'East US'
  ```
  The name of the vault must be unique. Having suiccessfully created a new Key Vault you will see
  various information displayed, some of which you will need in order to interact with the vault.
  Record the vault name (e.g. MyAppSecretsVault) and the Vault URI (e.g. https://MyAppSecretsVault.vault.azure.net)

- Add a Secret to the Vault
  To add a secret to the vault, which is a password named EncryptionPassword and has the value of Pa$$w0rd to Azure Key Vault, first convert the value of Pa$$w0rd to a secure string by typing these commands:
  ```
  PS> $secretvalue = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
  PS> $secret = Set-AzureKeyVaultSecret -VaultName 'MyAppSecretsVault' -Name 'EncryptionPassword' -SecretValue $secretvalue
  ```
  You can display the URI that will allow you to retrieve the secret in the future:
  ```
  PS> $secret.Id
  ```
  You will see the URL displayed, it will look something like this:

  https://myappsecretsvault.vault.azure.net:443/secrets/EncryptionPassword/943448d311d04bfbaeca4dd0ef83b557

  You should record the URL for later use.

  You can view information about your new secret with this command:
  ```
  PS> Get-AzureKeyVaultSecret –VaultName 'MyAppSecretsVault'
  ```
  And you can view the value associated with the secret like this:
  ```
  PS> (get-azurekeyvaultsecret -vaultName "MyAppSecretsVault" -name "EncryptionPassword").SecretValueText
  ```
## Registering An Application with Active Directory
  
Applications that use a key vault must authenticate by using a token from Azure Active Directory.
To do this, the owner of the application must first register the application in their Azure Active
Directory. At the end of registration, the application owner gets the following values:

- An Application ID
- An authentication key (also known as the shared secret).

The application must present both these values to Azure Active Directory, to get an access token,
which can then be used to access the key vault REST API endpoint.

To register an application in Azure Active Directory:

1. Sign in to your Azure Portal.
2. In the main portal menu on the left, click "Azure Active Directory".
3. In the Azure Active Directory menu, click "App registrations".
4. Near the top of the App registrations window, click "New application registration".
5. In the Create blade:
   - Enter a name for the application, such as "Key Vault Access".
   - Set the Application type to "Web app / API".
   - Set the Sign-on URL to the url of the key vault service (e.g. )
   - Click the "Create" button
6. Back in the Aoo registrations window, click on the new application to display it's property pages.
7. Record the "Application ID" GUID
8. Click on the "All Settings" Link
9. In the Settings blade, click on "Keys"
10. In the "Keys" window
    - In the DESCRIPTION field enter "PermanentKey"
    - In the EXPIRES dropdown select "Never expires"
    - Click the Save button at the top of the page
11. Immediately copy and record the "Application Secret" that is displayed below the VALUE column.
    This is the only time the value will ever be displayed.


### PowerShell Workflow

    ```
    PS> $sp = New-AzureRmADApplication -DisplayName "Key Vault Test" -IdentifierUris https://myappsecretsvault.vault.azure.net
    ```

## Assigning the Application to a Role

Next your will need to assign the Active Directory application definition that you have
just created to a Role.

1. In the main menu panel of the Azure Portal, select "Subscriptions".
2. In the Subscriptions blade, select the subscription that you are working with.
3. Select "Access control (IAM).
4. In the Access control (IAM) window, click "Add".
5. In the add permissions window:
   - Set the "Role" dropdown to "Reader".
   - In the "Assign access to" dropdown select "Azure AD user, group or application".
   - In the "Select" field search for then select the name of the AD application that
     you created in the previous step (e.g. "Key Vault Access").
     Click the "Save" button.
6. XXX

## Recording the Active Directory Tenant ID

You will need to locate and record one final piece of information, which is the "Tenant ID" of
your Azure Active Directory instance. To so this, execute the following command:

```
PS> (Get-AzureRmContext).Tenant.TenantId
```

Then record the GUID that is displayed as you "AD Tenant ID"

## Authorize the Application to Access the Key Vault

The next step is to authorize the application that you just defined in the Azure Active Directory
to access the secrets stored in the key vault. Back in the PowerShell window, use the following
command, replacing <application_id> with the GUID of the Application ID that you recorded earlier:

```
PS> Set-AzureRmKeyVaultAccessPolicy -VaultName 'MyAppSecretsVault' -ServicePrincipalName <application_id> -PermissionsToSecrets Get -ResourceGroupName 'KeyVaultResourceGroup'
```

## Editing the Sample Code to Access Your Key Vault

Having configured your Azure Key Vault and Active Directory services you will need to record
several pieces of information in the source code of the sample application.

Copy the contents of AzureDataRenameMe.dbl to AzureData.def and then declare values for the following
identifiers:

| Identifier              | Value                                                              |
| ----------------------- | ------------------------------------------------------------------ |
| AZURE_AD_TENANT_ID      | Insert your "AD Tenant ID" GUID |
| AZURE_AD_APP_ID         | Insert your "Application ID" GUID |
| AZURE_AD_APP_SECRET     | Insert your "Application Secret" value |
| KEYVAULT_INSTANCE       | Insert the HOST portion of your key vault URI (e.g. "MyAppSecretsVault.vault.azure.net") |
| KEYVAULT_SECRET_NAME    | Insert the NAME of the secret to be accessed (e.g. "EncryptionPassword")|
| KEYVAULT_SECRET_VERSION | Insert the VERSION of the secret to be accessed. This is the GUID value at the end of the URL that was displayed when you used the PowerShell command $secret.Id |
