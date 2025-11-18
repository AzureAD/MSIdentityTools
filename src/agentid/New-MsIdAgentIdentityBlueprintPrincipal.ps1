<#
.SYNOPSIS
Creates a service principal for the Agent Identity Blueprint

.DESCRIPTION
Creates a service principal for the current Agent Identity Blueprint using the specialized
graph.agentIdentityBlueprintPrincipal endpoint. Uses the stored AgentBlueprintId from
the last New-MsIdAgentIdentityBlueprint call.

.PARAMETER AgentBlueprintId
Optional. The Application ID (AppId) of the Agent Identity Blueprint to create the service principal for.
If not provided, uses the stored ID from the last blueprint creation.

.EXAMPLE
New-MsIdAgentIdentityBlueprint -DisplayName "My Blueprint" -SponsorUserIds @("user1")
New-MsIdAgentIdentityBlueprintPrincipal

.EXAMPLE
New-MsIdAgentIdentityBlueprintPrincipal -AgentBlueprintId "021fe0d0-d128-4769-950c-fcfbf7b87def"

.OUTPUTS
Returns the service principal response object from Microsoft Graph
#>
function New-MsIdAgentIdentityBlueprintPrincipal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$AgentBlueprintId
    )

    # Use provided ID or fall back to stored ID
    if (-not $AgentBlueprintId) {
        if (-not $script:CurrentAgentBlueprintId) {
            throw "No Agent Blueprint ID provided and no stored ID available. Please run New-MsIdAgentIdentityBlueprint first or provide the AgentBlueprintId parameter."
        }
        $AgentBlueprintId = $script:CurrentAgentBlueprintId
        Write-Host "Using stored Agent Blueprint ID: $AgentBlueprintId" -ForegroundColor Yellow
    }
    else {
        Write-Host "Using provided Agent Blueprint ID: $AgentBlueprintId" -ForegroundColor Yellow
    }

    # Ensure we're connected to Microsoft Graph
    $context = Get-MgContext
    if (-not $context) {
        Write-Host "Not connected to Microsoft Graph. Attempting to connect..." -ForegroundColor Yellow
        Connect-MsIdEntraAsUser
    }
    else {
        Write-Host "Connected to Microsoft Graph as: $($context.Account)" -ForegroundColor Green
    }

    try {
        Write-Host "Creating Agent Identity Blueprint Service Principal..." -ForegroundColor Green

        # Prepare the body for the service principal creation
        $body = @{
            appId = $AgentBlueprintId
        }

        # Create the service principal using the specialized endpoint with retry logic
        Write-Host "Making request to create service principal for Agent Blueprint: $AgentBlueprintId" -ForegroundColor Cyan

        $retryCount = 0
        $maxRetries = 10
        $servicePrincipalResponse = $null
        $success = $false

        while ($retryCount -lt $maxRetries -and -not $success) {
            try {
                $servicePrincipalResponse = Invoke-MgRestMethod -Uri "/beta/serviceprincipals/graph.agentIdentityBlueprintPrincipal" -Method POST -Body ($body | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
                $success = $true
            }
            catch {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Write-Host "Waiting for propagation..." -ForegroundColor Yellow
                    Write-Verbose "Attempt $retryCount failed. Waiting 10 seconds before retry..."
                    Start-Sleep -Seconds 10
                }
                else {
                    Write-Error "Failed to create service principal after $maxRetries attempts: $_"
                    throw
                }
            }
        }

        Write-Host "Successfully created Agent Identity Blueprint Service Principal" -ForegroundColor Green
        Write-Host "Service Principal ID: $($servicePrincipalResponse.id)" -ForegroundColor Cyan
        Write-Host "Service Principal App ID: $($servicePrincipalResponse.appId)" -ForegroundColor Cyan

        # Store the service principal ID in module-level variable for use by other functions
        $script:CurrentAgentBlueprintServicePrincipalId = $servicePrincipalResponse.id

        return $servicePrincipalResponse
    }
    catch {
        Write-Error "Failed to create Agent Identity Blueprint Service Principal: $_"
        if ($_.Exception.Response) {
            Write-Host "Response Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
            if ($_.Exception.Response.Content) {
                Write-Host "Response Content: $($_.Exception.Response.Content)" -ForegroundColor Red
            }
        }
        throw
    }
}
