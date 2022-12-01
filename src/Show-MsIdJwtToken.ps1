<#
.SYNOPSIS
   Show Json Web Token (JWT) decoded in Web Browser using diagnostic web app.
   
.EXAMPLE
    PS > $MsalToken.IdToken | Show-MsIdJwtToken

    Show OAuth IdToken JWT decoded in Web Browser.

.INPUTS
    System.String

#>
function Show-MsIdJwtToken {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [Alias('Show-Jwt')]
    param (
        # JSON Web Token (JWT)
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]] $Tokens,
        # OAuth2 Redirect Uri of test application to send Json Web Token
        [Parameter(Mandatory = $false)]
        [uri] $OAuth2RedirectUri = 'https://jwt.ms/',
        # Suppress Prompts
        [Parameter(Mandatory = $false)]
        [switch] $Force
    )

    begin {
        if ($Force -and -not (Get-Variable Confirm -ValueOnly -ErrorAction Ignore)) { $ConfirmPreference = 'None' }
    }

    process {
        foreach ($Token in $Tokens) {

            if ($OAuth2RedirectUri.AbsoluteUri -ne 'https://jwt.ms/') {
                Write-Warning ('The token is being sent to the following web service [{0}]. This command is intended for troubleshooting and should only be used if you trust the service endpoint receiving the token.' -f $OAuth2RedirectUri.AbsoluteUri)
                if (!$PSCmdlet.ShouldProcess($OAuth2RedirectUri.AbsoluteUri, "Send token")) { continue }
            }

            $OAuth2RedirectUriWithToken = New-Object System.UriBuilder $OAuth2RedirectUri -Property @{ Fragment = "id_token=$Token" }
            Start-Process $OAuth2RedirectUriWithToken.Uri.AbsoluteUri
        }
    }
}
