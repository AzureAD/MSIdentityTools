<#
.SYNOPSIS
    Test Mg Command Availability
.EXAMPLE
    PS C:\>Test-MgCommand 'Get-MgUser'
.INPUTS
    System.String
#>
function Test-MgCommand {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        # The name of a command.
        [Parameter(Mandatory = $true, Position = 1)]
        [string[]] $CommandName,
        # The service API version.
        [Parameter(Mandatory = $false)]
        [ValidateSet('v1.0', 'beta')]
        [string] $ApiVersion = 'v1.0',
        # Specifies a minimum version.
        [Parameter(Mandatory = $false)]
        [version] $MinimumVersion
    )

    process {
        ## Initialize
        $result = $true

        ## Get Graph Command Details
        [array] $MgCommands = Find-MgGraphCommand -Command $CommandName -ApiVersion $ApiVersion

        ## Remove duplicate commands
        [hashtable] $MgCommandLookup = @{}
        foreach ($MgCommand in $MgCommands) {
            $MgCommandLookup[$MgCommand.Command] = $MgCommand
        }

        ## Import Required Modules
        foreach ($MgCommand in $MgCommandLookup.Values) {
            try {
                Import-Module "Microsoft.Graph.$($MgCommand.Module)" -MinimumVersion $MinimumVersion -ErrorAction Stop
            }
            catch {
                Write-Error -ErrorRecord $_
                $result = $false
            }
        }
        
        ## Check MgModule Connection
        $MgContext = Get-MgContext
        if ($MgContext) {
            ## Check MgModule Consented Scopes
            foreach ($MgCommand in $MgCommandLookup.Values) {
                if (!(Compare-Object $MgCommand.Permissions.Name -DifferenceObject $MgContext.Scopes -ExcludeDifferent)) {
                    Write-Error "Additional scope needed for command '$($MgCommand.Command)', call Connect-MgGraph with one of the following scopes: $($MgCommand.Permissions.Name -join ', ')"
                    $result = $false
                }
            }
        }
        else {
            Write-Error "Authentication needed, call Connect-MgGraph."
            $result = $false
        }

        return $result
    }
}
