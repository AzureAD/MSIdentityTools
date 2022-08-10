<#
.SYNOPSIS
    Retrieve Users who have not had interactive sign ins since XX days ago

.EXAMPLE
    PS > Get-MsIdUnredeemedInvitedUser -InvitedBeforeDaysAgo 30

    Retrieve Users who have been invited but have not redeemed greater than XX days ago

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
function Get-MsIdUnredeemedInvitedUser {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # External User Invited XX Days Ago
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [int] $InvitedBeforeDaysAgo = 30
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        try {


            ## Check MgModule Connection
            $MgContext = Get-MgContext
            if ($MgContext) {
                ## Check MgModule Consented Scopes
                $MgPermissions = Find-MgGraphCommand -Command Get-MgUser -ApiVersion beta | Select-Object -First 1 -ExpandProperty Permissions
                if (!(Compare-Object $MgPermissions.Name -DifferenceObject $MgContext.Scopes -ExcludeDifferent)) {
                    Write-Error "Additional scope needed, call Connect-MgGraph with one of the following scopes: $($MgPermissions.Name -join ', ')" -ErrorAction Stop
                }
            }
            else {
                Write-Error "Authentication needed, call Connect-MgGraph." -ErrorAction Stop
            }
        }
        catch { Write-Error -ErrorRecord $_ -ErrorVariable CriticalError; return }

        ## Save Current MgProfile to Restore at End
        $previousMgProfile = Get-MgProfile
        if ($previousMgProfile.Name -ne 'beta') {
            Select-MgProfile -Name 'beta'
        }

    }

    process {
        if ($CriticalError) { return }

        $queryUsers = $null

        $queryDate = Get-Date (Get-Date).AddDays($(0 - $LastSignInBeforeDaysAgo)) -UFormat %Y-%m-%dT00:00:00Z

        $UnredeemedFilter = ("(externalUserState eq 'PendingAcceptance')")
        #To Add: Detection for invited users without externalUserState values

        $queryFilter = $UnredeemedFilter

        Write-Debug ("Retrieving Invited Users who are not redeemed with filter {0}" -f $queryFilter)
        $queryUsers = Get-MgUser -Filter $queryFilter -All:$true -Property ExternalUserState, ExternalUserStateChangeDateTime, UserPrincipalName, Id, DisplayName, mail, userType, AccountEnabled -ConsistencyLevel eventual -CountVariable $UnredeemedUsersCount

        Write-Verbose ("{0} Unredeemed Invite Users Found!" -f $UnredeemedUsersCount)
        foreach ($userObject in $queryUsers) {
            Write-Verbose ("User {0}" -f $userObject.id)
            $checkedUser = [ordered] @{}
            $checkedUser.UserID = $userObject.Id
            $checkedUser.DisplayName = $userObject.DisplayName
            $checkedUser.UserPrincipalName = $userObject.UserPrincipalName
            $checkedUser.AccountEnabled = $userObject.AccountEnabled
            $checkedUser.Mail = $userObject.Mail
            $checkedUser.UserType = $userObject.UserType
            $checkedUser.Identities = $userObject.Identities
            $checkedUser.ExternalUserState = $userObject.ExternalUserState

            If ($null -eq $userObject.ExternalUserStateChangeDateTime) {
                $checkedUser.ExternalUserStateChangeDateTime = "Unknown"
                $checkedUser.InvitedDaysAgo = "Unknown"

            }
            else {
                $checkedUser.ExternalUserStateChangeDateTime = $userObject.ExternalUserStateChangeDateTime
                $checkedUser.InvitedDaysAgo = (New-TimeSpan -Start $userObject.ExternalUserStateChangeDateTime -End (Get-Date)).Days

            }

            if ($checkedUser.ExternalUserStateChangeDateTime -eq 'Unknown' -or $checkedUser.InvitedDaysAgo -ge $InvitedBeforeDaysAgo) {
                Write-Output ([pscustomobject]$checkedUser)
            }
        }

    }

    end {
        if ($CriticalError) { return }

        ## Restore Previous MgProfile
        if ($previousMgProfile -and $previousMgProfile.Name -ne (Get-MgProfile).Name) {
            Select-MgProfile -Name $previousMgProfile.Name
        }
    }
}
