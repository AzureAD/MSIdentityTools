<#
.SYNOPSIS
    Returns true if the user's mail is a Microsoft Account
    
.EXAMPLE
    PS > Get-MsIdHasMicrosoftAccount -Mail john@yopmail.net

    Check if the mail address has a Microsoft account

#>
function Get-MsIdHasMicrosoftAccount {
    [CmdletBinding()]

    param (
        # The email address of the external user.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false)]
        [string] $Mail
    )

    $userRealm = Get-MsftUserRealm $Mail
    
    $isMSA = (Get-ObjectPropertyValue $userRealm 'MicrosoftAccount') -eq "0"

    return $isMSA
}
