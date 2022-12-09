<#
.SYNOPSIS
    Find Users with Admin Roles that are not registered for MFA
.DESCRIPTION
    Find Users with Admin Roles that are not registered for MFA by evaluating their authentication methods registered for MFA and their sign-in activity.
.EXAMPLE
    PS > Find-MsIdUnprotectedUsersWithAdminRoles

    Enumerate users with role assignments
.EXAMPLE
    PS > Find-MsIdUnprotectedUsersWithAdminRoles -includeSignIns:$false

    Enumerate users with role assignments including their sign in activity
.NOTES
     - Eligible users for roles may not have active assignments showing in their directoryrolememberships, but they have the potential to elevate to assigned roles
     - Large amounts of role assignments may take time process.
     - Must be connected to MS Graph with appropriate scopes for reading user, group, application, role, an sign in information and selected the beta profile before running.
      --  Connect-MgGraph -scopes RoleManagement.Read.Directory,UserAuthenticationMethod.Read.All,AuditLog.Read.All,User.Read.All,Group.Read.All,Application.Read.All
      --  Select-MgProfile -name Beta
#>
function Find-MsIdUnprotectedUsersWithAdminRoles {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # Include Sign In log activity -  Note this can cause the query to run slower in larger active environments
        [switch] $IncludeSignIns
    )
    
    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'Get-MgUser', 'Get-MgUserAuthenticationMethod', 'Get-MgGroupMember', 'Get-MgRoleManagementDirectoryRoleDefinition', 'Get-MgRoleManagementDirectoryRoleAssignmentSchedule', 'Get-MgRoleManagementDirectoryRoleEligibilitySchedule', 'Get-MgAuditLogSignIn' -ApiVersion beta -MinimumVersion 1.9.2 -RequireListPermissions -ErrorVariable CriticalError)) { return }
        
        ## Save Current MgProfile to Restore at End
        $previousMgProfile = Get-MgProfile
        if ($previousMgProfile.Name -ne 'beta') {
            Select-MgProfile -Name 'beta' -Verbose:$false # -Verbose:$false is not suppressing output
        }

        if ($VerbosePreference -eq 'SilentlyContinue') {
            Write-Host "NOTE:  This process may take awhile depending on the size of the environment.   Please run with -Verbose switch for more details progress output."
        }

    }
    
    process {
        if ($CriticalError) { return }

        [array]$usersWithRoles = Get-UsersWithRoleAssignments
       
        $TotalUsersCount = $usersWithRoles.count
        Write-Verbose ("Checking {0} users with roles..." -f $TotalUsersCount)

        [array]$checkedUsers = @()
        $checkUsersCount = 0
        
        foreach ($user in $usersWithRoles) {

            $checkUsersCount++

            $userObject = $null
            try {
                $userObject = Get-MgUser -UserId $user.PrincipalId -Property signInActivity, UserPrincipalName, Id
            }
            catch {
                Write-Warning ("User object with UserId {0} with a role assignment was not found!  Review assignment for orphaned user." -f $user.PrincipalId)
            }

            Write-Verbose ("User {0} of {1} - Evaluating {2} with role assignments...." -f $checkUsersCount, $TotalUsersCount, $userObject.Id)

            if ($Null -ne $userObject) {
                $UserAuthMethodStatus = Get-UserMfaRegisteredStatus -UserId $userObject.UserPrincipalName

                $checkedUser = [ordered] @{}
                $checkedUser.UserID = $userObject.Id
                $checkedUser.UserPrincipalName = $userObject.UserPrincipalName
            
                If ($null -eq $userObject.signInActivity.LastSignInDateTime) {
                    $checkedUser.LastSignInDateTime = "Unknown"
                    $checkedUser.LastSigninDaysAgo = "Unknown"
                }
                else {
                    $checkedUser.LastSignInDateTime = $userObject.signInActivity.LastSignInDateTime
                    $checkedUser.LastSigninDaysAgo = (New-TimeSpan -Start $checkedUser.LastSignInDateTime -End (Get-Date)).Days
                }
                $checkedUser.DirectoryRoleAssignments = $user.RoleName
                $checkedUser.DirectoryRoleAssignmentType = $user.AssignmentType
                $checkedUser.DirectoryRoleAssignmentCount = $user.RoleName.count
                $checkedUser.RoleAssignedBy = $user.RoleAssignedBy
                $checkedUser.IsMfaRegistered = $UserAuthMethodStatus.isMfaRegistered
                $checkedUser.Status = $UserAuthMethodStatus.Status

                if ($includeSignIns -eq $true) {
                    $signInInfo = Get-UserSignInSuccessHistoryAuth -userId $checkedUser.UserId

                    $checkedUser.SuccessSignIns = $signInInfo.SuccessSignIns
                    $checkedUser.MultiFactorSignIns = $signInInfo.MultiFactorSignIns
                    $checkedUser.SingleFactorSignIns = $signInInfo.SingleFactorSignIns
                    $checkedUser.RiskySignIns = $signInInfo.RiskySignIns
                }
                else {
                    $checkedUser.SuccessSignIns = "Skipped"
                    $checkedUser.MultiFactorSignIns = "Skipped"
                    $checkedUser.SingleFactorSignIns = "Skipped"
                    $checkedUser.RiskySignIns = "Skipped"
                }
                $checkedUsers += ([pscustomobject]$checkedUser)
            }
            else {
                
                $checkedUser = [ordered] @{}
                $checkedUser.UserID = $userObject.Id
                $checkedUser.Status = "Not Exists"

            }
        }

    }
    
    end {
        if ($CriticalError) { return }

        Write-Verbose ("{0} Users Evaluated!" -f $checkedUsers.count)
        Write-Verbose ("{0} Users with roles who are NOT registered for MFA!" -f ($checkedUsers | Where-Object -FilterScript { $_.isMfaRegistered -eq $false }).count)
        Write-Output $checkedUsers

        ## Restore Previous MgProfile
        if ($previousMgProfile -and $previousMgProfile.Name -ne (Get-MgProfile).Name) {
            Select-MgProfile -Name $previousMgProfile.Name -Verbose:$false # -Verbose:$false is not suppressing output
        }
    }
}

