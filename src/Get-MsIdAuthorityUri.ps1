<#
.SYNOPSIS
    Build Microsoft Identity Provider Authority URI

.EXAMPLE
    PS > Get-MsIdAuthorityUri

    Get common Microsoft authority URI endpoint.

.EXAMPLE
    PS > Get-MsIdAuthorityUri -TenantId contoso.com

    Get Microsoft IdP authority URI endpoint for a specific organizational tenant (Azure AD).

.EXAMPLE
    PS > Get-MsIdAuthorityUri -AzureAd

    Get Microsoft IdP authority URI endpoint for any organizational account (Azure AD).

.EXAMPLE
    PS > Get-MsIdAuthorityUri -Msa

    Get Microsoft IdP authority URI endpoint for any Microsoft consumer account (MSA).

.EXAMPLE
    PS > Get-MsIdAuthorityUri -AzureAdB2c -TenantName contoso -Policy B2C_1_SignUp

    Get Microsoft IdP authority URI endpoint for a specific organization B2C tenant (Azure AD B2C) using the B2C_1_SignUp policy.
    
#>
function Get-MsIdAuthorityUri {
    [CmdletBinding(DefaultParameterSetName = 'Common')]
    [OutputType([string])]
    param (
        # Use endpoint for organizational accounts (Azure AD).
        [Parameter(Mandatory = $true, ParameterSetName = 'AzureAd')]
        [switch] $AzureAd,
        # Use endpoint for organizational B2C accounts (Azure AD B2C).
        [Parameter(Mandatory = $true, ParameterSetName = 'AzureAdB2c')]
        [switch] $AzureAdB2c,
        # Use endpoint for Microsoft consumer accounts (MSA).
        [Parameter(Mandatory = $true, ParameterSetName = 'Msa')]
        [switch] $Msa,
        # Name of Azure AD tenant. For example: <TenantName>.onmicrosoft.com
        [Parameter(Mandatory = $false, ParameterSetName = 'Common')]
        [Parameter(Mandatory = $false, ParameterSetName = 'AzureAd')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AzureAdB2c')]
        [string] $TenantName,
        # Azure AD tenant GUID or verified domain name. For example: contoso.onmicrosoft.com or contoso.com
        [Parameter(Mandatory = $false, ParameterSetName = 'Common')]
        [Parameter(Mandatory = $false, ParameterSetName = 'AzureAd')]
        [Parameter(Mandatory = $false, ParameterSetName = 'AzureAdB2c')]
        [string] $TenantId,
        # Name of B2C Policy defined in Azure AD B2C tenant.
        [Parameter(Mandatory = $true, ParameterSetName = 'AzureAdB2c')]
        [string] $Policy,

        # Type of app integration ('OAuth2','Saml','WsFed'). 'OAuth2' is default.
        [Parameter(Mandatory = $false)]
        [ValidateSet('OAuth2', 'Saml', 'WsFed')]
        [string] $AppType = 'OAuth2',
        # OAuth2 endpoint version ('v1.0','v2.0'). v2.0 is default.
        [Parameter(Mandatory = $false, ParameterSetName = 'Common')]
        [Parameter(Mandatory = $false, ParameterSetName = 'AzureAd')]
        [ValidateSet('v1.0', 'v2.0')]
        [string] $OAuth2EndpointVersion = 'v2.0'
    )

    switch ($PSCmdlet.ParameterSetName) {
        "AzureAdB2c" {
            [uri] $BaseUri = "https://{0}.b2clogin.com/" -f $TenantName
        }
        default {
            [uri] $BaseUri = "https://login.microsoftonline.com/"
        }
    }

    switch ($PSCmdlet.ParameterSetName) {
        "AzureAd" {
            if (!$TenantId) {
                if ($TenantName) { $TenantId = "{0}.onmicrosoft.com" -f $TenantName }
                else { $TenantId = "organizations" }
            }
            break
        }
        "AzureAdB2c" {
            if (!$TenantId) { $TenantId = "{0}.onmicrosoft.com" -f $TenantName }
            break
        }
        "Msa" {
            if (!$TenantId) { $TenantId = "consumers" }
            break
        }
        default {
            if (!$TenantId) {
                if ($TenantName) { $TenantId = "{0}.onmicrosoft.com" -f $TenantName }
                else { $TenantId = "common" }
            }
        }
    }

    $uriMsftIdPAuthority = New-Object System.UriBuilder $BaseUri.AbsoluteUri
    $uriMsftIdPAuthority.Path = '/{0}' -f $TenantId
    if ($PSCmdlet.ParameterSetName -eq 'AzureAdB2c') { $uriMsftIdPAuthority.Path += '/{0}' -f $Policy }
    if ($AppType -eq 'OAuth2' -and $OAuth2EndpointVersion -ne 'v1.0') { $uriMsftIdPAuthority.Path += '/{0}' -f $OAuth2EndpointVersion }
    #if ($Policy) { $uriMsftIdPAuthority.Query = ConvertTo-QueryString @{ p = $Policy } }

    return $uriMsftIdPAuthority.Uri.AbsoluteUri
}
