<#
.SYNOPSIS
Internal function to get the Microsoft Graph Service Principal ID

.DESCRIPTION
Retrieves the service principal ID (object ID) for Microsoft Graph (app ID 00000003-0000-0000-c000-000000000000)
in the current tenant. Caches the result for subsequent calls to improve performance.

.OUTPUTS
String - The service principal ID (object ID) of Microsoft Graph
#>
function Get-MSGraphServicePrincipalId {
    [CmdletBinding()]
    param()

    # Return cached value if available
    if ($script:MSGraphServicePrincipalId) {
        Write-Verbose "Using cached Microsoft Graph Service Principal ID: $script:MSGraphServicePrincipalId"
        return $script:MSGraphServicePrincipalId
    }

    try {
        Write-Verbose "Retrieving Microsoft Graph Service Principal ID from tenant..."

        # Microsoft Graph App ID is always 00000003-0000-0000-c000-000000000000
        $msGraphAppId = "00000003-0000-0000-c000-000000000000"

        # Get the service principal for Microsoft Graph
        $msGraphServicePrincipalResponse = Invoke-MgGraphRequest -Method GET -Uri "v1.0/servicePrincipals?`$filter=appId eq '$msGraphAppId'&`$select=id,appId,displayName"

        if (-not $msGraphServicePrincipalResponse.value -or $msGraphServicePrincipalResponse.value.Count -eq 0) {
            throw "Microsoft Graph Service Principal not found in tenant"
        }

        $msGraphServicePrincipal = $msGraphServicePrincipalResponse.value[0]

        # Cache the result
        $script:MSGraphServicePrincipalId = $msGraphServicePrincipal.id

        Write-Verbose "Microsoft Graph Service Principal found - ID: $script:MSGraphServicePrincipalId, Display Name: $($msGraphServicePrincipal.displayName)"

        return $script:MSGraphServicePrincipalId
    }
    catch {
        Write-Error "Failed to retrieve Microsoft Graph Service Principal ID: $_"
        throw
    }
}
