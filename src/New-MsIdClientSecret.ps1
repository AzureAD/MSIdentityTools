<#
.SYNOPSIS
    Generate Random Client Secret for application registration or service principal in Azure AD.
    
.EXAMPLE
    PS > New-MsIdClientSecret

    Generates a new client secret 32 characters long.
    
.EXAMPLE
    PS > New-MsIdClientSecret -Length 64 -Base64Encode

    Generates a new client secret 64 bytes long and then base64 encodes it.

#>
function New-MsIdClientSecret {
    [CmdletBinding()]
    [OutputType([securestring])]
    param (
        # Specifies the number of random characters or bytes to generate.
        [Parameter(Mandatory = $false)]
        [int] $Length = 32,
        # Generate a binary key and encode it to base64.
        [Parameter(Mandatory = $false)]
        [switch] $Base64Encode
    )

    if ($Base64Encode) {
        [securestring] $Secret = ConvertTo-SecureString (ConvertTo-Base64String ([byte[]](Get-Random -InputObject ((([byte]::MinValue)..([byte]::MaxValue)) * $Length) -Count $Length))) -AsPlainText -Force
    }
    else {
        [char[]] $Numbers = (48..57)
        [char[]] $UpperCaseLetters = (65..90)
        [char[]] $LowerCaseLetters = (97..122)
        [char[]] $Symbols = '*+-./:=?@[]_'
        [securestring] $Secret = ConvertTo-SecureString ((Get-Random -InputObject (($UpperCaseLetters + $LowerCaseLetters + $Numbers + $Symbols) * $Length) -Count $Length) -join '') -AsPlainText -Force
    }
    return $Secret
}
