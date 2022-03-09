<#
.SYNOPSIS
    Convert Msft Identity token structure to PowerShell object.

.EXAMPLE
    PS > ConvertFrom-MsIdJwtToken $OpenIdConnectToken

    Convert OAuth Id Token JWS to PowerShell object.

.EXAMPLE
    PS > ConvertFrom-MsIdJwtToken $AccessToken

    Convert OAuth Access Token JWS to PowerShell object.

.INPUTS
    System.String
    
#>
function ConvertFrom-MsIdJwtToken {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        # JSON Web Token (JWT)
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]] $Tokens
    )

    process {
        foreach ($Token in $Tokens) {
            ConvertFrom-JsonWebSignature $Token
        }
    }
}
