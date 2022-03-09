<#
.SYNOPSIS
    Parse OpenId Provider Configuration and Keys
    
.EXAMPLE
    PS > Get-MsIdAuthorityUri -TenantId tenant.onmicrosoft.com | Get-MsIdOpenIdProviderConfiguration

    Get OpenId Provider Configuration for a specific Microsoft organizational tenant (Azure AD).

.EXAMPLE
    PS > Get-MsIdAuthorityUri -TenantId tenant.onmicrosoft.com | Get-MsIdOpenIdProviderConfiguration -Keys

    Get public keys for OpenId Provider for a specific Microsoft organizational tenant (Azure AD).

.EXAMPLE
    PS > Get-MsIdAuthorityUri -Msa | Get-MsIdOpenIdProviderConfiguration

    Get OpenId Provider Configuration for Microsoft consumer accounts (MSA).

.INPUTS
    System.Uri

#>
function Get-MsIdOpenIdProviderConfiguration {
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
