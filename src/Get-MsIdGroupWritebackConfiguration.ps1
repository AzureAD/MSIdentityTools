<#
.SYNOPSIS
    Gets the group writeback configuration for the group ID
    
.EXAMPLE
    PS > Get-MsIdGroupWritebackConfiguration -GroupId <GroupId>

    Get Group Writeback for Group ID

.EXAMPLE
    PS > Get-MsIdGroupWritebackConfiguration -Group <Group>

    Get Group Writeback for Group

#>
function Get-MsIdGroupWritebackConfiguration {
    [CmdletBinding(DefaultParameterSetName = 'ObjectId')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ObjectId', Position = 0, ValueFromPipeline = $true)]
        [ValidateScript( {
            try {
                [System.Guid]::Parse($_) | Out-Null
                $true
            }
            catch {
                throw "$_ is not a valid ObjectID format. Valid value is a GUID format only."
            }
        })]
        [string[]]
        # Group Object ID
        $GroupId,
        # Group Object
        [Parameter(Mandatory = $true, ParameterSetName = 'GraphGroup', Position = 0, ValueFromPipeline = $true)]
        [psobject[]] $Group
    )
    
    begin {

        if ($null -eq (Get-MgContext)) {
            Write-Error "$(Get-Date -f T) - Please Connect to MS Graph API with the Connect-MgGraph cmdlet from the Microsoft.Graph.Authentication module first before calling functions!" -ErrorAction Stop
        }
        else {
            
            
            if ((Get-MgProfile).Name -ne "beta")
            {
                Write-Error "$(Get-Date -f T) - Please select the beta profile with 'Select-MgProfile -Name beta' to use this cmdlet" -ErrorAction Stop
            }
            
            $GroupsModuleVersion = (get-command -Module Microsoft.Graph.Groups -Name "Get-MGGroup").Version

            if ($GroupsModuleVersion.Major -le "1" -and $GroupsModuleVersion.Minor -lt '10')
            {
                Write-Error ("Microsoft.Graph.Groups Module 1.10 or Greater is not installed!  Pleas Update-Module to the latest version!") -ErrorAction Stop
                
            }

        }
        
    }
    
    process {


        foreach ($gid in $GroupId)
        {
            Write-Verbose ("Retrieving Group Writeback Settings for Group ID {0}" -f $gid)
            $checkedGroup = [ordered]@{}
            $mgGroup = $null
            $mgGroup = Get-MgGroup -GroupId $gid
            $checkedGroup.id = $mgGroup.Id
            $checkedGroup.DisplayName = $mgGroup.DisplayName


            $groupType = ($group.GroupTypes -contains 'Unified') ? 'M365' : 'Security'
            $checkedGroup.Type = $groupType
        
            $writebackEnabled = $null

            switch ($group.writebackConfiguration.isEnabled)
            {
                $true { $writebackEnabled = "TRUE"}
                $false { $writebackEnabled = "FALSE"}
                $null { $writebackEnabled = "NOTSET"}
            }
            
            
            if ($null -ne ($group.writebackConfiguration.onPremisesGroupType))
            {
                $WriteBackOnPremGroupType = $group.writebackConfiguration.onPremisesGroupType
            }
            else {
                if ($checkedGroup.Type -eq 'M365')
                {
                $WriteBackOnPremGroupType = "universalDistributionGroup (M365 DEFAULT)"
                }
                else {
                    $WriteBackOnPremGroupType = "universalSecurityGroup (Security DEFAULT)"
                }
            }

            $checkedGroup.WriteBackEnabled = $writebackEnabled
            $checkedGroup.WriteBackOnPremGroupType = $WriteBackOnPremGroupType

            if ($checkedGroup.Type -eq 'M365')
            {
                if ($checkedGroup.WriteBackEnabled -ne $false)
                {
                    $checkedGroup.EffectiveWriteBack = ("Cloud M365 group will be writtenback onprem as {0} grouptype" -f $WriteBackOnPremGroupType)
                }
                else {
                    $checkedGroup.EffectiveWriteBack = "Cloud M365 group will NOT be writtenback onprem"
                }
            }

            if ($checkedGroup.Type -eq 'Security')
            {
                if ($checkedGroup.WriteBackEnabled -eq $true)
                {
                    $checkedGroup.EffectiveWriteBack = ("Cloud security group will be writtenback onprem as {0} grouptype" -f $WriteBackOnPremGroupType)
                }
                else {
                    $checkedGroup.EffectiveWriteBack = "Cloud security will NOT be writtenback onprem"
                }
            }

            Write-Output ([pscustomobject]$checkedGroup)


        }
    }
    
    
    end {
        
    }
}