function Get-UserMfaRegisteredStatus ([string]$UserId) {

    $mfaMethods = @("#microsoft.graph.fido2AuthenticationMethod", "#microsoft.graph.softwareOathAuthenticationMethod", "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod", "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod", "#microsoft.graph.phoneAuthenticationMethod")

    $results = [pscustomobject]@{
        IsMfaRegistered = $null
        AuthMethodsRegistered = $null
        status = $null
    }
    
    try {
        $authMethods = (Get-MgUserAuthenticationMethod -UserId $UserId).AdditionalProperties."@odata.type"

        $isMfaRegistered = $false
        foreach ($mfa in $MfaMethods) { if ($authmethods -contains $mfa) { $isMfaRegistered = $true } }

        $results.IsMfaRegistered = $isMfaRegistered
        $results.AuthMethodsRegistered = $authMethods
        $results.status = "Checked"
        
    }
    catch {
        $results.status = "Unknown"
    }

    Write-Output $results

}

function Get-UserSignInSuccessHistoryAuth ([string]$userId) {

    $signinAuth = @{}
    $signinAuth.UserID = $userId
    $signinAuth.SuccessSignIns = 0
    $signinAuth.MultiFactorSignIns = 0
    $signinAuth.SingleFactorSignIns = 0
    $signInAuth.RiskySignIns = 0

    $filter = ("UserId eq '{0}' and status/errorCode eq 0" -f $userId)
    Write-Debug $filter
    [array]$signins = Get-MgAuditLogSignIn -Filter $filter -all:$True
    Write-Debug $signins.count

    if ($signins.count -gt 0) {

        $signinAuth.SuccessSignIns = $signins.count
        $groupedAuth = $signins | Group-Object -Property AuthenticationRequirement

        $MfaSignInsCount = 0
        $MfaSignInsCount = $groupedAuth | Where-Object -FilterScript { $_.Name -eq 'multiFactorAuthentication' } | Select-Object -ExpandProperty count
        if ($null -eq $MfaSignInsCount) {
            $MfaSignInsCount = 0
        }
        $signinAuth.MultiFactorSignIns = $MfaSignInsCount

        $singleFactorSignInsCount = 0
        $singleFactorSignInsCount = $groupedAuth | Where-Object -FilterScript { $_.Name -eq 'singleFactorAuthentication' } | Select-Object -ExpandProperty count


        if ($null -eq $singleFactorSignInsCount) {
            $singleFactorSignInsCount = 0
        }
        $signinAuth.SingleFactorSignIns = $singleFactorSignInsCount

        $signInAuth.RiskySignIns = ($signins | Where-Object -FilterScript { $_.RiskLevelDuringSignIn -ne 'none' } | Measure-Object | Select-Object -ExpandProperty Count)

    }

    Write-Output ([pscustomobject]$signinAuth)
}

