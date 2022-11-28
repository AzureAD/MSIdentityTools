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
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [string[]] $Name,
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
        [array] $MgCommands = Find-MgGraphCommand -Command $Name -ApiVersion $ApiVersion

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
                if (!(Compare-Object $MgCommand.Permissions.Name -DifferenceObject $MgContext.Scopes -ExcludeDifferent -IncludeEqual)) {
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
