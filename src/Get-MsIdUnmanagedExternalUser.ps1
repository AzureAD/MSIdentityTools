<#
.SYNOPSIS
    Returns a list of all the external users in the tenant that are unmanaged (viral users).
    
.EXAMPLE
    PS > Get-MsIdUnmanagedExternalUser

    Gets a list of all the unmanaged/viral external users.

.EXAMPLE
    PS > Get-MsIdUnmanagedExternalUser -Type ExternalAzureADViral

    Gets a list of all the unmanaged/viral external users. This is the same as running Get-MsIdUnmanagedExternalUser without any parameters.

.EXAMPLE
    PS > Get-MsIdUnmanagedExternalUser -Type MicrosoftAccount

    Gets a list of all the external users with a personal Microsoft Account.

.EXAMPLE
    PS > Get-MsIdUnmanagedExternalUser -Type All

    Gets a list of all the external users that are from an unmanaged/viral tenant or have a personal Microsoft Account. 

#>
function Get-MsIdUnmanagedExternalUser {
    [CmdletBinding()]

    param (
        # The type of unmanaged user to return
        [Parameter(Mandatory = $false,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Parameter Set 1')]
        [ValidateSet("ExternalAzureADViral", "MicrosoftAccount", "All")]
        [string]
        $Type = "ExternalAzureADViral"
    )

    $graphBaseUri = "https://graph.microsoft.com/$((Get-MgProfile).Name)"
    $pageCount = 999
    $guestUserUri = $graphBaseUri + "/users?`$filter=userType eq 'Guest'&`$select=id,userPrincipalName,mail,displayName,identities&`$count=true&`$top=$pageCount"

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
                $isMsaUser = $false
                $mail = Get-ObjectPropertyValue $user 'mail'

                foreach ($identity in (Get-ObjectPropertyValue $user 'identities')) {
                    $issuer = Get-ObjectPropertyValue $identity 'issuer'
                    Write-Verbose "$($mail) Issuer = $($issuer) [$($user.userPrincipalName)]"
                    switch ($issuer) {
                        'ExternalAzureAD' { $isAzureAdUser = $true }
                        'MicrosoftAccount' { $isMsaUser = $true }
                    }
                }

                $isViralUser = $false
                if($Type -eq 'ExternalAzureADViral' -or $Type -eq 'All')
                {
                    if ($isAzureAdUser) {
                        
                        Write-Verbose "Checking if user $($mail) is viral user. [$($user.userPrincipalName)]"

                        if (![string]::IsNullOrEmpty($mail)) {
                            $isViralUser = Get-MsIdIsViralUser -Mail $mail
                        }
                        else {
                            Write-Verbose "Skipping viral check. $($user.userPrincipalName) does not have a mail address."
                        }
                    }
                    else {
                        Write-Verbose "Skipping viral check. $($mail) <> ExternalAzureAD managed user"
                    }
                }

                if(($Type -eq 'ExternalAzureADViral' -or $Type -eq 'All') -and $isViralUser)
                {
                    Write-Verbose "$($mail) = viral user [$($user.userPrincipalName)]"
                    Write-Output $user
                }
                if(($Type -eq 'MicrosoftAccount' -or $Type -eq 'All') -and $isMsaUser)
                {
                    Write-Verbose "$($mail) = Microsoft Account [$($user.userPrincipalName)]"
                    Write-Output $user
                }

            }
        
            $nextLink = Get-ObjectPropertyValue $results '@odata.nextLink'
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
