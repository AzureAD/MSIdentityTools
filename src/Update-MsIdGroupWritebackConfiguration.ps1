<#
.SYNOPSIS
    Update an Azure AD cloud group settings to writeback as an AD on-premises group

.EXAMPLE
    PS > Update-MsIdGroupWritebackConfiguration -GroupId <GroupId> -WriteBackEnabled $false

    Disable Group Writeback for Group ID

.EXAMPLE
    PS > Update-MsIdGroupWritebackConfiguration -GroupId <GroupId> -WriteBackEnabled $true -WriteBackOnPremGroupType universalDistributionGroup

    Enable Group Writeback for Group ID as universalDistributionGroup on-premises
.EXAMPLE
    PS > Update-MsIdGroupWritebackConfiguration -GroupId <GroupId> -WriteBackEnabled $false

    Disable Group Writeback for Group ID
.EXAMPLE
    PS > Get-mggroup -filter "groupTypes/any(c:c eq 'Unified')"|Update-MsIdGroupWritebackConfiguration -WriteBackEnabled $false -verbose

    For all M365 Groups in the tenant, set the WritebackEnabled to false to prevent them from being written back on-premises
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
function Update-MsIdGroupWritebackConfiguration {
    [CmdletBinding(DefaultParameterSetName = 'ObjectId')]
    param (
        # Group Object ID
        [Parameter(Mandatory = $true, ParameterSetName = 'ObjectId', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript( {
                try {
                    [System.Guid]::Parse($_) | Out-Null
                    $true
                }
                catch {
                    throw "$_ is not a valid ObjectID format. Valid value is a GUID format only."
                }
            })]
        [string[]] $GroupId,

        # Group Object
        [Parameter(Mandatory = $true, ParameterSetName = 'GraphGroup', Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Object[]] $Group,

        # WritebackEnabled true or false
        [Parameter(Mandatory = $true, Position = 2, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
        [bool] $WriteBackEnabled,

        # On-Premises Group Type cloud group is written back as
        [Parameter(Mandatory = $false, Position = 3, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
        [ValidateSet("universalDistributionGroup", "universalSecurityGroup", "universalMailEnabledSecurityGroup")]
        [string] $WriteBackOnPremGroupType
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'Get-MgGroup', 'Update-MgGroup' -MinimumVersion 2.8.0 -ErrorVariable CriticalError)) { return }
    }

    process {
        if ($CriticalError) { return }

        if ($null -ne $Group) {
            $GroupId = $group.id
        }

        foreach ($gid in $GroupId) {
            $currentIsEnabled = $null
            $currentOnPremGroupType = $null
            $mgGroup = $null
            $groupSourceOfAuthority = $null
            $wbc = @{}
            $skipUpdate = $false

            Write-Verbose ("Retrieving mgGroup for Group ID {0}" -f $gid)
            $mgGroup = Get-MgGroup -GroupId $gid
            Write-Debug ($mgGroup | Select-Object -Property Id, DisplayName, GroupTypes, SecurityEnabled, OnPremisesSyncEnabled -Expand WritebackConfiguration | Select-Object -Property Id, DisplayName, GroupTypes, SecurityEnabled, OnPremisesSyncEnabled, IsEnabled, OnPremisesGroupType | Out-String)


            $currentOnPremGroupType = $mgGroup.WritebackConfiguration.OnPremisesGroupType

            $currentIsEnabled = $mgGroup.WritebackConfiguration.IsEnabled
            $cloudGroupType = $null

            if ($mggroup.GroupTypes -contains 'Unified') {
                $cloudGroupType = "M365"
            }
            else {

                if ($mgGroup.SecurityEnabled -eq $true) {
                    $cloudGroupType = "Security"

                    if ($null -notlike $mgGroup.ProxyAddresses) {
                        $cloudGroupType = "Mail-Enabled Security"
                    }
                }
                else {
                    $cloudGroupType = "Distribution"
                }
            }

            $groupSourceOfAuthority = if ($mgGroup.OnPremisesSyncEnabled -eq $true) { "On-Premises" }else { "Cloud" }


            if ($groupSourceOfAuthority -eq 'On-Premises') {
                $skipUpdate = $true
                Write-Verbose ("Group {0} is an on-premises SOA group and will not be updated." -f $gid)
            }
            else {

                switch ($cloudGroupType) {
                    "Distribution" {
                        $skipUpdate = $true
                        Write-Error ("Group {0} is a cloud distribution group and will NOT be updated. Cloud Distribution Groups are not supported for group writeback to on-premises. Use M365 groups instead." -f $gid)

                    }
                    "Mail-Enabled Security" {
                        $skipUpdate = $true
                        Write-Error ("Group {0} is a mail-enabled security group and will NOT be updated. Cloud mail-enabled security groups are not supported for group writeback to on-premises. Use M365 groups instead." -f $gid)

                    }
                    "Security" {


                        Write-Verbose ("Group {0} is a Security Group with current IsEnabled of {1} and onPremisesGroupType of {2}." -f $gid, $currentIsEnabled, $currentOnPremGroupType)

                        if ($currentIsEnabled -eq $WriteBackEnabled) {
                            $skipUpdate = $true
                            Write-Verbose "WriteBackEnabled $WriteBackEnabled already set for Security Group!"
                        }
                        else {

                            $wbc.isEnabled = $WriteBackEnabled

                            if ($null -eq $currentOnPremGroupType -or $currentOnPremGroupType -ne 'universalSecurityGroup') {
                                if ($null -ne $WriteBackOnPremGroupType -and $WriteBackOnPremGroupType -ne 'universalSecurityGroup') {
                                    $skipUpdate = $true
                                    Write-Error ("{0} is not a cloud security group and can only be written back as a univeralSecurityGroup type which is not currently set for this group!" -f $gid)

                                }
                                else {


                                    if ($null -eq $currentOnPremGroupType -ne $WriteBackOnPremGroupType) {
                                        $wbc.onPremisesGroupType = $WriteBackOnPremGroupType
                                    }
                                }
                            }

                        }
                    }

                    "M365" {

                        Write-Verbose ("Group {0} is an M365 Group with current IsEnabled of {1} and onPremisesGroupType of {2}." -f $gid, $currentIsEnabled, $currentOnPremGroupType)
                        if ($currentIsEnabled -eq $WriteBackEnabled) {
                            $skipUpdate = $true
                            Write-Verbose "WriteBackEnabled $WriteBackEnabled already set for M365 Group!"
                        }
                        else {

                            $wbc.isEnabled = $WriteBackEnabled

                            if ($currentOnPremGroupType -ne $WriteBackOnPremGroupType) {


                                $wbc.onPremisesGroupType = $WriteBackOnPremGroupType

                            }

                        }

                    }

                }

                if ($wbc.Count -eq 0) {
                    $skipUpdate = $true
                }

                if ($skipUpdate -ne $true) {
                    Write-Debug ($wbc | Out-String)
                    Write-Verbose ("Updating Group {0} with Group Writeback settings of Writebackenabled={1} and onPremisesGroupType={2}" -f $gid, $WriteBackEnabled, $WriteBackOnPremGroupType )

                    if ($null -like $wbc.onPremisesGroupType) {

                        # Workaround for null properties issue filed on GitHub - https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/833
                        $root = @{}
                        $root.writebackConfiguration = $wbc
                        $jbody = ($root | ConvertTo-Json -Depth 10 -Compress).Replace('""', 'null')

                        Update-MgGroup -GroupId $gid -BodyParameter $jbody
                    }
                    else {
                        Update-MgGroup -GroupId $gid -writeBackConfiguration $wbc -ErrorAction Stop
                    }

                    Write-Verbose ("Group Updated!")
                }
                else {

                    Write-Verbose ("No effective updates to group applied!")
                }

            }
        }
    }

    end {
        if ($CriticalError) { return }
    }
}
