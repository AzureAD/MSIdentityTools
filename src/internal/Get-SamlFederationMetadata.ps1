<#
.SYNOPSIS
    Parse Federation Metadata
.EXAMPLE
    PS C:\>Get-MsIdAuthorityUri -TenantId tenant.onmicrosoft.com -AppType 'Saml' | Get-SamlFederationMetadata
    Get SAML or WS-Fed Federation Metadata for a specific Microsoft tenant.
.EXAMPLE
    PS C:\>Get-MsIdAuthorityUri -TenantId tenant.onmicrosoft.com -AppType 'Saml' | Get-SamlFederationMetadata -AppId 00000000-0000-0000-0000-000000000000
    Get SAML or WS-Fed Federation Metadata for a specific application within a specific Microsoft tenant.
.EXAMPLE
    PS C:\>Get-SamlFederationMetadata 'https://adfs.contoso.com'
    Get SAML or WS-Fed Federation Metadata for an ADFS farm.
.INPUTS
    System.Uri
#>
function Get-SamlFederationMetadata {
    [CmdletBinding()]
    [Alias('Get-WsFedFederationMetadata')]
    [OutputType([xml], [System.Xml.XmlElement[]])]
    param (
        # Identity Provider Authority URI
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [uri] $Issuer,
        # Azure AD Application Id
        [Parameter(Mandatory = $false, Position = 2)]
        [guid] $AppId
    )

    ## Remove Microsoft v2.0 endpoint because it is only for OAuth2
    if ($Issuer.Authority -eq 'login.microsoftonline.com') { $Issuer = $Issuer.AbsoluteUri -replace '[/\\]v2.0[/\\]?$', '' }

    ## Build common federation metadata URI
    $uriFederationMetadata = New-Object System.UriBuilder $Issuer.AbsoluteUri
    if (!$uriFederationMetadata.Path.EndsWith('/FederationMetadata/2007-06/FederationMetadata.xml', $true, $null)) { $uriFederationMetadata.Path += '/FederationMetadata/2007-06/FederationMetadata.xml' }
    if ($AppId) {
        $uriFederationMetadata.Query = ConvertTo-QueryString @{
            AppId = $AppId
        }
    }

    ## Download and parse federation metadata
    $FederationMetadata = Invoke-RestMethod -UseBasicParsing -Uri $uriFederationMetadata.Uri.AbsoluteUri -ErrorAction Stop  # Should return ContentType 'application/samlmetadata+xml'
    if ($FederationMetadata -is [string]) {
        try {
            [xml] $xmlFederationMetadata = $FederationMetadata -replace '^[^<]*', ''
        }
        catch { throw }
    }
    else {
        [xml] $xmlFederationMetadata = $FederationMetadata
    }

    return $xmlFederationMetadata.GetElementsByTagName('EntityDescriptor')
}
