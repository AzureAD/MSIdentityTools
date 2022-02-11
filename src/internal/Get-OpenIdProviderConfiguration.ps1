<#
.SYNOPSIS
    Parse OpenId Provider Configuration and Keys
.EXAMPLE
    PS C:\>Get-MSIDAuthorityUri -TenantId tenant.onmicrosoft.com | Get-OpenIdProviderConfiguration
    Get OpenId Provider Configuration for a specific Microsoft organizational tenant (Azure AD).
.EXAMPLE
    PS C:\>Get-MSIDAuthorityUri -TenantId tenant.onmicrosoft.com | Get-OpenIdProviderConfiguration -Keys
    Get public keys for OpenId Provider for a specific Microsoft organizational tenant (Azure AD).
.EXAMPLE
    PS C:\>Get-MSIDAuthorityUri -Msa | Get-OpenIdProviderConfiguration
    Get OpenId Provider Configuration for Microsoft consumer accounts (MSA).
.EXAMPLE
    PS C:\>Get-OpenIdProviderConfiguration 'https://accounts.google.com/'
    Get OpenId Provider Configuration for Google Accounts.
.INPUTS
    System.Uri
#>
function Get-OpenIdProviderConfiguration {
    [CmdletBinding()]
    [OutputType([PsCustomObject[]])]
    param (
        # Identity Provider Authority URI
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [uri] $Issuer,
        # Return configuration keys
        [Parameter(Mandatory = $false)]
        [switch] $Keys
    )
    ## Build common OpenId provider configuration URI
    $uriOpenIdProviderConfiguration = New-Object System.UriBuilder $Issuer.AbsoluteUri
    if (!$uriOpenIdProviderConfiguration.Path.EndsWith('/.well-known/openid-configuration')) { $uriOpenIdProviderConfiguration.Path += '/.well-known/openid-configuration' }

    ## Download and parse configuration
    $OpenIdProviderConfiguration = Invoke-RestMethod -UseBasicParsing -Uri $uriOpenIdProviderConfiguration.Uri.AbsoluteUri  # Should return ContentType 'application/json'
    if ($Keys) {
        $OpenIdProviderConfigurationJwks = Invoke-RestMethod -UseBasicParsing -Uri $OpenIdProviderConfiguration.jwks_uri  # Should return ContentType 'application/json'
        return $OpenIdProviderConfigurationJwks.keys
    }
    else {
        return $OpenIdProviderConfiguration
    }
}
