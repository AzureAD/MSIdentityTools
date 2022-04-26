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
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Parameter Set 1')]
        [string]
        $Mail
    )

    $userRealmUriFormat = "https://login.microsoftonline.com/common/userrealm?user={urlEncodedMail}&api-version=2.1&checkForMicrosoftAccount=true"

    $encodedMail = [System.Web.HttpUtility]::UrlEncode($Mail)
    
    $userRealmUri = $userRealmUriFormat -replace "{urlEncodedMail}", $encodedMail
    Write-Verbose $userRealmUri

    $userRealmResponse = Invoke-WebRequest -Uri $userRealmUri
    $content = ConvertFrom-Json (Get-ObjectPropertyValue $userRealmResponse 'Content')
    
    $isMSA = (Get-ObjectPropertyValue $content 'MicrosoftAccount') -eq "0"

    return $isMSA
}
 
