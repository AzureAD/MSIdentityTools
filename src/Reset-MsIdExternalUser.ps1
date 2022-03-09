<#
.SYNOPSIS
    Resets the redemption state of an external user.

.EXAMPLE
    PS > Reset-MsIdExternalUser -UserId 1468b68b-8536-4bc5-ab1f-6014175b836d

    Resets the invitation state of an external user.

.EXAMPLE
    PS > Reset-MsIdExternalUser -UserId 1468b68b-8536-4bc5-ab1f-6014175b836d -SendInvitationMessage

    Resets the invitation state of an external user and sends them the invitation redemption mail.

.EXAMPLE
    PS > $user = Get-MgUser -Filter "startsWith(mail, 'john.doe@fabrikam.net')"
    PS > Reset-MsIdExternalUser -UserId $user.Id

    Resets the invitation state of an external user with the email address john.doe@fabrikam.net.

.EXAMPLE
    PS > $users = Get-MgUser -Filter "endsWith(mail, '@fabrikam.net')"
    PS > $users | Reset-MsIdExternalUser -UserId $user.Id -SendInvitationMessage

    Resets the invitation state of all external users from fabrikam.net and sends them an invitation mail.

.EXAMPLE
    PS > Get-MsIdUnmanagedExternalUser | Reset-MsIdExternalUser

    Resets the invitation state of all unmanaged external users in the tenant.

#>
function Reset-MsIdExternalUser {
    [CmdletBinding(DefaultParameterSetName = 'ObjectId')]
    param (
        # ObjectId of external user
        [Parameter(Mandatory = $true, ParameterSetName = 'ObjectId', Position = 0, ValueFromPipeline = $true)]
        [string] $UserId,

        # User object of external user
        [Parameter(Mandatory = $true, ParameterSetName = 'GraphUser', Position = 0, ValueFromPipeline = $true)]
        [psobject] $User,
        
        # The url to redirect the user to after they redeem the link
        # Defaults to My Apps page of the inviter's home tenant. https://myapps.microsoft.com?tenantId={tenantId}
        [Parameter(Mandatory = $false, ParameterSetName = 'ObjectId', Position = 1, ValueFromPipeline = $false)]
        [Parameter(Mandatory = $false, ParameterSetName = 'GraphUser', Position = 1, ValueFromPipeline = $false)]
        [string] $InviteRedirectUrl,

        # Sends an email notification to the user with the guest invitation redemption link
        [Parameter(Mandatory = $false, ParameterSetName = 'ObjectId', Position = 2, ValueFromPipeline = $false)]
        [Parameter(Mandatory = $false, ParameterSetName = 'GraphUser', Position = 2, ValueFromPipeline = $false)]
        [switch] $SendInvitationMessage
    )

    begin {
        
        ## Initialize Critical Dependencies

        $CriticalError = $null
        try {
            Import-Module Microsoft.Graph.Identity.SignIns -MinimumVersion 1.9.2 -ErrorAction Stop
        }
        catch { Write-Error -ErrorRecord $_ -ErrorVariable CriticalError; return }

        $previousProfile = Get-MgProfile
        if ($previousProfile.Name -ne 'beta') {
            Select-MgProfile -Name 'beta'
        }
    
        if (!$InviteRedirectUrl) {
            $tenantId = (Get-MgContext).TenantId
            $InviteRedirectUrl = "https://myapps.microsoft.com?tenantId=$tenantId"
        }
        $doSendInvitationMessage = $SendInvitationMessage.IsPresent
    }

    process {
        function Send-Invitation {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
                [psobject]$GraphUser
            )

            # check that object has requried properties
            if ($GraphUser.psobject.Properties.Name -inotcontains "id") {
                Write-Error "No provided user id"
            } 
            if ($GraphUser.psobject.Properties.Name -inotcontains "mail") {
                Write-Error "No provided user mail"
            } 
            # check that values are not empty
            if ([string]::IsNullOrWhiteSpace($GraphUser.Id)) {
                Write-Error "Provided user id is empty"
            }
            if ([string]::IsNullOrWhiteSpace($GraphUser.Mail)) {
                Write-Error "Provided user mail is empty"
            }
            # send the invitation
            New-MgInvitation `
                -InvitedUserEmailAddress $GraphUser.Mail `
                -InviteRedirectUrl $InviteRedirectUrl `
                -ResetRedemption `
                -SendInvitationMessage:$doSendInvitationMessage `
                -InvitedUser @{ "id" = $GraphUser.Id }
        }

        # don't process further if there is a critical error
        if ($CriticalError) {
            return
        }

        switch ($PSCmdlet.ParameterSetName) {
            "ObjectId" {
                $graphUser = Get-MgUser -UserId $UserId
                if ($graphUser) {
                    Send-Invitation $graphUser
                }
                else {
                    Write-Error "User not found."
                }    
                break
            }
            "GraphUser" {
                Send-Invitation $User
                break
            }
        }
    }

    end {
        if ($previousProfile.Name -ne (Get-MgProfile).Name) {
            Select-MgProfile -Name $previousProfile.Name
        }
    }
}
