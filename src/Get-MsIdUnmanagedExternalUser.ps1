<#
.SYNOPSIS
    Returns a list of all the external users in the tenant that are unmanaged (viral users).
    
.EXAMPLE
    PS > Get-MsIdUnmanagedExternalUsers

    Gets a list of all the unmanaged (viral) users in the tenant.

#>
function Get-MsIdUnmanagedExternalUser {
    [CmdletBinding()]

    param ()

    $graphBaseUri = "https://graph.microsoft.com/$((Get-MgProfile).Name)"
    $pageCount = 100
    $guestUserUri = $graphBaseUri + "/users?`$filter=userType eq 'Guest'&`$select=id,userPrincipalName,mail,displayName,identities&`$count=true&`$top=$pageCount"

    $userRealmUriFormat = "https://login.microsoftonline.com/common/userrealm?user={urlEncodedMail}&api-version=2.1"

    $results = Invoke-MgGraphRequest -Uri $guestUserUri -Headers @{ ConsistencyLevel = 'eventual' }
    $count = Get-ObjectPropertyValue $results '@odata.count'
    $currentPage = 0
    $hasMoreData = $true
    $userIndex = 1

    #Declare $user as GraphUser object

    if ($count -eq 0) {
        Write-Host "No guest users in this tenant."
    }
    elseif ($count -gt 0) {
        while ($hasMoreData) {     
            $percentCompleted = $currentPage * $pageCount / $count * 100
            $currentPage += 1
            Write-Progress -Activity "Checking Guest Users" -PercentComplete $percentCompleted
            
            foreach ($userObject in (Get-ObjectPropertyValue $results 'value')) {
                [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser1]$user = $userObject
                
                Write-Verbose "$userIndex / $count"
                $userIndex += 1
                $isAzureAdUser = $false
                foreach ($identity in (Get-ObjectPropertyValue $user 'identities')) {
                    if ((Get-ObjectPropertyValue $identity 'issuer') -eq 'ExternalAzureAD') {
                        $isAzureAdUser = $true
                        break;
                    }
                }

                if ($isAzureAdUser) {
                    Write-Verbose "Checking if user is viral user. $($user.userPrincipalName)"

                    $mail = Get-ObjectPropertyValue $user 'mail'
                    if (![string]::IsNullOrEmpty($mail)) {
                        $encodedMail = [System.Web.HttpUtility]::UrlEncode($user.mail)
                        
                        $userRealmUri = $userRealmUriFormat -replace "{urlEncodedMail}", $encodedMail
                        Write-Verbose $userRealmUri

                        try {
                            $userRealmResponse = Invoke-WebRequest -Uri $userRealmUri
                            $content = ConvertFrom-Json (Get-ObjectPropertyValue $userRealmResponse 'Content')
                            if ((Get-ObjectPropertyValue $content 'IsViral') -eq "True") {
                                Write-Verbose "$($user.userPrincipalName)  = viral user"
                                Write-Output $user
                            }
                            else {
                                Write-Verbose "$($user.userPrincipalName) <> viral user"
                            }                                
                        }
                        catch {
                            
                        }
                    }
                }
                else {
                    Write-Verbose "Skipping. $($user.userPrincipalName) <> ExternalAzureAD managed user"
                }
            }
        
            $nextLink = Get-ObjectPropertyValue $results 'nextLink'
            if ($nextLink) {
                $results = Invoke-MgGraphRequest -Uri $nextLink -Headers @{ ConsistencyLevel = 'eventual' }
            }
            else {
                $hasMoreData = $false
            }
            
        } 
        Write-Progress -Activity "Checking Guest Users" -Completed
    }
}
