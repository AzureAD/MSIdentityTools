<#
.SYNOPSIS
Grants permission to create Agent Users to the Agent Identity Blueprint Principal

.DESCRIPTION
Adds the AgentIdUser.ReadWrite.IdentityParentedBy permission to the Agent Identity Blueprint Service Principal.
This permission allows the blueprint to create agent users that are parented to agent identities.
Uses the stored AgentBlueprintId from the last New-AgentIdentityBlueprint call and the cached Microsoft Graph Service Principal ID.

.PARAMETER AgentBlueprintId
Optional. The ID of the Agent Identity Blueprint Service Principal to grant permissions to.
If not provided, uses the stored ID from the last blueprint creation.

.EXAMPLE
New-MsIdAgentIdentityBlueprint -DisplayName "My Blueprint" -SponsorUserIds @("user1")
New-MsIdAgentIdentityBlueprintPrincipal
Add-MsIdPermissionToCreateAgentUsersToAgentIdentityBlueprintPrincipal

.EXAMPLE
Add-MsIdPermissionToCreateAgentUsersToAgentIdentityBlueprintPrincipal -AgentBlueprintId "7c0c1226-1e81-41a5-ad6c-532c95504443"

.OUTPUTS
Returns the app role assignment response object from Microsoft Graph
#>
function Add-MsIdPermissionToCreateAgentUsersToAgentIdentityBlueprintPrincipal {
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
        Write-Host "Adding permission to create Agent Users to Agent Identity Blueprint Principal..." -ForegroundColor Green

        # Check if we have the service principal ID from New-MsIdAgentIdentityBlueprintPrincipal
        if (-not $script:CurrentAgentBlueprintServicePrincipalId) {
            throw "No Agent Identity Blueprint Service Principal ID available. Please run New-MsIdAgentIdentityBlueprintPrincipal first."
        }

        $servicePrincipalId = $script:CurrentAgentBlueprintServicePrincipalId
        Write-Host "Using stored Agent Identity Blueprint Service Principal ID: $servicePrincipalId" -ForegroundColor Yellow

        # Get the Microsoft Graph Service Principal ID using our internal function
        Write-Host "Retrieving Microsoft Graph Service Principal ID..." -ForegroundColor Cyan
        $msGraphServicePrincipalId = Get-MSGraphServicePrincipalId
        Write-Host "Microsoft Graph Service Principal ID: $msGraphServicePrincipalId" -ForegroundColor Cyan

        # AgentIdUser.ReadWrite.IdentityParentedBy permission ID
        $appRoleId = "4aa6e624-eee0-40ab-bdd8-f9639038a614"
        Write-Host "App Role ID (AgentIdUser.ReadWrite.IdentityParentedBy): $appRoleId" -ForegroundColor Cyan

        # Prepare the body for the app role assignment
        $body = @{
            principalId = $servicePrincipalId
            resourceId = $msGraphServicePrincipalId
            appRoleId = $appRoleId
        }

        Write-Host "Request Details:" -ForegroundColor Cyan
        Write-Host "  Principal ID (Service Principal): $servicePrincipalId" -ForegroundColor White
        Write-Host "  Resource ID (Microsoft Graph): $msGraphServicePrincipalId" -ForegroundColor White
        Write-Host "  App Role ID: $appRoleId (AgentIdUser.ReadWrite.IdentityParentedBy)" -ForegroundColor White

        # Create the app role assignment using the Microsoft Graph REST API
        $apiUrl = "/beta/servicePrincipals/$servicePrincipalId/appRoleAssignments"
        Write-Host "Making request to: $apiUrl" -ForegroundColor Cyan

        $appRoleAssignmentResponse = Invoke-MgRestMethod -Uri $apiUrl -Method POST -Body ($body | ConvertTo-Json) -ContentType "application/json"

        Write-Host "Successfully granted AgentIdUser.ReadWrite.IdentityParentedBy permission" -ForegroundColor Green
        Write-Host "App Role Assignment ID: $($appRoleAssignmentResponse.id)" -ForegroundColor Cyan
        Write-Host "Principal ID: $($appRoleAssignmentResponse.principalId)" -ForegroundColor Cyan
        Write-Host "Resource ID: $($appRoleAssignmentResponse.resourceId)" -ForegroundColor Cyan
        Write-Host "App Role ID: $($appRoleAssignmentResponse.appRoleId)" -ForegroundColor Cyan

        # Add descriptive properties to the response
        $appRoleAssignmentResponse | Add-Member -MemberType NoteProperty -Name "AgentBlueprintId" -Value $AgentBlueprintId -Force
        $appRoleAssignmentResponse | Add-Member -MemberType NoteProperty -Name "AgentBlueprintServicePrincipalId" -Value $servicePrincipalId -Force
        $appRoleAssignmentResponse | Add-Member -MemberType NoteProperty -Name "PermissionName" -Value "AgentIdUser.ReadWrite.IdentityParentedBy" -Force
        $appRoleAssignmentResponse | Add-Member -MemberType NoteProperty -Name "PermissionDescription" -Value "Allows creation of agent users parented to agent identities" -Force
        $appRoleAssignmentResponse | Add-Member -MemberType NoteProperty -Name "MSGraphServicePrincipalId" -Value $msGraphServicePrincipalId -Force

        return $appRoleAssignmentResponse
    }
    catch {
        Write-Error "Failed to add AgentIdUser.ReadWrite.IdentityParentedBy permission to Agent Identity Blueprint Principal: $_"
        if ($_.Exception.Response) {
            Write-Host "Response Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
            if ($_.Exception.Response.Content) {
                Write-Host "Response Content: $($_.Exception.Response.Content)" -ForegroundColor Red
            }
        }
        throw
    }
}
