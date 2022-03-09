<#
.SYNOPSIS
    Validate the digital signature for JSON Web Token.

.EXAMPLE
    PS > Confirm-MsIdJwtTokenSignature $OpenIdConnectToken

    Validate the OpenId token was signed by token issuer based on the OIDC Provider Configuration for token issuer.

.EXAMPLE
    PS > Confirm-MsIdJwtTokenSignature $AccessToken

    Validate the access token was signed by token issuer based on the OIDC Provider Configuration for token issuer.

.INPUTS
    System.String
    
#>
function Confirm-MsIdJwtTokenSignature {
    [CmdletBinding()]
    [Alias('Confirm-JwtSignature')]
    [OutputType([bool])]
    param (
        # JSON Web Token (JWT)
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]] $Tokens
    )

    process {
        foreach ($Token in $Tokens) {
            $Jws = ConvertFrom-JsonWebSignature $Token
            $SigningKeys = $Jws.Payload.iss | Get-OpenIdProviderConfiguration -Keys | Where-Object use -EQ 'sig'
            $SigningKey = $SigningKeys | Where-Object kid -EQ $Jws.Header.kid
            $SigningCertificate = Get-X509Certificate $SigningKey.x5c

            Confirm-JsonWebSignature $Token -SigningCertificate $SigningCertificate
        }
    }
}
