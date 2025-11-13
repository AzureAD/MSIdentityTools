<#
.SYNOPSIS
Creates a new Agent Identity Blueprint

.DESCRIPTION
Uses Invoke-MgGraphRequest to post a request to create an Agent Identity Blueprint

.PARAMETER DisplayName
The display name for the Agent Identity Blueprint

.PARAMETER SponsorUserIds
Array of user IDs to set as sponsors

.PARAMETER SponsorGroupIds
Array of group IDs to set as sponsors

.PARAMETER OwnerUserIds
Array of user IDs to set as owners

.NOTES
At least one owner or sponsor (user or group) must be specified

.EXAMPLE
New-MsIdAgentIdentityBlueprint -DisplayName "My Blueprint" -SponsorUserIds @("user1") -OwnerUserIds @("owner1")

.EXAMPLE
New-MsIdAgentIdentityBlueprint  # Will prompt for all required parameters
#>
function New-MsIdAgentIdentityBlueprint {
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

    # Ensure required modules are available and connect as admin
    Connect-MsIdEntraAsUser -Scopes @('AgentIdentityBlueprint.Create', 'AgentIdentityBlueprintPrincipal.Create', 'AppRoleAssignment.ReadWrite.All', 'Application.ReadWrite.All', 'User.ReadWrite.All')

    # Prompt for missing DisplayName if not provided
    if (-not $DisplayName -or $DisplayName.Trim() -eq "") {
        do {
            $DisplayName = Read-Host "Enter the display name for the Agent Identity Blueprint"
        } while (-not $DisplayName -or $DisplayName.Trim() -eq "")
    }

    # Get sponsors and owners (prompt if not provided)
    $sponsorsAndOwners = Get-SponsorsAndOwners -SponsorUserIds $SponsorUserIds -SponsorGroupIds $SponsorGroupIds -OwnerUserIds $OwnerUserIds
    $SponsorUserIds = $sponsorsAndOwners.SponsorUserIds
    $SponsorGroupIds = $sponsorsAndOwners.SponsorGroupIds
    $OwnerUserIds = $sponsorsAndOwners.OwnerUserIds

    # Build the request body
    $Body = [PSCustomObject]@{
        displayName = $DisplayName
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

    $JsonBody = $Body | ConvertTo-Json -Depth 5
    Write-Host "Creating Agent Identity Blueprint: $DisplayName" -ForegroundColor Yellow
    Write-Debug "Request Body: $JsonBody"

    try {
        $BlueprintRes = Invoke-MgGraphRequest -Method Post -Uri "https://graph.microsoft.com/beta/applications/graph.agentIdentityBlueprint" -Body $JsonBody

        # Display the full response from the Graph API call
        Write-Host "Graph API Response:" -ForegroundColor Cyan
        $BlueprintRes | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor Gray

        # Extract and store the blueprint ID
        $AgentBlueprintId = $BlueprintRes.id
        Write-Host "Successfully created Agent Identity Blueprint" -ForegroundColor Green
        Write-Host "Agent Blueprint ID: $AgentBlueprintId" -ForegroundColor Cyan

        # Store the ID in module-level variable for use by other functions
        $script:CurrentAgentBlueprintId = $AgentBlueprintId
        $script:CurrentAgentBlueprintAppId = $BlueprintRes.appId

        # Return only the AgentBlueprintId instead of the full response
        return $AgentBlueprintId
    }
    catch {
        Write-Error "Failed to create Agent Identity Blueprint: $_"
        throw
    }
}
