<#
.SYNOPSIS
    Gets the group writeback configuration for the group ID
    
.EXAMPLE
    PS > Get-MsIdGroupWritebackConfiguration -GroupId <GroupId>

    Get Group Writeback for Group ID

.EXAMPLE
    PS > Get-MsIdGroupWritebackConfiguration -Group <Group>

    Get Group Writeback for Group


.NOTES
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
function Get-MsIdGroupWritebackConfiguration {
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
        [Object[]] $Group
    )
    
    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        try {
            ## Import Required Modules
            Import-Module Microsoft.Graph.Groups -MinimumVersion 1.10.0 -ErrorAction Stop

            ## Check MgModule Connection
            $MgContext = Get-MgContext
            if ($MgContext) {
                ## Check MgModule Consented Scopes
                $MgPermissions = Find-MgGraphCommand -Command Get-MgGroup -ApiVersion beta | Select-Object -First 1 -ExpandProperty Permissions
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

        if ($null -ne $Group) {
            $GroupId = $group.id
        }

        foreach ($gid in $GroupId) {
            Write-Verbose ("Retrieving Group Writeback Settings for Group ID {0}" -f $gid)
            $checkedGroup = [ordered]@{}
            $mgGroup = $null
            $cloudGroupType = $null


            Write-Verbose ("Retrieving mgGroup for Group ID {0}" -f $gid)
            $mgGroup = Get-MgGroup -GroupId $gid
            Write-Debug ($mgGroup | Select-Object -Property Id, DisplayName, GroupTypes, SecurityEnabled, OnPremisesSyncEnabled -Expand WritebackConfiguration | Select-Object -Property Id, DisplayName, GroupTypes, SecurityEnabled, OnPremisesSyncEnabled, IsEnabled, OnPremisesGroupType | Out-String)

            $checkedGroup.id = $mgGroup.Id
            $checkedGroup.DisplayName = $mgGroup.DisplayName
            $checkedGroup.SourceOfAuthority = if ($mgGroup.OnPremisesSyncEnabled -eq $true) { "On-Premises" }else { "Cloud" }


            if ($mgGroup.GroupTypes -contains 'Unified') {
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

            
            $checkedGroup.Type = $cloudGroupType

            if ($checkedGroup.SourceOfAuthority -eq 'On-Premises') {
                $checkedGroup.WriteBackEnabled = "N/A"
                $checkedGroup.WriteBackOnPremGroupType = "N/A"
                $checkedGroup.EffectiveWriteBack = "On-Premises is Source Of Authority for Group"
            }
            else {
            
                switch ($checkedGroup.Type) {
                    "Distribution" {
                        $checkedGroup.WriteBackEnabled = "N/A"
                        $checkedGroup.WriteBackOnPremGroupType = "N/A"
                        $checkedGroup.EffectiveWriteBack = "Cloud Distribution Groups are not supported for group writeback to on-premises. Use M365 groups instead."

                    }

                    "Mail-Enabled Security" {
                        $checkedGroup.WriteBackEnabled = "N/A"
                        $checkedGroup.WriteBackOnPremGroupType = "N/A"
                        $checkedGroup.EffectiveWriteBack = "Cloud mail-enabled security groups are not supported for group writeback to on-premises. Use M365 groups instead."

                    }
                    Default {
        
                        $writebackEnabled = $null

                        switch ($mgGroup.writebackConfiguration.isEnabled) {
                            $true { $writebackEnabled = "TRUE" }
                            $false { $writebackEnabled = "FALSE" }
                            $null { $writebackEnabled = "NOTSET" }
                        }
            
            
                        if ($null -ne ($mgGroup.writebackConfiguration.onPremisesGroupType)) {
                            $WriteBackOnPremGroupType = $mgGroup.writebackConfiguration.onPremisesGroupType
                        }
                        else {
                            if ($checkedGroup.Type -eq 'M365') {
                                $WriteBackOnPremGroupType = "universalDistributionGroup (M365 DEFAULT)"
                            }
                            else {
                                $WriteBackOnPremGroupType = "universalSecurityGroup (Security DEFAULT)"
                            }
                        }

                        $checkedGroup.WriteBackEnabled = $writebackEnabled
                        $checkedGroup.WriteBackOnPremGroupType = $WriteBackOnPremGroupType

                        if ($checkedGroup.Type -eq 'M365') {
                            if ($checkedGroup.WriteBackEnabled -ne $false) {
                                $checkedGroup.EffectiveWriteBack = ("Cloud M365 group will be writtenback onprem as {0} grouptype" -f $WriteBackOnPremGroupType)
                            }
                            else {
                                $checkedGroup.EffectiveWriteBack = "Cloud M365 group will NOT be writtenback on-premises"
                            }
                        }

                        if ($checkedGroup.Type -eq 'Security') {
                            if ($checkedGroup.WriteBackEnabled -eq $true) {
                                $checkedGroup.EffectiveWriteBack = ("Cloud security group will be writtenback onprem as {0} grouptype" -f $WriteBackOnPremGroupType)
                            }
                            else {
                                $checkedGroup.EffectiveWriteBack = "Cloud security will NOT be writtenback on-premises"
                            }
                        }
                    }
                }
            }
            Write-Output ([pscustomobject]$checkedGroup)

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