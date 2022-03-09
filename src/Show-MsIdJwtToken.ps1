<#
.SYNOPSIS
   Show Json Web Token (JWT) decoded in Web Browser.
   
.EXAMPLE
    PS > $MsalToken.IdToken | Show-MsIdJwtToken

    Show OAuth IdToken JWT decoded in Web Browser.

.INPUTS
    System.String

#>
function Show-MsIdJwtToken {
    [CmdletBinding()]
    #[Alias('Show-Jwt')]
    param (
        # JSON Web Token (JWT)
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]] $Tokens
    )

    process {
        foreach ($Token in $Tokens) {
            Start-Process "https://jwt.ms/#id_token=$Token"
        }
    }
}
