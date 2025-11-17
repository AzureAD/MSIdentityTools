<#
.SYNOPSIS
Creates a new Agent Identity using an Agent Identity Blueprint

.DESCRIPTION
Creates a new Agent Identity by posting to the Microsoft Graph AgentIdentity endpoint
using the current Agent Identity Blueprint ID and specified sponsors/owners

.PARAMETER DisplayName
The display name for the Agent Identity

.PARAMETER SponsorUserIds
Array of user IDs to set as sponsors

.PARAMETER SponsorGroupIds
Array of group IDs to set as sponsors

.PARAMETER OwnerUserIds
Array of user IDs to set as owners

.NOTES
Requires an Agent Identity Blueprint to be created first (uses stored blueprint ID)
At least one owner or sponsor (user or group) must be specified

.EXAMPLE
New-MsIdAgentIDForAgentIdentityBlueprint -DisplayName "My Agent Identity" -SponsorUserIds @("user1") -OwnerUserIds @("owner1")

.EXAMPLE
New-MsIdAgentIDForAgentIdentityBlueprint  # Will prompt for all required parameters
#>
function New-MsIdAgentIDForAgentIdentityBlueprint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DisplayName,

        [Parameter(Mandatory = $false)]
        [string[]]$SponsorUserIds,

        [Parameter(Mandatory = $false)]
        [string[]]$SponsorGroupIds,

        [Parameter(Mandatory = $false)]
        [string[]]$OwnerUserIds
    )

    # Connect using Agent Identity Blueprint credentials
    if (!(ConnectAsAgentIdentityBlueprint)) {
        Write-Error "Failed to connect using Agent Identity Blueprint credentials. Cannot create Agent Identity."
        return
    }

    # Validate that we have a current Agent Identity Blueprint ID
    if (-not $script:CurrentAgentBlueprintId) {
        Write-Error "No Agent Identity Blueprint ID found. Please run New-MsIdAgentIdentityBlueprint first."
        return
    }

    # Prompt for missing DisplayName if not provided
    if (-not $DisplayName -or $DisplayName.Trim() -eq "") {
        do {
            $DisplayName = Read-Host "Enter the display name for the Agent Identity"
        } while (-not $DisplayName -or $DisplayName.Trim() -eq "")
    }

    # Get sponsors and owners (prompt if not provided)
    $sponsorsAndOwners = Get-SponsorsAndOwners -SponsorUserIds $SponsorUserIds -SponsorGroupIds $SponsorGroupIds -OwnerUserIds $OwnerUserIds
    $SponsorUserIds = $sponsorsAndOwners.SponsorUserIds
    $SponsorGroupIds = $sponsorsAndOwners.SponsorGroupIds
    $OwnerUserIds = $sponsorsAndOwners.OwnerUserIds

    # Build the request body
    $Body = [PSCustomObject]@{
        displayName              = $DisplayName
        AgentIdentityBlueprintId = $script:CurrentAgentBlueprintId
    }

    # Add sponsors if provided
    if ($SponsorUserIds -or $SponsorGroupIds) {
        $sponsorBindings = @()

        if ($SponsorUserIds) {
            foreach ($userId in $SponsorUserIds) {
                $sponsorBindings += "https://graph.microsoft.com/v1.0/users/$userId"
            }
        }

        if ($SponsorGroupIds) {
            foreach ($groupId in $SponsorGroupIds) {
                $sponsorBindings += "https://graph.microsoft.com/v1.0/groups/$groupId"
            }
        }

        $Body | Add-Member -MemberType NoteProperty -Name "sponsors@odata.bind" -Value $sponsorBindings
    }

    # Add owners if provided
    if ($OwnerUserIds) {
        $ownerBindings = @()
        foreach ($userId in $OwnerUserIds) {
            $ownerBindings += "https://graph.microsoft.com/v1.0/users/$userId"
        }
        $Body | Add-Member -MemberType NoteProperty -Name "owners@odata.bind" -Value $ownerBindings
    }

    try {
        Write-Host "Creating Agent Identity '$DisplayName' using blueprint '$script:CurrentAgentBlueprintId'..." -ForegroundColor Yellow

        # Convert the body to JSON
        $JsonBody = $Body | ConvertTo-Json -Depth 5
        Write-Host "Request body:" -ForegroundColor Gray
        Write-Host $JsonBody -ForegroundColor Gray

        # Make the REST API call with retry logic
        $retryCount = 0
        $maxRetries = 10
        $agentIdentity = $null
        $success = $false

        while ($retryCount -lt $maxRetries -and -not $success) {
            try {
                $agentIdentity = Invoke-MgRestMethod -Method POST -Uri "https://graph.microsoft.com/beta/serviceprincipals/Microsoft.Graph.AgentIdentity" -Body $JsonBody -ContentType "application/json" -ErrorAction Stop
                $success = $true
            }
            catch {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Write-Host "Attempt $retryCount failed. Waiting 10 seconds before retry..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 10
                }
                else {
                    Write-Error "Failed to create Agent Identity after $maxRetries attempts: $_"
                    throw
                }
            }
        }

        # Store the Agent Identity ID in module state
        $script:CurrentAgentIdentityId = $agentIdentity.id
        $script:CurrentAgentIdentityAppId = $agentIdentity.appId

        Write-Host "Agent Identity created successfully!" -ForegroundColor Green
        Write-Host "Agent Identity ID: $($agentIdentity.id)" -ForegroundColor Cyan
        Write-Host "Display Name: $($agentIdentity.displayName)" -ForegroundColor Cyan


        return $agentIdentity
    }
    catch {
        Write-Error "Failed to create Agent Identity: $_"
        throw
    }
}
