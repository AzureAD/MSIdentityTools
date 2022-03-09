<#
.SYNOPSIS
    Parse Federation Metadata
    
.EXAMPLE
    PS > Get-MsIdAuthorityUri -TenantId tenant.onmicrosoft.com -AppType 'Saml' | Get-MsIdSamlFederationMetadata

    Get SAML or WS-Fed Federation Metadata for a specific Microsoft tenant.

.EXAMPLE
    PS > Get-MsIdAuthorityUri -TenantId tenant.onmicrosoft.com -AppType 'Saml' | Get-MsIdSamlFederationMetadata -AppId 00000000-0000-0000-0000-000000000000

    Get SAML or WS-Fed Federation Metadata for a specific application within a specific Microsoft tenant.

.EXAMPLE
    PS > Get-MsIdSamlFederationMetadata 'https://adfs.contoso.com'

    Get SAML or WS-Fed Federation Metadata for an ADFS farm.

.INPUTS
    System.Uri

#>
function Get-MsIdSamlFederationMetadata {
    [CmdletBinding()]
    [Alias('Get-MsIdWsFedFederationMetadata')]
    [OutputType([xml], [System.Xml.XmlElement[]])]
    param (
        # Identity Provider Authority URI
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [uri] $Issuer,
        # Azure AD Application Id
        [Parameter(Mandatory = $false, Position = 2)]
        [guid] $AppId
    )

    process {
        Get-SamlFederationMetadata @PSBoundParameters
    }
}
