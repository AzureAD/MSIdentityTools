[![PSGallery Version](https://img.shields.io/powershellgallery/v/MSIdentityTools.svg?style=flat&logo=powershell&label=PSGallery%20Version)](https://www.powershellgallery.com/packages/MSIdentityTools) 
[![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/MSIdentityTools.svg?style=flat&logo=powershell&label=PSGallery%20Downloads)](https://www.powershellgallery.com/packages/MSIdentityTools)
[![PSGallery Platform](https://img.shields.io/powershellgallery/p/MSIdentityTools.svg?style=flat&logo=powershell&label=PSGallery%20Platform)](https://www.powershellgallery.com/packages/MSIdentityTools)

The Microsoft Identity Tools PowerShell module provides various tools for performing enhanced Identity administration activities. It is intended to address more complex business scenarios that can't be met solely with the use of MS Graph PowerShell SDK module.

## What is contained in the MSIdentityTools module?
A collection of cmdlets that use the MS Graph SDK PowerShell module to simplify common tasks for administrators of Azure AD tenants.

 
## How do I install the module?
 
The module can be found and installed from the PowerShell gallery at [PowerShell Gallery: MSIdentity Tools](https://www.powershellgallery.com/packages/MSIdentityTools) or can be downloaded from the releases page on this repo.

## What are the cmdlets in this module?
View the latest list of cmdlets on the [cmdlet summary](../../wiki/Cmdlets) page.
| Command | Synopsys |
| --- | --- |
| [Add-MsIdServicePrincipal](https://github.com/AzureAD/MSIdentityTools/wiki/Add-MsIdServicePrincipal) | Create service principal for existing application registration |
| [Confirm-MsIdJwtTokenSignature](https://github.com/AzureAD/MSIdentityTools/wiki/Confirm-MsIdJwtTokenSignature) | Validate the digital signature for JSON Web Token. |
| [ConvertFrom-MsIdAadcAadConnectorSpaceDn](https://github.com/AzureAD/MSIdentityTools/wiki/ConvertFrom-MsIdAadcAadConnectorSpaceDn) | Convert Azure AD connector space object Distinguished Name (DN) in AAD Connect |
| [ConvertFrom-MsIdAadcSourceAnchor](https://github.com/AzureAD/MSIdentityTools/wiki/ConvertFrom-MsIdAadcSourceAnchor) | Convert Azure AD Connect metaverse object sourceAnchor or Azure AD ImmutableId to sourceGuid. |
| [ConvertFrom-MsIdJwtToken](https://github.com/AzureAD/MSIdentityTools/wiki/ConvertFrom-MsIdJwtToken) | Convert Msft Identity token structure to PowerShell object. |
| [ConvertFrom-MsIdSamlMessage](https://github.com/AzureAD/MSIdentityTools/wiki/ConvertFrom-MsIdSamlMessage) | Convert SAML Message structure to PowerShell object. |
| [ConvertFrom-MsIdUniqueTokenIdentifier](https://github.com/AzureAD/MSIdentityTools/wiki/ConvertFrom-MsIdUniqueTokenIdentifier) | Convert Azure AD Unique Token Identifier to Request Id. |
| [Expand-MsIdJwtTokenPayload](https://github.com/AzureAD/MSIdentityTools/wiki/Expand-MsIdJwtTokenPayload) | Extract Json Web Token (JWT) payload from JWS structure to PowerShell object. |
| [Find-MsIdUnprotectedUsersWithAdminRoles](https://github.com/AzureAD/MSIdentityTools/wiki/Find-MsIdUnprotectedUsersWithAdminRoles) | Find Users with Admin Roles that are not registered for MFA |
| [Get-MsIdAdfsSamlToken](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdAdfsSamlToken) | Initiates a SAML logon request to and AD FS server to generate log activity and returns the user token. |
| [Get-MsIdAdfsSampleApp](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdAdfsSampleApp) | Returns the list of availabe sample AD FS relyng party trust applications available in this module. These applications do NOT use real endpoints and are meant to be used as test applications. |
| [Get-MsIdAdfsWsFedToken](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdAdfsWsFedToken) | Initiates a Ws-Fed logon request to and AD FS server to generate log activity and returns the user token. |
| [Get-MsIdAdfsWsTrustToken](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdAdfsWsTrustToken) | Initiates a Ws-Trust logon request to and AD FS server to generate log activity and returns the user token. |
| [Get-MsIdApplicationIdByAppId](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdApplicationIdByAppId) | Lookup Application Registration by AppId |
| [Get-MsIdAuthorityUri](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdAuthorityUri) | Build Microsoft Identity Provider Authority URI |
| [Get-MsIdAzureIpRange](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdAzureIpRange) | Get list of IP ranges for Azure |
| [Get-MsIdCrossTenantAccessActivity](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdCrossTenantAccessActivity) | Gets cross tenant user sign-in activity |
| [Get-MsIdGroupWithExpiration](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdGroupWithExpiration) | Return groups with an expiration date via lifecycle policy. |
| [Get-MsIdGroupWritebackConfiguration](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdGroupWritebackConfiguration) | Gets the group writeback configuration for the group ID |
| [Get-MsIdHasMicrosoftAccount](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdHasMicrosoftAccount) | Returns true if the user's mail is a Microsoft Account |
| [Get-MsIdInactiveSignInUser](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdInactiveSignInUser) | Retrieve Users who have not had interactive sign ins since XX days ago |
| [Get-MsIdIsViralUser](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdIsViralUser) | Returns true if the user's mail domain is a viral (unmanaged) Azure AD tenant. |
| [Get-MsIdMsftIdentityAssociation](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdMsftIdentityAssociation) | Parse Microsoft Identity Association Configuration for a Public Domain (such as published apps) |
| [Get-MsIdO365Endpoints](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdO365Endpoints) | Get list of URLs and IP ranges for O365 |
| [Get-MsIdOpenIdProviderConfiguration](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdOpenIdProviderConfiguration) | Parse OpenId Provider Configuration and Keys |
| [Get-MsIdProvisioningLogStatistics](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdProvisioningLogStatistics) | Get Statistics for Set of Azure AD Provisioning Logs |
| [Get-MsIdSamlFederationMetadata](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdSamlFederationMetadata) | Parse Federation Metadata |
| [Get-MsIdServicePrincipalIdByAppId](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdServicePrincipalIdByAppId) | Lookup Service Principal by AppId |
| [Get-MsIdSigningKeyThumbprint](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdSigningKeyThumbprint) | Get signing keys used by Azure AD. |
| [Get-MsIdUnmanagedExternalUser](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdUnmanagedExternalUser) | Returns a list of all the external users in the tenant that are unmanaged (viral users). |
| [Get-MsIdUnredeemedInvitedUser](https://github.com/AzureAD/MSIdentityTools/wiki/Get-MsIdUnredeemedInvitedUser) | Retrieve Users who have not had interactive sign ins since XX days ago |
| [Import-MsIdAdfsSampleApp](https://github.com/AzureAD/MSIdentityTools/wiki/Import-MsIdAdfsSampleApp) | Imports a list availabe sample AD FS relyng party trust applications available in this module, the list is created by the Get-MsIdAdfsSampleApps cmdlet. These applications do NOT use real endpoints and are meant to be used as test applications. |
| [Import-MsIdAdfsSamplePolicy](https://github.com/AzureAD/MSIdentityTools/wiki/Import-MsIdAdfsSamplePolicy) | Imports the 'MsId Block Off Corp and VPN' sample AD FS access control policy. This policy is meant to be used as test policy. |
| [Invoke-MsIdAzureAdSamlRequest](https://github.com/AzureAD/MSIdentityTools/wiki/Invoke-MsIdAzureAdSamlRequest) | Invoke Saml Request on Azure AD. |
| [New-MsIdClientSecret](https://github.com/AzureAD/MSIdentityTools/wiki/New-MsIdClientSecret) | Generate Random Client Secret for application registration or service principal in Azure AD. |
| [New-MsIdSamlRequest](https://github.com/AzureAD/MSIdentityTools/wiki/New-MsIdSamlRequest) | Create New Saml Request. |
| [New-MsIdTemporaryUserPassword](https://github.com/AzureAD/MSIdentityTools/wiki/New-MsIdTemporaryUserPassword) | Generate Random password for user in Azure AD. |
| [New-MsIdWsTrustRequest](https://github.com/AzureAD/MSIdentityTools/wiki/New-MsIdWsTrustRequest) | Create a WS-Trust request. |
| [Reset-MsIdExternalUser](https://github.com/AzureAD/MSIdentityTools/wiki/Reset-MsIdExternalUser) | Resets the redemption state of an external user. |
| [Resolve-MsIdAzureIpAddress](https://github.com/AzureAD/MSIdentityTools/wiki/Resolve-MsIdAzureIpAddress) | Lookup Azure IP address for Azure Cloud, Region, and Service Tag. |
| [Resolve-MsIdTenant](https://github.com/AzureAD/MSIdentityTools/wiki/Resolve-MsIdTenant) | Resolve TenantId or DomainName to an Azure AD Tenant |
| [Revoke-MsIdServicePrincipalConsent](https://github.com/AzureAD/MSIdentityTools/wiki/Revoke-MsIdServicePrincipalConsent) | Revoke Existing Consent to an Azure AD Service Principal. |
| [Set-MsIdServicePrincipalVisibleInMyApps](https://github.com/AzureAD/MSIdentityTools/wiki/Set-MsIdServicePrincipalVisibleInMyApps) | Toggles whether application service principals are visible when launching myapplications.microsoft.com (MyApps) |
| [Set-MsIdWindowsTlsSettings](https://github.com/AzureAD/MSIdentityTools/wiki/Set-MsIdWindowsTlsSettings) | Set TLS settings on Windows OS to use more secure TLS protocols. |
| [Show-MsIdJwtToken](https://github.com/AzureAD/MSIdentityTools/wiki/Show-MsIdJwtToken) | Show Json Web Token (JWT) decoded in Web Browser using diagnostic web app. |
| [Show-MsIdSamlToken](https://github.com/AzureAD/MSIdentityTools/wiki/Show-MsIdSamlToken) | Show Saml Security Token decoded in Web Browser using diagnostic web app. |
| [Split-MsIdEntitlementManagementConnectedOrganization](https://github.com/AzureAD/MSIdentityTools/wiki/Split-MsIdEntitlementManagementConnectedOrganization) | Split elements of a connectedOrganization |
| [Test-MsIdAzureAdDeviceRegConnectivity](https://github.com/AzureAD/MSIdentityTools/wiki/Test-MsIdAzureAdDeviceRegConnectivity) | Test connectivity on Windows OS for Azure AD Device Registration |
| [Test-MsIdCBATrustStoreConfiguration](https://github.com/AzureAD/MSIdentityTools/wiki/Test-MsIdCBATrustStoreConfiguration) | Test & report for common mis-configuration issues with the Entra ID Certificate Trust Store |
| [Update-MsIdApplicationSigningKeyThumbprint](https://github.com/AzureAD/MSIdentityTools/wiki/Update-MsIdApplicationSigningKeyThumbprint) | Update a Service Princpal's preferredTokenSigningKeyThumbprint to the specified certificate thumbprint |
| [Update-MsIdGroupWritebackConfiguration](https://github.com/AzureAD/MSIdentityTools/wiki/Update-MsIdGroupWritebackConfiguration) | Update an Azure AD cloud group settings to writeback as an AD on-premises group |


## Support
For issues, questions, and feature requests please review the guidance on the [Support](https://github.com/AzureAD/MSIdentityTools/blob/main/SUPPORT.md) page for this project for filing issues.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
