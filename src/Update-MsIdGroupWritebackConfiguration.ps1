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
#>
function Update-MsIdGroupWritebackConfiguration {
    [CmdletBinding(DefaultParameterSetName = 'ObjectId')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ObjectId', Position = 0, ValueFromPipeline = $true)]
        [string[]]
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
        #Group Object ID
        $GroupId,
        [bool]
        $WriteBackEnabled,
        [ValidateSet("universalDistributionGroup", "universalSecurityGroup", "universalMailEnabledSecurityGroup")]
        [string]
        $WriteBackOnPremGroupType
    )
    
    begin {

        if ($null -eq (Get-MgContext)) {
            Write-Error "$(Get-Date -f T) - Please Connect to MS Graph API with the Connect-MgGraph cmdlet from the Microsoft.Graph.Authentication module first before calling functions!" -ErrorAction Stop
        }
        else {
            
            if (((Get-MgContext).Scopes -notcontains "Directory.ReadWrite.All") -and ((Get-MgContext).Scopes -notcontains "Group.ReadWrite.All"))
            {
                Write-Error "$(Get-Date -f T) - Please Connect to MS Graph API with the 'Connect-MgGraph -Scopes Group.ReadWrite.All' to include the Group.ReadWrite.All scope to update groups from MS Graph API." -ErrorAction Stop
            }
            
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

            $group = Get-MgGroup -GroupId $gid

            if ($group.GroupTypes -notcontains 'Unified')
            {
                if ($WriteBackOnPremGroupType -ne 'universalSecurityGroup')
                {
                    write-error ("{0} is not an M365 Group and can only be written back as a univeralSecurityGroup type!" -f $gid) -ErrorAction Stop
                }
            }


            $wbc = @{}
            $wbc.isEnabled = $WriteBackEnabled
            $wbc.onPremisesGroupType = $WriteBackOnPremGroupType
            Write-Verbose ("Updating Group {0} with Group Writeback settings of Writebackenabled={1} and onPremisesGroupType={2}" -f $gid,$WriteBackEnabled,$WriteBackOnPremGroupType )
            Update-MgGroup -GroupId $gid -writeBackConfiguration $wbc
            Write-Verbose ("Group Updated!")
    }
}
    
    end {
        
    }
}