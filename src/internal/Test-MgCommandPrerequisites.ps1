<#
.SYNOPSIS
    Test Mg Graph Command Prerequisites
.EXAMPLE
    PS > Test-MgCommandPrerequisites 'Get-MgUser'
.INPUTS
    System.String
#>
function Test-MgCommandPrerequisites {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        # The name of a command.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [Alias('Command')]
        [string[]] $Name,
        # The service API version.
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet('v1.0', 'beta')]
        [string] $ApiVersion = 'v1.0',
        # Specifies a minimum version.
        [Parameter(Mandatory = $false)]
        [version] $MinimumVersion,
        # Require "list" permissions rather than "get" permissions when Get-Mg* commands are specified.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $RequireListPermissions
    )

    begin {
        [array] $MgAuthenticationModule = Get-Module 'Microsoft.Graph.Authentication'
        if (!$MgAuthenticationModule) {
            $MgAuthenticationModule = Import-Module 'Microsoft.Graph.Authentication' -PassThru -Verbose:$false
        }
        [version] $MgAuthenticationModuleVersion = $MgAuthenticationModule[0].Version
        Write-Debug "Microsoft.Graph.Authentication module version loaded: $MgAuthenticationModuleVersion"
    }

    process {
        ## Initialize
        $result = $true

        ## Get Graph Command Details
        [hashtable] $MgCommandLookup = @{}
        foreach ($CommandName in $Name) {
            [array] $MgCommands = Find-MgGraphCommand -Command $CommandName -ApiVersion $ApiVersion

            $MgCommand = $MgCommands[0]
            if ($MgCommands.Count -gt 1) {
                ## Resolve from multiple results
                [array] $MgCommandsWithPermissions = $MgCommands | Where-Object Permissions -NE $null
                [array] $MgCommandsWithListPermissions = $MgCommandsWithPermissions | Where-Object URI -NotLike "*}"
                [array] $MgCommandsWithGetPermissions = $MgCommandsWithPermissions | Where-Object URI -Like "*}"
                if ($MgCommandsWithListPermissions -and $RequireListPermissions) {
                    $MgCommand = $MgCommandsWithListPermissions[0]
                }
                elseif ($MgCommandsWithGetPermissions) {
                    $MgCommand = $MgCommandsWithGetPermissions[0]
                }
                else {
                    $MgCommand = $MgCommands[0]
                }
            }

            $MgCommandLookup[$MgCommand.Command] = $MgCommand
        }

        ## Import Required Modules
        [string[]] $MgModules = @()
        foreach ($MgCommand in $MgCommandLookup.Values) {
            if (!$MgModules.Contains($MgCommand.Module)) {
                $MgModules += $MgCommand.Module
                [string] $ModuleName = "Microsoft.Graph.$($MgCommand.Module)"
                try {
                    if ($MgAuthenticationModuleVersion -lt $MinimumVersion) {
                        ## Check for newer module but load will likely fail due to old Microsoft.Graph.Authentication module
                        try {
                            Import-Module $ModuleName -MinimumVersion $MinimumVersion -ErrorAction Stop -Verbose:$false
                        }
                        catch [System.IO.FileLoadException] {
                            $result = $false
                            Write-Error -Exception $_.Exception -Category ResourceUnavailable -ErrorId 'MgModuleOutOfDate' -Message ("The module '{0}' with minimum version '{1}' was found but currently loaded 'Microsoft.Graph.Authentication' module is version '{2}'. To resolve, try opening a new PowerShell session and running the command again." -f $ModuleName, $MinimumVersion, $MgAuthenticationModuleVersion) -TargetObject $ModuleName -RecommendedAction ("Import-Module {0} -MinimumVersion '{1}'" -f $ModuleName, $MinimumVersion)
                        }
                        catch [System.IO.FileNotFoundException] {
                            $result = $false
                            Write-Error -Exception $_.Exception -Category ResourceUnavailable -ErrorId 'MgModuleWithVersionNotFound' -Message ("The module '{0}' with minimum version '{1}' not found. To resolve, try installing module '{0}' with the latest version. For example: Install-Module {0} -MinimumVersion '{1}'" -f $ModuleName, $MinimumVersion) -TargetObject $ModuleName -RecommendedAction ("Install-Module {0} -MinimumVersion '{1}'" -f $ModuleName, $MinimumVersion)
                        }
                    }
                    else {
                        ## Load module to match currently loaded Microsoft.Graph.Authentication module
                        try {
                            Import-Module $ModuleName -RequiredVersion $MgAuthenticationModuleVersion -ErrorAction Stop -Verbose:$false
                        }
                        catch [System.IO.FileLoadException] {
                            $result = $false
                            Write-Error -Exception $_.Exception -Category ResourceUnavailable -ErrorId 'MgModuleOutOfDate' -Message ("The module '{0}' was found but is not a compatible version. To resolve, try updating module '{0}' to version '{1}' to match currently loaded modules. For example: Update-Module {0} -RequiredVersion '{1}'" -f $ModuleName, $MgAuthenticationModuleVersion) -TargetObject $ModuleName -RecommendedAction ("Update-Module {0} -RequiredVersion '{1}'" -f $ModuleName, $MgAuthenticationModuleVersion)
                        }
                        catch [System.IO.FileNotFoundException] {
                            $result = $false
                            Write-Error -Exception $_.Exception -Category ResourceUnavailable -ErrorId 'MgModuleWithVersionNotFound' -Message ("The module '{0}' with version '{1}' not found. To resolve, try installing module '{0}' with version '{1}' to match currently loaded modules. For example: Install-Module {0} -RequiredVersion '{1}'" -f $ModuleName, $MgAuthenticationModuleVersion) -TargetObject $ModuleName -RecommendedAction ("Install-Module {0} -RequiredVersion '{1}'" -f $ModuleName, $MgAuthenticationModuleVersion)
                        }
                    }
                }
                catch {
                    $result = $false
                    Write-Error -ErrorRecord $_
                }
            }
        }
        Write-Verbose ('Required Microsoft Graph Modules: {0}' -f (($MgModules | ForEach-Object { "Microsoft.Graph.$_" }) -join ', '))
        
        ## Check MgModule Connection
        $MgContext = Get-MgContext
        if ($MgContext) {
            ## Check MgModule Consented Scopes
            foreach ($MgCommand in $MgCommandLookup.Values) {
                if ($MgCommand.Permissions -and !(Compare-Object $MgCommand.Permissions.Name -DifferenceObject $MgContext.Scopes -ExcludeDifferent -IncludeEqual)) {
                    $Exception = New-Object System.Security.SecurityException -ArgumentList "Additional scope needed for command '$($MgCommand.Command)', call Connect-MgGraph with one of the following scopes: $($MgCommand.Permissions.Name -join ', ')"
                    Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::PermissionDenied) -ErrorId 'MgScopePermissionRequired'
                    $result = $false
                }
            }
        }
        else {
            $Exception = New-Object System.Security.Authentication.AuthenticationException -ArgumentList "Authentication needed, call Connect-MgGraph."
            Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::AuthenticationError) -CategoryReason 'AuthenticationException' -ErrorId 'MgAuthenticationRequired'
            $result = $false
        }

        return $result
    }
}
