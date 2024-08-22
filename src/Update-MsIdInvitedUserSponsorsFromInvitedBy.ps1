<#
.Synopsis
   Update the Sponsors attribute to include the user who initially invited them to the tenant using the InvitedBy property. This script can be used to backfill Sponsors attribute for existing users.
.DESCRIPTION
   Update the Sponsors attribute to include the user who initially invited them to the tenant

.LINK
Feature Page: https://learn.microsoft.com/en-us/azure/active-directory/external-identities/b2b-sponsors
EM: https://learn.microsoft.com/en-us/azure/active-directory/governance/entitlement-management-access-package-create\

API Docs:
Sponsors api - https://learn.microsoft.com/en-us/graph/api/user-post-sponsors?view=graph-rest-beta
Invite api - https://learn.microsoft.com/en-us/graph/api/resources/invitation?view=graph-rest-beta
ELM - https://learn.microsoft.com/en-us/graph/api/resources/entitlementmanagement-overview?view=graph-rest-beta
Invited BY - https://learn.microsoft.com/en-us/graph/api/user-list-invitedby?view=graph-rest-beta

.EXAMPLE
   Update-MsIdInvitedUserSponsorsFromInvitedBy

   Enumerate all invited users in the Tenant and update Sponsors using InvitedBy value

.EXAMPLE
   Update-MsIdInvitedUserSponsorsFromInvitedBy -All

   Enumerate all invited users in the Tenant and update Sponsors using InvitedBy value

.EXAMPLE
   Update-MsIdInvitedUserSponsorsFromInvitedBy -UserId user1@contoso.com,user2@contoso.com

   For only specified users in the tenant update Sponsors using InvitedBy value
#>
function Update-MsIdInvitedUserSponsorsFromInvitedBy {
    [CmdletBinding(SupportsShouldProcess,
        ConfirmImpact = 'High',
        DefaultParameterSetName = 'AllInvitedGuests')]
    param (

        # UserId of Guest User
        [Parameter(ParameterSetName = 'ByUsers')]
        [String[]]
        $UserId,
        # Enumerate and Update All Guest Users.
        [Parameter(ParameterSetName = 'AllInvitedGuests')]
        [switch]
        $All
    )

    begin {

        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'Get-Mguser', 'Update-Mguser' -MinimumVersion 2.8.0 -ErrorVariable CriticalError)) { return }

        $guestFilter = "(CreationType eq 'Invitation')"
    }

    process {
        if ($CriticalError) { return }
        if ($null -eq $UserId -and !$All) {
            Write-Error "Please specify either -UserId or -All"
            return
        }

        if ($All) {
            $InvitedUsers = Get-MgUser -Filter $guestFilter -All -ExpandProperty Sponsors
        }
        else {
            foreach ($user in $userId) {
                $InvitedUsers += Get-MgUser -UserId $user -ExpandProperty Sponsors
            }
        }

        if ($null -eq $InvitedUsers) {
            Write-Error "No guest users to process"
        }
        else {
            foreach ($InvitedUser in $InvitedUsers) {
                $invitedBy = $null

                $splatArgumentsGetInvitedBy = @{
                    Method = 'Get'
                    Uri    = ((Get-MgEnvironment -Name (Get-MgContext).Environment).GraphEndpoint +
                        "/beta/users/" + $InvitedUser.Id + "/invitedBy")
                }

                $invitedBy = Invoke-MgGraphRequest @splatArgumentsGetInvitedBy

                Write-Verbose ($invitedBy | ConvertTo-Json -Depth 10)

                if ($null -ne $invitedBy -and $null -ne $invitedBy.value -and $null -ne (Get-ObjectPropertyValue $invitedBy.value -Property 'id')) {
                    Write-Verbose ("InvitedBy for Guest User {0}: {1}" -f $InvitedUser.DisplayName, $invitedBy.value.id)

                    if (($null -like $InvitedUser.Sponsors) -or ($InvitedUser.Sponsors.id -notcontains $invitedBy.value.id)) {
                        Write-Verbose "Sponsors does not contain the user who invited them!"

                        if ($PSCmdlet.ShouldProcess(("$($InvitedUser.displayName) ($($InvitedUser.UserPrincipalName) - $($InvitedUser.id))"), "Update Sponsors")) {
                            try {
                                $sponsorUrl = ("https://graph.microsoft.com/beta/users/{0}" -f $invitedBy.value.id)
                                $dirObj = @{"sponsors@odata.bind" = @($sponsorUrl) }
                                $sponsorsRequestBody = $dirObj | ConvertTo-Json

                                Update-MgUser -UserId $InvitedUser.Id -BodyParameter $sponsorsRequestBody
                                Write-Output "$($InvitedUser.UserPrincipalName) - Sponsor updated succesfully for this user."
                            }
                            catch {
                                Write-Output "$($InvitedUser.UserPrincipalName) - Failed updating sponsor for this user."
                                Write-Error $_
                            }
                        }
                    }
                    else {
                        Write-Output "$($InvitedUser.UserPrincipalName) - Sponsor already exists for this user."
                    }
                }
                else {
                    Write-Output "$($InvitedUser.UserPrincipalName) - Invited user information not available for this user."
                }
            }
        }
    }

    end {
        Write-Verbose "Complete!"
    }
}
