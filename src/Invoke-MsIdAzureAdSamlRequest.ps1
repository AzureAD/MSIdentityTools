<#
.SYNOPSIS
    Invoke Saml Request on Azure AD.
   
.EXAMPLE
    PS > $samlRequest = New-MsIdSamlRequest -Issuer 'urn:microsoft:adfs:claimsxray'
    PS > Invoke-MsIdAzureAdSamlRequest $samlRequest.OuterXml

    Create new Saml Request for Claims X-Ray and Invoke on Azure AD.

.INPUTS
    System.String

#>
function Invoke-MsIdAzureAdSamlRequest {
    [CmdletBinding()]
    [OutputType()]
    param (
        # SAML Request
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object[]] $SamlRequest,
        # Azure AD Tenant Id
        [Parameter(Mandatory = $false)]
        [string] $TenantId = 'common'
    )

    process {
        foreach ($_SamlRequest in $SamlRequest) {
            if ($Token -is [string]) {
                $xmlSamlRequest = ConvertFrom-SamlMessage $_SamlRequest
            }
            else {
                $xmlSamlRequest = $Token
            }
            $EncodedSamlRequest = $xmlSamlRequest.OuterXml | Compress-Data | ConvertTo-Base64String

            [System.UriBuilder] $uriAzureAD = 'https://login.microsoftonline.com/{0}/saml2' -f $TenantId
            $uriAzureAD.Query = ConvertTo-QueryString @{
                SAMLRequest = $EncodedSamlRequest
            }

            Write-Verbose ('Invoking Azure AD SAML2 Endpoint [{0}]' -f $uriAzureAD.Uri.AbsoluteUri)
            Start-Process $uriAzureAD.Uri.AbsoluteUri
        }
    }
}
