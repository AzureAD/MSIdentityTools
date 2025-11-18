<#
.SYNOPSIS
Adds a client secret to the current Agent Identity Blueprint

.DESCRIPTION
Creates an application password for the most recently created Agent Identity Blueprint using New-MgApplicationPassword.
Uses the stored AgentBlueprintId from the last New-AgentIdentityBlueprint call.

.PARAMETER AgentBlueprintId
Optional. The ID of the Agent Identity Blueprint to add the secret to. If not provided, uses the stored ID from the last blueprint creation.

.EXAMPLE
New-MsIdAgentIdentityBlueprint -DisplayName "My Blueprint" -SponsorUserIds @("user1")
Add-MsIdClientSecretToAgentIdentityBlueprint  # Uses the stored blueprint ID

.EXAMPLE
Add-MsIdClientSecretToAgentIdentityBlueprint -AgentBlueprintId "12345678-1234-1234-1234-123456789012"  # Uses specific ID
#>
function Add-MsIdClientSecretToAgentIdentityBlueprint {
    [CmdletBinding()]
    param (
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
        Write-Host "Adding secret to Agent Blueprint: $AgentBlueprintId" -ForegroundColor Yellow

        # Create the password credential object
        $passwordCredential = @{
            displayName = "1st blueprint secret for dev/test. Not recommended for production use"
            endDateTime = (Get-Date).AddDays(90).ToString("yyyy-MM-ddTHH:mm:ssZ")
        }

        # Add the secret to the application with retry logic
        $retryCount = 0
        $maxRetries = 10
        $secretResult = $null
        $success = $false

        $body = @{
            passwordCredential = $passwordCredential
        }

        while ($retryCount -lt $maxRetries -and -not $success) {
            try {
                $secretResult = Invoke-MgGraphRequest -Method POST -Uri "v1.0/applications/$AgentBlueprintId/addPassword" -Body ($body | ConvertTo-Json -Depth 10) -ErrorAction Stop
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
                    Write-Error "Failed to add secret to Agent Blueprint after $maxRetries attempts: $_"
                    throw
                }
            }
        }

        Write-Host "Successfully added secret to Agent Blueprint" -ForegroundColor Green
        #Write-Host "Secret Value: $($secretResult.SecretText)" -ForegroundColor Red

        # Add additional properties for easy access
        $secretResult | Add-Member -MemberType NoteProperty -Name "Description" -Value "Not recommended for production use" -Force
        $secretResult | Add-Member -MemberType NoteProperty -Name "AgentBlueprintId" -Value $AgentBlueprintId -Force

        # Store the secret in module-level variables for use by other functions
        $script:CurrentAgentBlueprintSecret = $secretResult
        $script:LastClientSecret = ConvertTo-SecureString $secretResult.SecretText -AsPlainText -Force

        return $secretResult
    }
    catch {
        Write-Error "Failed to add secret to Agent Blueprint: $_"
        throw
    }
}
