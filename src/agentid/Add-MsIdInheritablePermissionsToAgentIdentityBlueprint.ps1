<#
.SYNOPSIS
Adds inheritable permissions to Agent Identity Blueprints

.DESCRIPTION
Configures inheritable Microsoft Graph permissions that can be granted to Agent Identity Blueprints.
This allows agents created from the blueprint to inherit specific Microsoft Graph permissions.

.PARAMETER Scopes
Optional. Array of Microsoft Graph permission scopes to make inheritable. If not provided, will prompt for input.
Common scopes include: User.Read, Mail.Read, Calendars.Read, etc.

.PARAMETER ResourceAppId
Optional. The resource application ID. Defaults to Microsoft Graph (00000003-0000-0000-c000-000000000000).

.EXAMPLE
Add-MsIdInheritablePermissionsToAgentIdentityBlueprint  # Will prompt for scopes

.EXAMPLE
Add-MsIdInheritablePermissionsToAgentIdentityBlueprint -Scopes @("User.Read", "Mail.Read", "Calendars.Read")

.EXAMPLE
Add-MsIdInheritablePermissionsToAgentIdentityBlueprint -Scopes @("User.Read") -ResourceAppId "00000003-0000-0000-c000-000000000000"
#>
function Add-MsIdInheritablePermissionsToAgentIdentityBlueprint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$Scopes,

        [Parameter(Mandatory = $false)]
        [string]$ResourceAppId = "00000003-0000-0000-c000-000000000000"
    )

    # Prompt for ResourceAppId if not provided
    if (-not $ResourceAppId -or $ResourceAppId.Trim() -eq "") {
        Write-Host "Enter the Resource Application ID for the permissions." -ForegroundColor Yellow
        Write-Host "Default: 00000003-0000-0000-c000-000000000000 (Microsoft Graph)" -ForegroundColor Gray

        $resourceInput = Read-Host "Resource App ID (press Enter for Microsoft Graph default)"
        if ($resourceInput -and $resourceInput.Trim() -ne "") {
            $ResourceAppId = $resourceInput.Trim()
        } else {
            $ResourceAppId = "00000003-0000-0000-c000-000000000000"
            Write-Host "Using default: Microsoft Graph" -ForegroundColor Cyan
        }
    }

    # Determine resource name for display
    $resourceName = switch ($ResourceAppId) {
        "00000003-0000-0000-c000-000000000000" { "Microsoft Graph" }
        "00000002-0000-0000-c000-000000000000" { "Azure Active Directory Graph" }
        default { "Custom Resource ($ResourceAppId)" }
    }

    # Prompt for scopes if not provided
    if (-not $Scopes -or $Scopes.Count -eq 0) {
        Write-Host "Enter permission scopes to make inheritable for $resourceName." -ForegroundColor Yellow
        if ($ResourceAppId -eq "00000003-0000-0000-c000-000000000000") {
            Write-Host "Common Microsoft Graph scopes: User.Read, Mail.Read, Calendars.Read, Files.Read, etc." -ForegroundColor Gray
        }
        Write-Host "Enter multiple scopes separated by commas." -ForegroundColor Gray

        do {
            $scopeInput = Read-Host "Enter permission scopes (comma-separated)"
            if ($scopeInput -and $scopeInput.Trim() -ne "") {
                $Scopes = $scopeInput.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
            }
        } while (-not $Scopes -or $Scopes.Count -eq 0)
    }

    # Check if we have a stored Agent Blueprint ID
    if (-not $script:CurrentAgentBlueprintId) {
        Write-Error "No Agent Blueprint ID available. Please create a blueprint first using New-MsIdAgentIdentityBlueprint."
        return
    }

    # Ensure we're connected to Microsoft Graph
    $context = Get-MgContext
    if (-not $context) {
        Write-Error "Not connected to Microsoft Graph. Please run Connect-MgGraph first."
        return
    }

    try {
        Write-Host "Adding inheritable permissions to Agent Identity Blueprint..." -ForegroundColor Yellow
        Write-Host "Agent Blueprint ID: $($script:CurrentAgentBlueprintId)" -ForegroundColor Gray
        Write-Host "Resource App ID: $ResourceAppId ($resourceName)" -ForegroundColor Cyan
        Write-Host "Scopes to make inheritable:" -ForegroundColor Cyan
        foreach ($scope in $Scopes) {
            Write-Host "  - $scope" -ForegroundColor White
        }

        # Build the request body
        $Body = [PSCustomObject]@{
            resourceAppId = $ResourceAppId
            inheritableScopes = [PSCustomObject]@{
                "@odata.type" = "microsoft.graph.enumeratedScopes"
                scopes = $Scopes
            }
        }

        $JsonBody = $Body | ConvertTo-Json -Depth 5
        Write-Debug "Request Body: $JsonBody"

        # Use Invoke-MgRestMethod to make the API call with the stored Agent Blueprint ID with retry logic
        $apiUrl = "https://graph.microsoft.com/beta/applications/microsoft.graph.agentIdentityBlueprint/$($script:CurrentAgentBlueprintId)/inheritablePermissions"
        Write-Debug "API URL: $apiUrl"
        
        $retryCount = 0
        $maxRetries = 10
        $result = $null
        $success = $false

        while ($retryCount -lt $maxRetries -and -not $success) {
            try {
                $result = Invoke-MgRestMethod -Method POST -Uri $apiUrl -Body $JsonBody -ContentType "application/json" -ErrorAction Stop
                $success = $true
            }
            catch {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Write-Host "Attempt $retryCount failed. Waiting 10 seconds before retry..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 10
                }
                else {
                    Write-Error "Failed to add inheritable permissions after $maxRetries attempts: $_"
                    throw
                }
            }
        }

        Write-Host "Successfully added inheritable permissions to Agent Identity Blueprints" -ForegroundColor Green
        Write-Host "Permissions are now available for inheritance by agent blueprints" -ForegroundColor Green

        # Store the scopes for use in other functions
        $script:LastConfiguredInheritableScopes = $Scopes

        # Create a result object with permission information
        $permissionResult = [PSCustomObject]@{
            AgentBlueprintId = $script:CurrentAgentBlueprintId
            ResourceAppId = $ResourceAppId
            ResourceAppName = $resourceName
            InheritableScopes = $Scopes
            ScopeCount = $Scopes.Count
            ConfiguredAt = Get-Date
            ApiResponse = $result
        }

        return $permissionResult
    }
    catch {
        Write-Error "Failed to add inheritable permissions: $_"
        if ($_.Exception.Response) {
            Write-Host "Response Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
            if ($_.Exception.Response.Content) {
                Write-Host "Response Content: $($_.Exception.Response.Content)" -ForegroundColor Red
            }
        }
        throw
    }
}
