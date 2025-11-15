<#
.SYNOPSIS
Gets an Agent Identity by its ID

.DESCRIPTION
Retrieves an Agent Identity from Microsoft Graph using the provided Agent ID.
Returns the agent identity object if found, or throws an error if not found.

.PARAMETER AgentId
The ID of the Agent Identity to retrieve.

.EXAMPLE
Get-MsIdAgentIdentity -AgentId "27a3cf14-5bdc-4814-bb13-8f1740ca9a4f"

.EXAMPLE
try {
    $agent = Get-MsIdAgentIdentity -AgentId "27a3cf14-5bdc-4814-bb13-8f1740ca9a4f"
    Write-Host "Agent found: $($agent.displayName)"
} catch {
    Write-Host "Agent not found or error occurred: $_"
}
#>
function Get-MsIdAgentIdentity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$AgentId
    )

    # Ensure we're connected to Microsoft Graph
    $context = Get-MgContext
    if (-not $context) {
        Write-Error "Not connected to Microsoft Graph. Please run Connect-MgGraph first."
        return
    }

    try {
        Write-Verbose "Retrieving Agent Identity: $AgentId"
        
        # Call the Graph API to get the agent identity
        $uri = "https://graph.microsoft.com/beta/servicePrincipals/microsoft.graph.agentIdentity/$AgentId"
        $result = Invoke-MgRestMethod -Method GET -Uri $uri -ErrorAction Stop
        
        Write-Verbose "Successfully retrieved Agent Identity"
        return $result
    }
    catch {
        # Check if it's a 404 (not found) error
        if ($_.Exception.Message -like "*404*" -or $_.Exception.Message -like "*NotFound*") {
            Write-Error "Agent Identity with ID '$AgentId' not found."
        }
        else {
            Write-Error "Failed to retrieve Agent Identity: $_"
        }
        throw
    }
}
