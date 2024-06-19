<#
.SYNOPSIS
    Test Mg Graph Module Prerequisites
.EXAMPLE
    PS > Test-MgModulePrerequisites 'CrossTenantInformation.ReadBasic.All'
.INPUTS
    System.String
#>
function Test-MgModulePrerequisites {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        # The name of scope
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [Alias('Permission')]
        [string[]] $Scope
    )

    process {
        ## Initialize
        $result = $true

        ## Check MgModule Connection
        $MgContext = Get-MgContext
        if ($MgContext) {
            if ($Scope) {
                ## Check MgModule Consented Scopes
                [string[]] $ScopesMissing = Compare-Object $Scope -DifferenceObject $MgContext.Scopes | Where-Object SideIndicator -EQ '<=' | Select-Object -ExpandProperty InputObject
                if ($ScopesMissing) {
                    $Exception = New-Object System.Security.SecurityException -ArgumentList "Additional scope(s) needed, call Connect-MgGraph with all of the following scopes: $($ScopesMissing -join ', ')"
                    Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::PermissionDenied) -ErrorId 'MgScopePermissionRequired' -RecommendedAction ("Connect-MgGraph -Scopes $($ScopesMissing -join ',')")
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
