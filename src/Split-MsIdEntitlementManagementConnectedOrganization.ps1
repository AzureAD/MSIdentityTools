<#
.Synopsis
Split elements of a connectedOrganization
.Description
Split elements of one or more Azure AD entitlement management connected organizations, returned by Get-MgEntitlementManagementConnectedOrganization, to simplify reporting.
.Inputs
Microsoft.Graph.PowerShell.Models.MicrosoftGraphConnectedOrganization

#>
function Split-MsIdEntitlementManagementConnectedOrganization {
[CmdletBinding(DefaultParameterSetName='SplitByIdentitySource', PositionalBinding=$false, ConfirmImpact='Medium')]
param(

    [Parameter(ValueFromPipeline=$true,ParameterSetName='SplitByIdentitySource')]
    [Microsoft.Graph.PowerShell.Models.MicrosoftGraphConnectedOrganization[]]
    # The connected organization.
    ${ConnectedOrganization},

    [Parameter(Mandatory=$true, ParameterSetName='SplitByIdentitySource')]
    [switch]
    ${ByIdentitySource}

)

begin {

}

process {
    if ($ByIdentitySource) {

        if ($null -ne $ConnectedOrganization.IdentitySources) {
            foreach ($is in $ConnectedOrganization.IdentitySources) {
                # identity sources, as an abstract class, does not have any properties

                $aObj = [pscustomobject]@{
                    ConnectedOrganizationId = $ConnectedOrganization.Id
                }
            
                $addl = $is.AdditionalProperties
                foreach ($k in $addl.Keys) {
                    $isk = $k
                    $aObj | Add-Member -MemberType NoteProperty -Name $isk -Value $addl[$k] -Force
                }

                write-output $aObj
            }
        }
    }
}

end {

}
}
