<#
.SYNOPSIS
Connects to Microsoft Graph using stored Agent Identity Blueprint credentials

.DESCRIPTION
Internal function that connects to Microsoft Graph using the stored client secret from
Add-MsIdClientSecretToAgentIdentityBlueprint and the stored blueprint ID and tenant ID

.NOTES
This is an internal function that requires:
- $script:CurrentAgentBlueprintId to be set (from New-MsIdAgentIdentityBlueprint)
- $script:LastClientSecret to be set (from Add-MsIdClientSecretToAgentIdentityBlueprint)
- $script:CurrentTenantId to be set (from Connect-MsIdEntraAsUser)
#>
function ConnectAsAgentIdentityBlueprint {
    [CmdletBinding()]
    param()

    # Validate that we have the required stored values
    if (-not $script:CurrentAgentBlueprintId) {
        Write-Error "No Agent Identity Blueprint ID found. Please run New-MsIdAgentIdentityBlueprint first."
        return $false
    }

    if (-not $script:LastClientSecret) {
        Write-Error "No client secret found. Please run Add-MsIdClientSecretToAgentIdentityBlueprint first."
        return $false
    }

    if (-not $script:CurrentTenantId) {
        Write-Error "No tenant ID found. Please run Connect-MsIdEntraAsUser or New-MsIdAgentIdentityBlueprint first."
        return $false
    }

    try {
        # Check if we need to disconnect from a different connection type
        if ($script:LastSuccessfulConnection -and $script:LastSuccessfulConnection -ne "AgentIdentityBlueprint") {
            Write-Host "Disconnecting from previous connection type: $script:LastSuccessfulConnection" -ForegroundColor Yellow
            Disconnect-MgGraph -ErrorAction SilentlyContinue
        }

        Write-Host "Connecting to Microsoft Graph using Agent Identity Blueprint credentials..." -ForegroundColor Yellow

        # Convert the stored client secret to a secure credential
        $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $script:CurrentAgentBlueprintId, $script:LastClientSecret

        # Connect to Microsoft Graph using the blueprint's credentials
        connect-mggraph -tenantId $script:CurrentTenantId -ClientSecretCredential $ClientSecretCredential -ContextScope Process -NoWelcome

        $script:LastSuccessfulConnection = "AgentIdentityBlueprint"
        Write-Host "Successfully connected as Agent Identity Blueprint: $script:CurrentAgentBlueprintId" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to connect to Microsoft Graph using Agent Identity Blueprint credentials: $_"
        return $false
    }
}
