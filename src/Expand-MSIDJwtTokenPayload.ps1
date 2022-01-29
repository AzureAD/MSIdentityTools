<#
.SYNOPSIS
    Extract Json Web Token (JWT) payload from JWS structure to PowerShell object.
.EXAMPLE
    PS C:\>$MsalToken.IdToken | Expand-MSIDJwtTokenPayload
    Extract Json Web Token (JWT) payload from JWS structure to PowerShell object.
.INPUTS
    System.String
#>
function Expand-MSIDJwtTokenPayload {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        # JSON Web Token (JWT)
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]] $Tokens
    )

    process {
        foreach ($Token in $Tokens) {
            $Jwt = ConvertFrom-JsonWebSignature $Token
            Write-Output $Jwt.Payload
        }
    }
}
