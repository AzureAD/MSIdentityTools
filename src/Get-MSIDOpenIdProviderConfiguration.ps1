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
.INPUTS
    System.Uri
#>
function Get-MSIDOpenIdProviderConfiguration {
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

    process {
        Get-OpenIdProviderConfiguration @PSBoundParameters
    }
}
