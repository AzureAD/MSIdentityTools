<#
.SYNOPSIS
Adds an OAuth2 permission scope to the current Agent Identity Blueprint

.DESCRIPTION
Adds a custom OAuth2 permission scope to the Agent Identity Blueprint, allowing applications
to request specific permissions when accessing the agent. Uses the stored AgentBlueprintId
from the last New-MsIdAgentIdentityBlueprint call.

.PARAMETER AgentBlueprintId
Optional. The ID of the Agent Identity Blueprint to add the scope to. If not provided, uses the stored ID from the last blueprint creation.

.PARAMETER AdminConsentDescription
Optional. The description that appears in admin consent experiences. If not provided, will prompt for input.

.PARAMETER AdminConsentDisplayName
Optional. The display name that appears in admin consent experiences. If not provided, will prompt for input.

.PARAMETER Value
Optional. The value of the permission scope (used in token claims). If not provided, will prompt for input.

.EXAMPLE
New-MsIdAgentIdentityBlueprint -DisplayName "My Blueprint" -SponsorUserIds @("user1")
Add-MsIdScopeToAgentIdentityBlueprint  # Will prompt for scope details

.EXAMPLE
Add-MsIdScopeToAgentIdentityBlueprint -AdminConsentDescription "Allow agent access" -AdminConsentDisplayName "Agent Access" -Value "agent_access"
#>
function Add-MsIdScopeToAgentIdentityBlueprint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$AgentBlueprintId,

        [Parameter(Mandatory = $false)]
        [string]$AdminConsentDescription,

        [Parameter(Mandatory = $false)]
        [string]$AdminConsentDisplayName,

        [Parameter(Mandatory = $false)]
        [string]$Value
    )

    # Use stored blueprint ID if not provided
    if (-not $AgentBlueprintId) {
        if (-not $script:CurrentAgentBlueprintId) {
            Write-Error "No Agent Blueprint ID available. Please create a blueprint first using New-MsIdAgentIdentityBlueprint or provide an explicit AgentBlueprintId parameter."
            return
        }
        $AgentBlueprintId = $script:CurrentAgentBlueprintId
        Write-Host "Using stored Agent Blueprint ID: $AgentBlueprintId" -ForegroundColor Gray
    }

    # Prompt for missing parameters
    if (-not $AdminConsentDescription -or $AdminConsentDescription.Trim() -eq "") {
        $defaultDescription = "Access AI as the current user"
        Write-Host "Default: $defaultDescription" -ForegroundColor Gray
        $userInput = Read-Host "Enter the admin consent description for the scope (press Enter for default)"
        if ($userInput -and $userInput.Trim() -ne "") {
            $AdminConsentDescription = $userInput.Trim()
        } else {
            $AdminConsentDescription = $defaultDescription
            Write-Host "Using default: $AdminConsentDescription" -ForegroundColor Cyan
        }
    }

    if (-not $AdminConsentDisplayName -or $AdminConsentDisplayName.Trim() -eq "") {
        $defaultDisplayName = "Access AI as user"
        Write-Host "Default: $defaultDisplayName" -ForegroundColor Gray
        $userInput = Read-Host "Enter the admin consent display name for the scope (press Enter for default)"
        if ($userInput -and $userInput.Trim() -ne "") {
            $AdminConsentDisplayName = $userInput.Trim()
        } else {
            $AdminConsentDisplayName = $defaultDisplayName
            Write-Host "Using default: $AdminConsentDisplayName" -ForegroundColor Cyan
        }
    }

    if (-not $Value -or $Value.Trim() -eq "") {
        $defaultValue = "access_AI_as_user"
        Write-Host "Default: $defaultValue" -ForegroundColor Gray
        $userInput = Read-Host "Enter the scope value (used in token claims, press Enter for default)"
        if ($userInput -and $userInput.Trim() -ne "") {
            $Value = $userInput.Trim()
        } else {
            $Value = $defaultValue
            Write-Host "Using default: $Value" -ForegroundColor Cyan
        }
    }

    # Ensure we're connected to Microsoft Graph
    $context = Get-MgContext
    if (-not $context) {
        Write-Error "Not connected to Microsoft Graph. Please run Connect-MgGraph first."
        return
    }

    try {
        Write-Host "Adding OAuth2 permission scope to Agent Blueprint: $AgentBlueprintId" -ForegroundColor Yellow
        Write-Host "Scope Details:" -ForegroundColor Cyan
        Write-Host "  Description: $AdminConsentDescription" -ForegroundColor White
        Write-Host "  Display Name: $AdminConsentDisplayName" -ForegroundColor White
        Write-Host "  Value: $Value" -ForegroundColor White

        # Generate a new GUID for the scope ID
        $scopeId = [System.Guid]::NewGuid().ToString()

        # Build the request body
        $Body = [PSCustomObject]@{
            identifierUris = @("api://$AgentBlueprintId")
            api = [PSCustomObject]@{
                oauth2PermissionScopes = @(
                    [PSCustomObject]@{
                        adminConsentDescription = $AdminConsentDescription
                        adminConsentDisplayName = $AdminConsentDisplayName
                        id = $scopeId
                        isEnabled = $true
                        type = "User"
                        value = $Value
                    }
                )
            }
        }

        $JsonBody = $Body | ConvertTo-Json -Depth 5
        Write-Debug "Request Body: $JsonBody"

        # Use Invoke-MgRestMethod to update the application
        $scopeResult = Invoke-MgRestMethod -Method PATCH -Uri "https://graph.microsoft.com/v1.0/applications/$AgentBlueprintId" -Body $JsonBody -ContentType "application/json"

        Write-Host "Successfully added OAuth2 permission scope to Agent Blueprint" -ForegroundColor Green
        Write-Host "Scope ID: $scopeId" -ForegroundColor Cyan
        Write-Host "Identifier URI: api://$AgentBlueprintId" -ForegroundColor Cyan

        # Create a result object with scope information
        $result = [PSCustomObject]@{
            ScopeId = $scopeId
            AdminConsentDescription = $AdminConsentDescription
            AdminConsentDisplayName = $AdminConsentDisplayName
            Value = $Value
            IdentifierUri = "api://$AgentBlueprintId"
            AgentBlueprintId = $AgentBlueprintId
            FullScopeReference = "api://$AgentBlueprintId/$Value"
        }

        return $result
    }
    catch {
        Write-Error "Failed to add OAuth2 permission scope to Agent Blueprint: $_"
        throw
    }
}
