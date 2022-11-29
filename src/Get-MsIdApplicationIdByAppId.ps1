<#
.SYNOPSIS
    Lookup Application Registration by AppId
    
.EXAMPLE
    PS > Get-MsIdApplicationIdByAppId 10000000-0000-0000-0000-000000000001

    Return the application registration id matching appId, 10000000-0000-0000-0000-000000000001.

.INPUTS
    System.String

#>
function Get-MsIdApplicationIdByAppId {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # AppID of the Application Registration
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [string[]] $AppId
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'Get-MgApplication' -MinimumVersion 1.9.2 -ErrorVariable CriticalError)) { return }
    }

    process {
        if ($CriticalError) { return }

        foreach ($_AppId in $AppId) {
            ## Filter application registration by appId and return id
            Get-MgApplication -Filter "appId eq '$_AppId'" -Select id | Select-Object -ExpandProperty id
        }
    }
}
