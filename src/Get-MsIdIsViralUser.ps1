<#
.SYNOPSIS
    Returns true if the user's mail domain is a viral (unmanaged) Azure AD tenant.

.DESCRIPTION
    To learn more about viral tenants see [Take over an unmanaged directory as administrator in Azure Active Directory](https://docs.microsoft.com/azure/active-directory/enterprise-users/domains-admin-takeover)

.EXAMPLE
    PS > Get-MsIdIsViralUser -Mail john@yopmail.net

    Check if the mail address is from a viral tenant.

#>
function Get-MsIdIsViralUser {
    [CmdletBinding()]

    param (
        # The email address of the external user.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false)]
        [string] $Mail
    )

    $userRealm = Get-MsftUserRealm $Mail

    $isExternalAzureADViral = (Get-ObjectPropertyValue $userRealm 'IsViral') -eq "True"

    return $isExternalAzureADViral
}
