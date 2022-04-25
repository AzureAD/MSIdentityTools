<#
.SYNOPSIS
    Returns true if the user's mail domain is a viral (unmanaged) Azure AD tenant.

    To learn more about viral tenants see [Take over an unmanaged directory as administrator in Azure Active Directory](https://docs.microsoft.com/azure/active-directory/enterprise-users/domains-admin-takeover)
    
.EXAMPLE
    PS > Get-MsIdIsViralUser -Mail john@yopmail.net

    Check if the mail address is from a viral tenant.

#>
function Get-MsIdIsViralUser {
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

    $userRealmUriFormat = "https://login.microsoftonline.com/common/userrealm?user={urlEncodedMail}&api-version=2.1"


    $encodedMail = [System.Web.HttpUtility]::UrlEncode($Mail)
    
    $userRealmUri = $userRealmUriFormat -replace "{urlEncodedMail}", $encodedMail
    Write-Verbose $userRealmUri

    $userRealmResponse = Invoke-WebRequest -Uri $userRealmUri
    $content = ConvertFrom-Json (Get-ObjectPropertyValue $userRealmResponse 'Content')
    
    $isExternalAzureADViral = (Get-ObjectPropertyValue $content 'IsViral') -eq "True"

    return $isExternalAzureADViral
}
