<#
.SYNOPSIS
Connects to Microsoft Graph as a user with required scopes and validates admin privileges

.DESCRIPTION
Establishes a connection to Microsoft Graph with the necessary permissions for Agent Identity operations
and validates that the authenticated user has Global Admin or Global Reader role

.PARAMETER Scopes
Array of scopes to request. Defaults to AgentIdentityBlueprint.Create plus Directory.Read.All for role validation

.EXAMPLE
Connect-MsIdEntraAsUser

.EXAMPLE
Connect-MsIdEntraAsUser -Scopes @('AgentIdentityBlueprint.Create', 'User.ReadWrite.All')
#>
function Connect-MsIdEntraAsUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$Scopes = @('AgentIdentityBlueprint.Create', 'AgentIdentityBlueprintPrincipal.Create', 'AppRoleAssignment.ReadWrite.All', 'Application.ReadWrite.All', 'User.ReadWrite.All', 'AgentIdentityBlueprint.ReadWrite.All', 'AgentIdentityBlueprint.AddRemoveCreds.All')
    )

    # Ensure required modules are available
    if (!(EnsureRequiredModules)) {
        Write-Error "Failed to ensure required modules are available."
        return
    }

    try {
        # Check if we need to disconnect from a different connection type
        if ($script:LastSuccessfulConnection -and $script:LastSuccessfulConnection -ne "EntraAsUser") {
            Write-Host "Disconnecting from previous connection type: $script:LastSuccessfulConnection" -ForegroundColor Yellow
            Disconnect-MgGraph -ErrorAction SilentlyContinue
        }

        Write-Host "Connecting to Microsoft Graph as user..." -ForegroundColor Yellow
        connect-mggraph -contextscope process -scopes $Scopes -NoWelcome

        # Get the tenant ID and current user
        $context = Get-MgContext
        $tenantId = $context.TenantId
        $script:CurrentTenantId = $tenantId
        $script:LastSuccessfulConnection = "EntraAsUser"
        Write-Host "Connected to tenant: $tenantId" -ForegroundColor Green

        return $tenantId
    }
    catch {
        Write-Error "Failed to connect to Microsoft Graph or validate admin privileges: $_"
        throw
    }
}
