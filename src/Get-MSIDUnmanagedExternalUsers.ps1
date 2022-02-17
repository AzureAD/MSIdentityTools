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

    $graphBaseUri = "https://graph.microsoft.com/$((Get-MgProfile).Name)"
    $pageCount = 100
    $guestUserUri = $graphBaseUri + "/users?`$filter=userType eq 'Guest'&`$select=id,userPrincipalName,mail,displayName,identities&`$count=true&`$top=$pageCount"

    $userRealmUriFormat = "https://login.microsoftonline.com/common/userrealm?user={urlEncodedMail}&api-version=2.1"

    $results = Invoke-MgGraphRequest -Uri $guestUserUri -Headers @{ ConsistencyLevel = 'eventual' }
    $count = $results.'@odata.count'
    $viralUsers = @()
    $currentPage = 0
    $hasMoreData = $true
    $userIndex = 1
    if ($count -eq 0){
        Write-Host "No guest users in this tenant."
    }
    elseif ($count -gt 0) {
        while($hasMoreData) {     
            $percentCompleted = $currentPage * $pageCount / $count * 100
            $currentPage += 1
            Write-Progress -Activity "Checking Guest Users"  -PercentComplete $percentCompleted

            foreach ($user in $results.value){
                Write-Verbose "$userIndex / $count"
                $userIndex += 1
                $isAzureAdUser = $false
                foreach($identity in $user.identities){
                    if($identity.issuer -eq 'ExternalAzureAD'){
                        $isAzureAdUser = $true
                        break;
                    }
                }
                if($isAzureAdUser){
                    Write-Verbose "Checking if user is viral user. $($user.userPrincipalName)"

                    $encodedMail = [System.Web.HttpUtility]::UrlEncode($user.mail)
                    
                    $userRealmUri = $userRealmUriFormat -replace "{urlEncodedMail}", $encodedMail
                    Write-Verbose $userRealmUri

                    $userRealmResponse = Invoke-WebRequest -Uri $userRealmUri
                    $content = ConvertFrom-Json $userRealmResponse.Content
                    if ($content.IsViral -eq "True"){
                        Write-Verbose "$($user.userPrincipalName)  = viral user"
                        $viralUsers += $user
                    }
                    else {
                        Write-Verbose "$($user.userPrincipalName) <> viral user"
                    }
                }
                else {
                    Write-Verbose "Skipping. $($user.userPrincipalName) <> ExternalAzureAD managed user"
                }
            }
        
            if($results.'@odata.nextLink'){
                $results = Invoke-MgGraphRequest -Uri $results.'@odata.nextLink' -Headers @{ ConsistencyLevel = 'eventual' }
            }
            else {
                $hasMoreData = $false
            }
            
        } 
        Write-Progress -Activity "Checking Guest Users" -Completed
    }
    
    Write-Output $viralUsers
}
