[![PSGallery Version](https://img.shields.io/powershellgallery/v/MSIdentityTools.svg?style=flat&logo=powershell&label=PSGallery%20Version)](https://www.powershellgallery.com/packages/MSIdentityTools) 
[![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/MSIdentityTools.svg?style=flat&logo=powershell&label=PSGallery%20Downloads)](https://www.powershellgallery.com/packages/MSIdentityTools)
[![PSGallery Platform](https://img.shields.io/powershellgallery/p/MSIdentityTools.svg?style=flat&logo=powershell&label=PSGallery%20Platform)](https://www.powershellgallery.com/packages/MSIdentityTools)

The Microsoft Identity Tools PowerShell module provides various tools for performing enhanced Identity administration activities. It is intended to address more complex business scenarios that can't be met solely with the use of MS Graph PowerShell SDK module.

## What is contained in the MSIdentityTools module?
A collection of cmdlets that use the MS Graph SDK PowerShell module to simplify common tasks for administrators of Azure AD tenants.

You can find a description of each cmdlet and it's usage documentation in the repo [wiki](https://github.com/AzureAD/MSIdentityTools/wiki)
  
## How do I install the module?
 
The module can be found and installed from the PowerShell gallery at [PowerShell Gallery: MSIdentity Tools](https://www.powershellgallery.com/packages/MSIdentityTools) or can be downloaded from the releases page on this repo.

## What are the cmdlets in this module?

| Command | Synopsys |
| --- | --- |
| [Confirm-MsIdJwtTokenSignature](../../wiki/Confirm-MsIdJwtTokenSignature) | Validate the digital signature for JSON Web Token. |
| [ConvertFrom-MsIdAadcAadConnectorSpaceDn](../../wiki/ConvertFrom-MsIdAadcAadConnectorSpaceDn) | Convert Azure AD connector space object Distinguished Name (DN) in AAD Connect |
| [ConvertFrom-MsIdAadcSourceAnchor](../../wiki/ConvertFrom-MsIdAadcSourceAnchor) | Convert Azure AD Connect metaverse object sourceAnchor or Azure AD ImmutableId to sourceGuid. |
| [ConvertFrom-MsIdJwtToken](../../wiki/ConvertFrom-MsIdJwtToken) | Convert Msft Identity token structure to PowerShell object. |
| [ConvertFrom-MsIdSamlMessage](../../wiki/ConvertFrom-MsIdSamlMessage) | Convert SAML Message structure to PowerShell object. |
| [ConvertFrom-MsIdUniqueTokenIdentifier](../../wiki/ConvertFrom-MsIdUniqueTokenIdentifier) | Convert Azure AD Unique Token Identifier to Request Id. |
| [Expand-MsIdJwtTokenPayload](../../wiki/Expand-MsIdJwtTokenPayload) | Extract Json Web Token (JWT) payload from JWS structure to PowerShell object. |
| [Find-MsIdUnprotectedUsersWithAdminRoles](../../wiki/Find-MsIdUnprotectedUsersWithAdminRoles) | Find Users with Admin Roles that are not registered for MFA |
| [Get-MsIdAdfsSamlToken](../../wiki/Get-MsIdAdfsSamlToken) | Initiates a SAML logon request to and AD FS server to generate log activity and returns the user token. |
| [Get-MsIdAdfsSampleApp](../../wiki/Get-MsIdAdfsSampleApp) | Returns the list of availabe sample AD FS relyng party trust applications available in this module. These applications do NOT use real endpoints and are meant to be used as test applications. |
| [Get-MsIdAdfsWsFedToken](../../wiki/Get-MsIdAdfsWsFedToken) | Initiates a Ws-Fed logon request to and AD FS server to generate log activity and returns the user token. |
| [Get-MsIdAdfsWsTrustToken](../../wiki/Get-MsIdAdfsWsTrustToken) | Initiates a Ws-Trust logon request to and AD FS server to generate log activity and returns the user token. |
| [Get-MsIdApplicationIdByAppId](../../wiki/Get-MsIdApplicationIdByAppId) | Lookup Application Registration by AppId |
| [Get-MsIdAuthorityUri](../../wiki/Get-MsIdAuthorityUri) | Build Microsoft Identity Provider Authority URI |
| [Get-MsIdAzureIpRange](../../wiki/Get-MsIdAzureIpRange) | Get list of IP ranges for Azure |
| [Get-MsIdCrossTenantAccessActivity](../../wiki/Get-MsIdCrossTenantAccessActivity) | Gets cross tenant user sign-in activity |
| [Get-MsIdGroupWithExpiration](../../wiki/Get-MsIdGroupWithExpiration) | Return groups with an expiration date via lifecycle policy. |
| [Get-MsIdGroupWritebackConfiguration](../../wiki/Get-MsIdGroupWritebackConfiguration) | Gets the group writeback configuration for the group ID |
| [Get-MsIdHasMicrosoftAccount](../../wiki/Get-MsIdHasMicrosoftAccount) | Returns true if the user's mail is a Microsoft Account |
| [Get-MsIdInactiveSignInUser](../../wiki/Get-MsIdInactiveSignInUser) | Retrieve Users who have not had interactive sign ins since XX days ago |
| [Get-MsIdIsViralUser](../../wiki/Get-MsIdIsViralUser) | Returns true if the user's mail domain is a viral (unmanaged) Azure AD tenant. |
| [Get-MsIdMsftIdentityAssociation](../../wiki/Get-MsIdMsftIdentityAssociation) | Parse Microsoft Identity Association Configuration for a Public Domain (such as published apps) |
| [Get-MsIdO365Endpoints](../../wiki/Get-MsIdO365Endpoints) | Get list of URLs and IP ranges for O365 |
| [Get-MsIdOpenIdProviderConfiguration](../../wiki/Get-MsIdOpenIdProviderConfiguration) | Parse OpenId Provider Configuration and Keys |
| [Get-MsIdProvisioningLogStatistics](../../wiki/Get-MsIdProvisioningLogStatistics) | Get Statistics for Set of Azure AD Provisioning Logs |
| [Get-MsIdSamlFederationMetadata](../../wiki/Get-MsIdSamlFederationMetadata) | Parse Federation Metadata |
| [Get-MsIdServicePrincipalIdByAppId](../../wiki/Get-MsIdServicePrincipalIdByAppId) | Lookup Service Principal by AppId |
| [Get-MsIdSigningKeyThumbprint](../../wiki/Get-MsIdSigningKeyThumbprint) | Get signing keys used by Azure AD. |
| [Get-MsIdUnmanagedExternalUser](../../wiki/Get-MsIdUnmanagedExternalUser) | Returns a list of all the external users in the tenant that are unmanaged (viral users). |
| [Get-MsIdUnredeemedInvitedUser](../../wiki/Get-MsIdUnredeemedInvitedUser) | Retrieve Users who have not had interactive sign ins since XX days ago |
| [Import-MsIdAdfsSampleApp](../../wiki/Import-MsIdAdfsSampleApp) | Imports a list availabe sample AD FS relyng party trust applications available in this module, the list is created by the Get-MsIdAdfsSampleApps cmdlet. These applications do NOT use real endpoints and are meant to be used as test applications. |
| [Import-MsIdAdfsSamplePolicy](../../wiki/Import-MsIdAdfsSamplePolicy) | Imports the 'MsId Block Off Corp and VPN' sample AD FS access control policy. This policy is meant to be used as test policy. |
| [Invoke-MsIdAzureAdSamlRequest](../../wiki/Invoke-MsIdAzureAdSamlRequest) | Invoke Saml Request on Azure AD. |
| [New-MsIdClientSecret](../../wiki/New-MsIdClientSecret) | Generate Random Client Secret for application registration or service principal in Azure AD. |
| [New-MsIdSamlRequest](../../wiki/New-MsIdSamlRequest) | Create New Saml Request. |
| [New-MsIdTemporaryUserPassword](../../wiki/New-MsIdTemporaryUserPassword) | Generate Random password for user in Azure AD. |
| [New-MsIdWsTrustRequest](../../wiki/New-MsIdWsTrustRequest) | Create a WS-Trust request. |
| [Reset-MsIdExternalUser](../../wiki/Reset-MsIdExternalUser) | Resets the redemption state of an external user. |
| [Resolve-MsIdAzureIpAddress](../../wiki/Resolve-MsIdAzureIpAddress) | Lookup Azure IP address for Azure Cloud, Region, and Service Tag. |
| [Resolve-MsIdTenant](../../wiki/Resolve-MsIdTenant) | Resolve TenantId or DomainName to an Azure AD Tenant |
| [Revoke-MsIdServicePrincipalConsent](../../wiki/Revoke-MsIdServicePrincipalConsent) | Revoke Existing Consent to an Azure AD Service Principal. |
| [Set-MsIdServicePrincipalVisibleInMyApps](../../wiki/Set-MsIdServicePrincipalVisibleInMyApps) | Toggles whether application service principals are visible when launching myapplications.microsoft.com (MyApps) |
| [Set-MsIdWindowsTlsSettings](../../wiki/Set-MsIdWindowsTlsSettings) | Set TLS settings on Windows OS to use more secure TLS protocols. |
| [Show-MsIdJwtToken](../../wiki/Show-MsIdJwtToken) | Show Json Web Token (JWT) decoded in Web Browser using diagnostic web app. |
| [Show-MsIdSamlToken](../../wiki/Show-MsIdSamlToken) | Show Saml Security Token decoded in Web Browser using diagnostic web app. |
| [Split-MsIdEntitlementManagementConnectedOrganization](../../wiki/Split-MsIdEntitlementManagementConnectedOrganization) | Split elements of a connectedOrganization |
| [Test-MsIdAzureAdDeviceRegConnectivity](../../wiki/Test-MsIdAzureAdDeviceRegConnectivity) | Test connectivity on Windows OS for Azure AD Device Registration |
| [Test-MsIdCBATrustStoreConfiguration](../../wiki/Test-MsIdCBATrustStoreConfiguration) | Test & report for common mis-configuration issues with the Entra ID Certificate Trust Store |
| [Update-MsIdApplicationSigningKeyThumbprint](../../wiki/Update-MsIdApplicationSigningKeyThumbprint) | Update a Service Princpal's preferredTokenSigningKeyThumbprint to the specified certificate thumbprint |
| [Update-MsIdGroupWritebackConfiguration](../../wiki/Update-MsIdGroupWritebackConfiguration) | Update an Azure AD cloud group settings to writeback as an AD on-premises group |


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
