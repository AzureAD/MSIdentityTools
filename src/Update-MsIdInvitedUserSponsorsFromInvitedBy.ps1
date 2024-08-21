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
        # Enumerate and Update All Guest Users
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
        if ($All) {

            $InvitedUsers = Get-MgUser -Filter $guestFilter -All -ExpandProperty Sponsors
        }
        else {
            foreach ($user in $userId) {

                $InvitedUsers += Get-MgUser -UserId $user -ExpandProperty Sponsors
            }
        }

        if ($null -eq $InvitedUsers) {
            Write-Information "No Guest Users to Process!"
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
                        Write-Verbose ("Sponsors does not contain the user who invited them!")

                        if ($PSCmdlet.ShouldProcess(("{0} - {1}" -f $InvitedUser.displayName, $InvitedUser.id), "Update Sponsors")) {
                            try {

                                $sponsosUrl = $null
                                $dirobj = $null
                                $sponsorsRequestBody = $null

                                $sponsorUrl = ("https://graph.microsoft.com/beta/users/{0}" -f $invitedBy.value.id)
                                $dirObj = @{"sponsors@odata.bind" = @($sponsorUrl) }
                                $sponsorsRequestBody = $dirObj | ConvertTo-Json


                                Update-MgUser -UserId $InvitedUser.Id -BodyParameter $sponsorsRequestBody
                                Write-Verbose ("Sponsors Updated for {0}" -f $InvitedUser.DisplayName)

                            }
                            catch {

                                Write-Error $_

                            }
                        }


                    }
                    else {
                        Write-Verbose ("------------> Sponsors already contains the user who invited them!")
                    }
                }
                else {
                    write-verbose ("------->InvitedBy is not available for this user!")
                }


            }
        }

    }

    end {

        Write-Verbose "Complete!"

    }
}
