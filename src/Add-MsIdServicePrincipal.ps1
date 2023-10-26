<#
.SYNOPSIS
    Create service principal for existing application registration

.EXAMPLE
    PS > Add-MsIdServicePrincipal 10000000-0000-0000-0000-000000000001

    Create service principal for existing appId, 10000000-0000-0000-0000-000000000001.

.INPUTS
    System.String

#>
function Add-MsIdServicePrincipal {
    [CmdletBinding()]
    [OutputType([object])]
    param (
        # AppID of Application
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [string[]] $AppId
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'New-MgServicePrincipal' -MinimumVersion 2.8.0 -ErrorVariable CriticalError)) { return }
    }

    process {
        if ($CriticalError) { return }

        foreach ($_AppId in $AppId) {
            ## Create Service Principal from Application Registration
            New-MgServicePrincipal -AppId $_AppId
        }
    }
}
