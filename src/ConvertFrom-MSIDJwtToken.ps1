<#
.SYNOPSIS
    Convert Msft Identity token structure to PowerShell object.
.EXAMPLE
    PS C:\>ConvertFrom-MSIDJwtToken $OpenIdConnectToken
    Convert OAuth Id Token JWS to PowerShell object.
.EXAMPLE
    PS C:\>ConvertFrom-MSIDJwtToken $AccessToken
    Convert OAuth Access Token JWS to PowerShell object.
.INPUTS
    System.String
#>
function ConvertFrom-MSIDJwtToken {
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
