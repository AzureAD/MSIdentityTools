<#
.SYNOPSIS
    Parse Microsoft Identity Association Configuration for a Public Domain (such as published apps)

.EXAMPLE
    PS > Get-MsIdMsftIdentityAssociation https://contoso.com/
    
    Get Microsoft Identity Association Configuration for contoso domain.

.INPUTS
    System.Uri

#>
function Get-MsIdMsftIdentityAssociation {
    [CmdletBinding()]
    [OutputType([PsCustomObject[]])]
    param (
        # Publisher Domain. For example: https://contoso.com/
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [uri] $Publisher
    )
    ## Build common OpenId provider configuration URI
    $uriMsftIdentityAssociation = New-Object System.UriBuilder $Publisher.AbsoluteUri
    if (!$uriMsftIdentityAssociation.Path.EndsWith('/.well-known/microsoft-identity-association.json')) { $uriMsftIdentityAssociation.Path += '/.well-known/microsoft-identity-association.json' }

    ## Download and parse configuration
    $MsftIdentityAssociation = Invoke-RestMethod -UseBasicParsing -Uri $uriMsftIdentityAssociation.Uri.AbsoluteUri  # Should return ContentType 'application/json'
    return $MsftIdentityAssociation
}
