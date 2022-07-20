<#
.SYNOPSIS
    Lookup Service Principal by AppId
    
.EXAMPLE
    PS > Get-MsIdServicePrincipalIdByAppId 10000000-0000-0000-0000-000000000001

    Return the service principal id matching appId, 10000000-0000-0000-0000-000000000001.

.INPUTS
    System.String

#>
function Get-MsIdServicePrincipalIdByAppId {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # AppID of the Service Principal
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [string] $AppId
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        try {
            Import-Module Microsoft.Graph.Applications -MinimumVersion 1.9.2 -ErrorAction Stop
        }
        catch { Write-Error -ErrorRecord $_ -ErrorVariable CriticalError; return }
    }

    process {
        if ($CriticalError) { return }

        ## Filter service principals by appId and return id
        Get-MgServicePrincipal -Filter "appId eq '$AppId'" -Select id | Select-Object -ExpandProperty id
    }
}