function Get-UsersWithRoleAssignments() {
    [array]$uniquePrincipals = $null
    [array]$usersWithRoles = $Null
    [array]$groupsWithRoles = $null
    [array]$servicePrincipalsWithRoles = $null
    [array]$roleAssignments = @()
    [array]$activeRoleAssignments = $null
    [array]$eligibleRoleAssignments = $null
    [array]$AssignmentSchedule = @()

    Write-Verbose "Retrieving Active Role Assignments..."
    $activeRoleAssignments = Get-MgRoleManagementDirectoryRoleAssignmentSchedule -All:$true -ExpandProperty Principal | Add-Member -MemberType NoteProperty -Name AssignmentScope -Value "Active" -Force -PassThru | Add-Member -MemberType ScriptProperty -Name PrincipalType -Value { $this.Principal.AdditionalProperties."@odata.type".split('.')[2] } -Force -PassThru
    Write-Verbose ("{0} Active Role Assignments..." -f $activeRoleAssignments.count)
    $AssignmentSchedule += $activeRoleAssignments
    
    Write-Verbose "Retrieving Eligible Role Assignments..."
    $eligibleRoleAssignments = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -All:$true -ExpandProperty Principal | Add-Member -MemberType NoteProperty -Name AssignmentScope -Value "Eligible" -Force -PassThru | Add-Member -MemberType ScriptProperty -Name PrincipalType -Value { $this.Principal.AdditionalProperties."@odata.type".split('.')[2] } -Force -PassThru
    Write-Verbose ("{0} Eligible Role Assignments..." -f $eligibleRoleAssignments.count)
    $AssignmentSchedule += $eligibleRoleAssignments

    Write-Verbose ("{0} Total Role Assignments to all principals..." -f $AssignmentSchedule.count)
    $uniquePrincipals = $AssignmentSchedule.PrincipalId | Get-Unique
    Write-Verbose ("{0} Total Role Assignments to unique principals..." -f $uniquePrincipals.count)

    foreach ($type in ($AssignmentSchedule | Group-Object PrincipalType)) {
        Write-Verbose ("{0} assignments to {1} type" -f $type.count, $type.name)
    }
    
    foreach ($assignment in ($AssignmentSchedule)) {
        
        if ($assignment.PrincipalType -eq 'user') {
            $roleAssignment = @{}
            $roleAssignment.PrincipalId = $assignment.PrincipalId
            $roleAssignment.PrincipalType = $assignment.PrincipalType
            $roleAssignment.AssignmentType = $assignment.AssignmentScope
            $roleAssignment.RoleDefinitionId = $assignment.RoleDefinitionId
            $roleAssignment.RoleAssignedBy = "user"
            $roleAssignment.RoleName = [array](Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $assignment.RoleDefinitionId | Select-Object -ExpandProperty displayName)
            $roleAssignments += ([pscustomobject]$roleAssignment)
        }
       
        if ($assignment.PrincipalType -eq 'group') {
            Write-Verbose ("Expanding Group Members for Role Assignable Group {0}" -f $assignment.PrincipalId)
            $groupMembers = Get-MgGroupMember -GroupId $assignment.PrincipalId | Select-Object -ExpandProperty Id

            [array]$RoleName = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $assignment.RoleDefinitionId | Select-Object -ExpandProperty displayName

            foreach ($member in $groupMembers) {
                Write-Verbose ("Adding Group Member {0} for Role Assignable Group {0}" -f $member, $assignment.PrincipalId)
               
                $roleAssignment = @{}
                $roleAssignment.PrincipalId = $member
                $roleAssignment.PrincipalType = "user"
                $roleAssignment.AssignmentType = $assignment.AssignmentScope
                $roleAssignment.RoleDefinitionId = $assignment.RoleDefinitionId
                $roleAssignment.RoleAssignedBy = "group"
                $roleAssignment.RoleName = $RoleName
                $roleAssignments += ([pscustomobject]$roleAssignment)

            }
        }

    }
        
    $usersWithRoles = $roleAssignments | Where-Object -FilterScript { $_.PrincipalType -eq 'user' }
    Write-Verbose ("{0} Total Role Assignments to Users" -f $usersWithRoles.count)

    Write-Output $usersWithRoles
}
