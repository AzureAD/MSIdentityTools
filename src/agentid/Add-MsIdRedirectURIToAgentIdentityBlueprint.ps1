<#
.SYNOPSIS
Adds a web redirect URI to the current Agent Identity Blueprint

.DESCRIPTION
Configures a web redirect URI for the Agent Identity Blueprint application registration.
This allows the application to receive authorization callbacks at the specified URI.
Uses the stored AgentBlueprintId from the last New-AgentIdentityBlueprint call.

.PARAMETER RedirectUri
Optional. The redirect URI to add. Defaults to "http://localhost".

.PARAMETER AgentBlueprintId
Optional. The ID of the Agent Identity Blueprint to configure. If not provided, uses the stored ID from the last blueprint creation.

.EXAMPLE
New-MsIdAgentIdentityBlueprint -DisplayName "My Blueprint" -SponsorUserIds @("user1")
Add-MsIdRedirectURIToAgentIdentityBlueprint  # Uses default "http://localhost"

.EXAMPLE
Add-MsIdRedirectURIToAgentIdentityBlueprint -RedirectUri "http://localhost:3000"

.EXAMPLE
Add-MsIdRedirectURIToAgentIdentityBlueprint -RedirectUri "https://myapp.com/callback" -AgentBlueprintId "12345678-1234-1234-1234-123456789012"
#>
function Add-MsIdRedirectURIToAgentIdentityBlueprint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RedirectUri = "http://localhost",

        [Parameter(Mandatory = $false)]
        [string]$AgentBlueprintId
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

    # Ensure we're connected to Microsoft Graph
    $context = Get-MgContext
    if (-not $context) {
        Write-Error "Not connected to Microsoft Graph. Please run Connect-MgGraph first."
        return
    }

    try {
        Write-Host "Adding web redirect URI to Agent Identity Blueprint..." -ForegroundColor Yellow
        Write-Host "Agent Blueprint ID: $AgentBlueprintId" -ForegroundColor Gray
        Write-Host "Redirect URI: $RedirectUri" -ForegroundColor Cyan

        # First, get the current application configuration to preserve existing redirect URIs
        Write-Host "Retrieving current application configuration..." -ForegroundColor Yellow
        $currentApp = Invoke-MgRestMethod -Method GET -Uri "https://graph.microsoft.com/v1.0/applications/$AgentBlueprintId" -ContentType "application/json"

        # Get existing redirect URIs or initialize empty array
        $existingRedirectUris = @()
        if ($currentApp.web -and $currentApp.web.redirectUris) {
            $existingRedirectUris = $currentApp.web.redirectUris
        }

        # Check if the redirect URI already exists
        if ($existingRedirectUris -contains $RedirectUri) {
            Write-Host "Redirect URI '$RedirectUri' already exists in the application" -ForegroundColor Yellow

            $result = [PSCustomObject]@{
                AgentBlueprintId = $AgentBlueprintId
                RedirectUri = $RedirectUri
                Action = "Already Exists"
                AllRedirectUris = $existingRedirectUris
                ConfiguredAt = Get-Date
            }

            return $result
        }

        # Add the new redirect URI to the existing ones
        $updatedRedirectUris = $existingRedirectUris + $RedirectUri

        # Build the request body to update the web redirect URIs
        $Body = [PSCustomObject]@{
            web = [PSCustomObject]@{
                redirectUris = $updatedRedirectUris
            }
        }

        $JsonBody = $Body | ConvertTo-Json -Depth 5
        Write-Debug "Request Body: $JsonBody"

        # Use Invoke-MgRestMethod to update the application
        $updateResult = Invoke-MgRestMethod -Method PATCH -Uri "https://graph.microsoft.com/v1.0/applications/$AgentBlueprintId" -Body $JsonBody -ContentType "application/json"

        Write-Host "Successfully added web redirect URI to Agent Identity Blueprint" -ForegroundColor Green
        Write-Host "Total redirect URIs: $($updatedRedirectUris.Count)" -ForegroundColor Cyan

        # Create a result object with redirect URI information
        $result = [PSCustomObject]@{
            AgentBlueprintId = $AgentBlueprintId
            RedirectUri = $RedirectUri
            Action = "Added"
            AllRedirectUris = $updatedRedirectUris
            ConfiguredAt = Get-Date
            ApiResponse = $updateResult
        }

        return $result
    }
    catch {
        Write-Error "Failed to add redirect URI to Agent Identity Blueprint: $_"
        if ($_.Exception.Response) {
            Write-Host "Response Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
            if ($_.Exception.Response.Content) {
                Write-Host "Response Content: $($_.Exception.Response.Content)" -ForegroundColor Red
            }
        }
        throw
    }
}
