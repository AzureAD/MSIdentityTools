<#
.SYNOPSIS
    Returns a list of all the external users in the tenant that are unmanaged (viral users).
.EXAMPLE
    PS C:\>Get-MSIDUnmanagedExternalUsers
    Gets a list of all the unmanaged (viral) users in the tenant.
#>
function Get-MSIDUnmanagedExternalUsers {
    [CmdletBinding()]

    param ()

    $uri = "https://login.microsoftonline.com/common/userrealm?user={urlEncodedMail}&api-version=2.1"

    $users = Get-MgUser -Filter "userType eq 'Guest'" -All

    foreach ($user in $users){
        $encodedMail = [System.Web.HttpUtility]::UrlEncode($user.mail)
        
        $userRealmUri = $uri -replace "{urlEncodedMail}", $encodedMail
        $userRealmResponse = Invoke-WebRequest -Uri $userRealmUri
        $content = ConvertFrom-Json $userRealmResponse.Content
        if ($content.IsViral -eq "True"){
            $user
        }
    }
}
