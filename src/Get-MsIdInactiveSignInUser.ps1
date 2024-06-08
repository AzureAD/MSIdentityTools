<#
.SYNOPSIS
    Retrieve Users who have not had interactive sign ins since XX days ago

.EXAMPLE
    PS > Get-MsIdInactiveSignInUser -LastSignInBeforeDaysAgo 30

    Retrieve Users who have not signed in since 30 days ago from today

.INPUTS
    System.Int
.NOTES
    - Updating Role Assignable Groups or Privileged Access Groups require PrivilegedAccess.ReadWrite.AzureADGroup permission scope
    THIS CODE-SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR
    FITNESS FOR A PARTICULAR PURPOSE.
    This sample is not supported under any Microsoft standard support program or service.
    The script is provided AS IS without warranty of any kind. Microsoft further disclaims all
    implied warranties including, without limitation, any implied warranties of merchantability
    or of fitness for a particular purpose. The entire risk arising out of the use or performance
    of the sample and documentation remains with you. In no event shall Microsoft, its authors,
    or anyone else involved in the creation, production, or delivery of the script be liable for
    any damages whatsoever (including, without limitation, damages for loss of business profits,
    business interruption, loss of business information, or other pecuniary loss) arising out of
    the use of or inability to use the sample or documentation, even if Microsoft has been advised
    of the possibility of such damages, rising out of the use of or inability to use the sample script,
    even if Microsoft has been advised of the possibility of such damages.

#>
function Get-MsIdInactiveSignInUser {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # User Last Sign In Activity is before Days ago
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [Alias("BeforeDaysAgo")]
        [int] $LastSignInBeforeDaysAgo = 30,
        # Return results for All, Member, or Guest userTypes
        [ValidateSet("All", "Member", "Guest")]
        [string]
        $UserType = "All"
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'Get-MgUser' -MinimumVersion 2.8.0 -RequireListPermissions -ErrorVariable CriticalError)) { return }
    }

    process {
        if ($CriticalError) { return }

        $queryDate = Get-Date (Get-Date).AddDays($(0 - $LastSignInBeforeDaysAgo)) -UFormat %Y-%m-%dT00:00:00Z

        $inactiveFilter = ("(signInActivity/lastSignInDateTime le {0})" -f $queryDate)

        $queryFilter = $inactiveFilter

        # Using Date scope here, since conflict with service side odata filter on userType.
        Write-Debug ("Retrieving Users with Filter {0}" -f $queryFilter)
        $queryUsers = Get-MgUser -Filter $queryFilter -All:$true -Property signInActivity, UserPrincipalName, Id, DisplayName, mail, userType, createdDateTime

        switch ($UserType) {
            "Member" {
                $users = $queryUsers | Where-Object -FilterScript { $_.userType -eq 'Member' }
            }
            "Guest" {
                $users = $queryUsers | Where-Object -FilterScript { $_.userType -eq 'Guest' }

            }
            "All" {
                $users = $queryUsers
            }
        }

        foreach ($userObject in $users) {
            $checkedUser = [ordered] @{}
            $checkedUser.UserID = $userObject.Id
            $checkedUser.DisplayName = $userObject.DisplayName
            $checkedUser.UserPrincipalName = $userObject.UserPrincipalName
            $checkedUser.Mail = $userObject.Mail
            $checkedUser.UserType = $userObject.UserType

            If ($null -eq $userObject.signInActivity.LastSignInDateTime) {
                $checkedUser.LastSignInDateTime = "Unknown"
                $checkedUser.LastSigninDaysAgo = "Unknown"
                $checkedUser.lastNonInteractiveSignInDateTime = "Unknown"
            }
            else {
                $checkedUser.LastSignInDateTime = $userObject.signInActivity.LastSignInDateTime
                $checkedUser.LastSigninDaysAgo = (New-TimeSpan -Start $checkedUser.LastSignInDateTime -End (Get-Date)).Days
                $checkedUser.lastSignInRequestId = $userObject.signInActivity.lastSignInRequestId

                #lastNonInteractiveSignInDateTime is NULL
                If ($null -eq $userObject.signInActivity.lastNonInteractiveSignInDateTime){
                    $checkedUser.lastNonInteractiveSignInDateTime = "Unknown"
                    $checkedUser.LastNonInteractiveSigninDaysAgo = "Unknown"

                } else {
                    $checkedUser.lastNonInteractiveSignInDateTime = $userObject.signInActivity.lastNonInteractiveSignInDateTime
                    $checkedUser.LastNonInteractiveSigninDaysAgo = (New-TimeSpan -Start $checkedUser.lastNonInteractiveSignInDateTime -End (Get-Date)).Days
                    $checkedUser.lastNonInteractiveSignInRequestId = $userObject.signInActivity.lastNonInteractiveSignInRequestId
                }
            }
            If ($null -eq $userObject.CreatedDateTime) {
                $checkedUser.CreatedDateTime = "Unknown"
                $checkedUser.CreatedDaysAgo = "Unknown"
            }
            else {
                $checkedUser.CreatedDateTime = $userObject.CreatedDateTime
                $checkedUser.CreatedDaysAgo = (New-TimeSpan -Start $userObject.CreatedDateTime -End (Get-Date)).Days
            }

            Write-Output ([pscustomobject]$checkedUser)
        }

    }

    end {
        if ($CriticalError) { return }
    }
}
