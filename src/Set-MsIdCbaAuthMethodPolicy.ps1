<#
.SYNOPSIS
    Configure and enable users for CBA
    
.DESCRIPTION
    
    
.EXAMPLE
    PS > Set-MsIdCbaAuthMethodPolicy -CertificateField 'PrincipalName' -AadUserProperty 'userPrincipalName'

    Configure CBA auth method policy

.INPUTS
    System.String

#>
function Set-MsIdCbaAuthMethodPolicy {
    [CmdletBinding()]
    [OutputType()]
    param (
        # 
        [Parameter(Mandatory = $true)]
        [ValidateSet("PrincipalName", "RFC822Name", "X509SKI", "X509SHA1PublicKey")]
        [switch] $CertificateField,
        # 
        [Parameter(Mandatory = $true)]
        [ValidateSet("userPrincipalName", "onPremisesUserPrincipalName", "certificateUserIds")]
        [hashtable] $AadUserProperty,
        # Enable only pilot group users
        [Parameter(Mandatory = $false)]
        [string[]] $PilotGroupId
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration' -MinimumVersion 1.9.2 -ErrorVariable CriticalError)) { return }
    }

    process {
        if ($CriticalError) { return }

        ## ToDo: Update CBA auth method policy for all users or just pilot group(s)
        #Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration
    }
}
