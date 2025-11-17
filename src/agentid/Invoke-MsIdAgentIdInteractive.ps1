<#
.SYNOPSIS
Interactive cmdlet to create and configure an Agent ID.

.DESCRIPTION
Demonstrates the full workflow of creating and configuring an Agent Identity Blueprint,
including creating Agent Identities and Agent Users as needed.

This interactive cmdlet guides you through the complete Agent Identity setup process with
prompts at key decision points:

- Blueprint creation with optional sponsors
- Client secret generation for API authentication
- Interactive agent scope configuration
- Inheritable permissions setup
- Service principal creation and permissions
- Admin consent flow (when applicable)
- Agent Identity and Agent User creation

The cmdlet maintains state between operations, automatically passing Blueprint IDs and
other required values to subsequent operations. You can create multiple Agent Identities
and Users in a single session.

.EXAMPLE
Invoke-MsIdAgentIdInteractive

Starts the interactive Agent Identity configuration workflow. The cmdlet will prompt you
for all required inputs and guide you through the complete setup process.

.NOTES
This cmdlet requires the following Microsoft Graph permissions:
- AgentIdentityBlueprint.Create
- AgentIdentityBlueprintPrincipal.Create
- AppRoleAssignment.ReadWrite.All
- Application.ReadWrite.All
- User.ReadWrite.All

The cmdlet will automatically connect to Microsoft Graph with these permissions if not
already connected.

.LINK
https://learn.microsoft.com/entra/identity/app-proxy/overview-what-is-app-proxy
#>

function Invoke-MsIdAgentIdInteractive {
    [CmdletBinding()]
    param()

    # ===================================================================
    # PHASE 1: Create Agent Identity Blueprint
    # ===================================================================

    Write-Host "=== Phase 1: Blueprint Creation ===" -ForegroundColor Magenta

    # Calculate seconds after midnight October 1, 2025 for unique naming
    $october1_2025 = [DateTime]::new(2025, 10, 1, 0, 0, 0)
    $blueprintNumber = [int]((Get-Date) - $october1_2025).TotalSeconds

    Write-Host "Connecting to Microsoft Graph with all the permissions needed to create and manage" -ForegroundColor Yellow
    Write-Host "Agent Identity Blueprints and Agent Users" -ForegroundColor Yellow

    # Ensure required modules are available and connect as admin
    Connect-MsIdEntraAsUser | Out-Null

    $bluePrintDisplayName = Read-Host "Enter a display name for the Agent Identity Blueprint (or press Enter for default)"
    if (-not $bluePrintDisplayName -or $bluePrintDisplayName.Trim() -eq "") {
        $bluePrintDisplayName = "Agent Identity Blueprint Example $blueprintNumber"
        Write-Host "Using default display name: $bluePrintDisplayName" -ForegroundColor Gray
    }

    # Get current user to suggest as sponsor
    try {
        $currentUserUpn = (Get-MgContext).Account
        # Get user's OID directly using their UPN
        $currentUser = Get-MgUser -Filter "userPrincipalName eq '$currentUserUpn'" -Property Id
        $currentUserId = $currentUser.Id
    }
    catch {
        $currentUserUpn = $null
        $currentUserId = $null
    }

    if ($currentUserUpn) {
        $useCurrentUserId = Read-Host "Use current user ($currentUserUpn) as sponsor? (y/n)"
        if ($null -eq $useCurrentUserId -or $useCurrentUserId -eq "y") {
            Write-Host "Using current user as default sponsor: $currentUserUpn" -ForegroundColor Gray
            $SponsorUserIds = @($currentUserId)
            $useSponsor = $true
        } else {
            $useSponsor = $false
        }
    } else {
        $useSponsor = $false
    }

    # Step 1: Create Agent Identity Blueprint with all parameters (no prompting)
    try {
        if ($useSponsor) {
            $blueprint1 = New-MsIdAgentIdentityBlueprint -DisplayName $bluePrintDisplayName -SponsorUserIds $SponsorUserIds
        } else {
            $blueprint1 = New-MsIdAgentIdentityBlueprint -DisplayName $bluePrintDisplayName
        }

        if ($blueprint1) {
            Write-Host "Created Blueprint ID: $blueprint1" -ForegroundColor Green
        } else {
            Write-Error "Failed to create Agent Identity Blueprint - no ID returned"
            return
        }
    }
    catch {
        Write-Error "Failed to create Agent Identity Blueprint: $_"
        return
    }
    Write-Host ""

    # ===================================================================
    # PHASE 2: Configure Blueprint Security and Permissions
    # ===================================================================

    Write-Host "=== Phase 2: Blueprint Configuration ===" -ForegroundColor Magenta

    # Step 2: Add a client secret to the blueprint (uses stored blueprint ID automatically)
    $secret1 = Add-MsIdClientSecretToAgentIdentityBlueprint
    Write-Host "Secret Key ID: $($secret1.KeyId)" -ForegroundColor Yellow
    Write-Host "Secret expires: $($secret1.EndDateTime)" -ForegroundColor Gray
    Write-Host ""

    # ===================================================================
    # PHASE 3: Configure Interactive Agents
    # ===================================================================

    Write-Host "=== Phase 3: Configure Interactive Agents ===" -ForegroundColor Magenta

    # Prompt user if there will be interactive agents
    do {
        $userResponse = Read-Host "Will there be interactive agents? (y/n)"
        $userResponse = $userResponse.Trim().ToLower()
    } while ($userResponse -ne "y" -and $userResponse -ne "n" -and $userResponse -ne "yes" -and $userResponse -ne "no")

    # Store the result for later use
    $hasInteractiveAgents = ($userResponse -eq "y" -or $userResponse -eq "yes")

    if ($hasInteractiveAgents) {
        Write-Host "Configuring scopes for interactive agents..." -ForegroundColor Yellow

        # Step 3: Configure scopes for interactive agent functionality (prompts user for all parameters)
        $interactiveScope = Add-MsIdScopeToAgentIdentityBlueprint
        Write-Host "Configured interactive scope: $($interactiveScope.ScopeId)" -ForegroundColor Cyan
    }
    else {
        Write-Host "Skipping interactive agent scope configuration." -ForegroundColor Gray
        $interactiveScope = $null
    }
    Write-Host ""

    # ===================================================================
    # PHASE 4: Configure Inheritable Permissions
    # ===================================================================

    Write-Host "=== Phase 4: Configure Inheritable Permissions ===" -ForegroundColor Magenta

    # Prompt user if Agent Identity Blueprint will have inheritable permissions
    do {
        $userResponse = Read-Host "Will this Agent Identity Blueprint have inheritable permissions? (y/n)"
        $userResponse = $userResponse.Trim().ToLower()
    } while ($userResponse -ne "y" -and $userResponse -ne "n" -and $userResponse -ne "yes" -and $userResponse -ne "no")

    # Store the result for later use
    $hasInheritablePermissions = ($userResponse -eq "y" -or $userResponse -eq "yes")

    if ($hasInheritablePermissions) {
        Write-Host "Configuring inheritable permissions..." -ForegroundColor Yellow

        # Step 4: Configure inheritable permissions (what permissions agent users will get)
        $inheritablePerms = Add-MsIdInheritablePermissionsToAgentIdentityBlueprint
        Write-Host "Configured inheritable permissions: $($inheritablePerms.InheritableScopes -join ', ')" -ForegroundColor Cyan
    }
    else {
        Write-Host "Skipping inheritable permissions configuration." -ForegroundColor Gray
        $inheritablePerms = $null
    }
    Write-Host ""

    # ===================================================================
    # PHASE 5: Configure Agent ID Users
    # ===================================================================

    Write-Host "=== Phase 5: Configure Agent ID Users ===" -ForegroundColor Magenta

    # Prompt user if Agent Identity Blueprint will have Agent ID users
    do {
        $userResponse = Read-Host "Will this Agent Identity Blueprint have Agent ID users? (y/n)"
        $userResponse = $userResponse.Trim().ToLower()
    } while ($userResponse -ne "y" -and $userResponse -ne "n" -and $userResponse -ne "yes" -and $userResponse -ne "no")

    # Store the result for later use
    $hasAgentIDUsers = ($userResponse -eq "y" -or $userResponse -eq "yes")

    # ===================================================================
    # PHASE 6: Create and Configure Service Principal
    # ===================================================================

    Write-Host "=== Phase 6: Service Principal Setup ===" -ForegroundColor Magenta

    # Step 6: Create the service principal for the blueprint
    $principal1 = New-MsIdAgentIdentityBlueprintPrincipal
    Write-Host "Created Service Principal ID: $($principal1.id)" -ForegroundColor Green

    # Step 7: Grant permission to create agent users (only if user chose to have Agent ID users)
    if ($hasAgentIDUsers) {
        Write-Host "Granting agent user creation permissions..." -ForegroundColor Yellow
        Add-MsIdPermissionToCreateAgentUsersToAgentIdentityBlueprintPrincipal
        Write-Host "Granted AgentIdUser.ReadWrite.IdentityParentedBy permission" -ForegroundColor Green
    }
    else {
        Write-Host "Skipping agent user creation permissions (no Agent ID users requested)." -ForegroundColor Gray
    }

    # Step 8: Configure admin consent for permission inheritance (only if user chose inheritable permissions)
    if ($hasInheritablePermissions) {
        Write-Host "Configuring admin consent for permission inheritance..." -ForegroundColor Yellow
        # This will suggest the scopes from the inheritable permissions configured above
        Write-Host "Opening browser for admin consent flow..." -ForegroundColor Yellow
        Add-MsIdPermissionsToInheritToAgentIdentityBlueprintPrincipal
        Write-Host "Admin consent URL opened in browser" -ForegroundColor Green

        # Pause and wait for user to complete admin consent
        Write-Host "" -ForegroundColor White
        Write-Host "IMPORTANT: Please complete the admin consent process in your browser before continuing." -ForegroundColor Red
        Write-Host "The script will wait for you to grant admin consent..." -ForegroundColor Yellow
        Read-Host "Press Enter to continue after Admin Consent has been granted"
        Write-Host "Continuing with workflow..." -ForegroundColor Green
    }
    else {
        Write-Host "Skipping admin consent configuration (no inheritable permissions configured)." -ForegroundColor Gray
    }
    Write-Host ""

    # ===================================================================
    # PHASE 7: Create Agent Identity and Users
    # ===================================================================

    Write-Host "=== Phase 7: Agent Identity and User Creation ===" -ForegroundColor Magenta

    # Ask user if they want to use example names or provide custom names
    do {
        $namingResponse = Read-Host "Use example names for Agent Identities and Users? (y=use examples like 'Agent Identity Example', n=provide custom names)"
        $namingResponse = $namingResponse.Trim().ToLower()
    } while ($namingResponse -ne "y" -and $namingResponse -ne "n" -and $namingResponse -ne "yes" -and $namingResponse -ne "no")

    $useExampleNames = ($namingResponse -eq "y" -or $namingResponse -eq "yes")

    if ($useExampleNames) {
        Write-Host "Using example naming pattern for Agent Identities and Users" -ForegroundColor Cyan
    } else {
        Write-Host "You will be prompted for custom names for each Agent Identity and User" -ForegroundColor Cyan
    }
    Write-Host ""

    # Initialize arrays to store all created Agent Identities and Users
    $allAgentIdentities = @()
    $allAgentUsers = @()
    # Set agent counter to seconds after midnight October 1, 2025
    $october1_2025 = [DateTime]::new(2025, 10, 1, 0, 0, 0)
    $agentCounter = [int]((Get-Date) - $october1_2025).TotalSeconds
    $continueCreating = $true

    # Loop to create multiple Agent Identities and Users
    while ($continueCreating) {
        Write-Host "--- Creating Agent Identity #$agentCounter ---" -ForegroundColor Yellow

        # Determine the display name for the Agent Identity
        if ($useExampleNames) {
            $agentIdentityDisplayName = "Agent Identity Example $agentCounter"
        } else {
            $agentIdentityDisplayName = Read-Host "Enter display name for this Agent Identity"
            if ([string]::IsNullOrWhiteSpace($agentIdentityDisplayName)) {
                $agentIdentityDisplayName = "Agent Identity $agentCounter"
                Write-Host "Using default: $agentIdentityDisplayName" -ForegroundColor Gray
            }
        }

        # Step 9: Create Agent Identity from the blueprint
        if ($useSponsor) {
            Write-Host "Using current user as sponsor for Agent Identity." -ForegroundColor Gray
            $agentIdentity = New-MsIdAgentIDForAgentIdentityBlueprint -DisplayName $agentIdentityDisplayName `
                -SponsorUserIds $SponsorUserIds
        }
        else {
            Write-Host "No sponsor specified for Agent Identity." -ForegroundColor Gray
            $agentIdentity = New-MsIdAgentIDForAgentIdentityBlueprint -DisplayName $agentIdentityDisplayName
        }
        Write-Host "Created Agent Identity ID: $($agentIdentity.id)" -ForegroundColor Green
        $allAgentIdentities += $agentIdentity

        # Step 10: Create Agent Users for the Agent Identity (only if user chose to have Agent ID users)
        if ($hasAgentIDUsers) {
            # Prompt user if this specific Agent ID requires an Agent ID user
            do {
                $userResponse = Read-Host "Does this Agent ID (#$agentCounter) require an Agent ID user? (y/n)"
                $userResponse = $userResponse.Trim().ToLower()
            } while ($userResponse -ne "y" -and $userResponse -ne "n" -and $userResponse -ne "yes" -and $userResponse -ne "no")

            # Store the result for this specific Agent ID
            $agentIDNeedsUser = ($userResponse -eq "y" -or $userResponse -eq "yes")

            if ($agentIDNeedsUser) {
                Write-Host "Creating Agent Users as requested..." -ForegroundColor Yellow
                # Get current tenant's domain for UPN
                $tenantDomain = (Get-MgOrganization).VerifiedDomains | Where-Object { $_.IsDefault -eq $true } | Select-Object -First 1 -ExpandProperty Name
                
                # Determine names for the Agent User
                if ($useExampleNames) {
                    $agentUserDisplayName = "Agent User Example $agentCounter"
                    $agentUserUpn = "AgentUser$agentCounter@$tenantDomain"
                } else {
                    $agentUserDisplayName = Read-Host "Enter display name for this Agent User"
                    if ([string]::IsNullOrWhiteSpace($agentUserDisplayName)) {
                        $agentUserDisplayName = "Agent User $agentCounter"
                        Write-Host "Using default: $agentUserDisplayName" -ForegroundColor Gray
                    }
                    
                    $agentUserUpnPrefix = Read-Host "Enter UPN prefix for this Agent User (will be @$tenantDomain)"
                    if ([string]::IsNullOrWhiteSpace($agentUserUpnPrefix)) {
                        $agentUserUpnPrefix = "AgentUser$agentCounter"
                        Write-Host "Using default prefix: $agentUserUpnPrefix" -ForegroundColor Gray
                    }
                    $agentUserUpn = "$agentUserUpnPrefix@$tenantDomain"
                }
                
                $agentUser = New-MsIdAgentIDUserForAgentId -DisplayName $agentUserDisplayName `
                    -UserPrincipalName $agentUserUpn
                Write-Host "Created Agent User ID: $($agentUser.id)" -ForegroundColor Green
                Write-Host "Agent User UPN: $($agentUser.userPrincipalName)" -ForegroundColor Cyan
                $allAgentUsers += $agentUser
            }
            else {
                Write-Host "Skipping Agent User creation for this Agent ID (not required)." -ForegroundColor Gray
                $agentUser = $null
            }
        }
        else {
            Write-Host "Skipping Agent User creation (Agent ID users not configured in Phase 4)." -ForegroundColor Gray
            $agentUser = $null
            $agentIDNeedsUser = $false
        }

        # Ask user if they want to create another Agent Identity
        do {
            $continueResponse = Read-Host "Do you want to create another Agent Identity? (y/n)"
            $continueResponse = $continueResponse.Trim().ToLower()
        } while ($continueResponse -ne "y" -and $continueResponse -ne "n" -and $continueResponse -ne "yes" -and $continueResponse -ne "no")

        $continueCreating = ($continueResponse -eq "y" -or $continueResponse -eq "yes")
        $agentCounter++
        Write-Host ""
    }

    Write-Host "=== Agent Identity and User Creation Summary ===" -ForegroundColor Cyan
    Write-Host "Total Agent Identities created: $($allAgentIdentities.Count)" -ForegroundColor White
    Write-Host "Total Agent Users created: $($allAgentUsers.Count)" -ForegroundColor White

    # Store the last created items for compatibility with existing summary code
    $agentIdentity = if ($allAgentIdentities.Count -gt 0) { $allAgentIdentities[-1] } else { $null }
    $agentUser = if ($allAgentUsers.Count -gt 0) { $allAgentUsers[-1] } else { $null }
    Write-Host ""

    # ===================================================================
    # SUMMARY AND MODULE STATUS
    # ===================================================================

    Write-Host "=== Complete Workflow Summary ===" -ForegroundColor Green
    Write-Host "✓ 1. Agent Identity Blueprint created and configured" -ForegroundColor Green
    Write-Host "✓ 2. Client secret added for API authentication" -ForegroundColor Green

    if ($hasInteractiveAgents) {
        Write-Host "✓ 3. Interactive agent scopes configured with user prompts" -ForegroundColor Green
    }
    else {
        Write-Host "- 3. Interactive agent scopes (skipped by user choice)" -ForegroundColor Gray
    }

    if ($hasInheritablePermissions) {
        Write-Host "✓ 4. Inheritable permissions configured for agent users" -ForegroundColor Green
    }
    else {
        Write-Host "- 4. Inheritable permissions (skipped by user choice)" -ForegroundColor Gray
    }

    Write-Host "✓ 5. Service Principal created with proper permissions" -ForegroundColor Green

    if ($hasAgentIDUsers) {
        Write-Host "✓ 6. Agent user creation permissions granted" -ForegroundColor Green
    }
    else {
        Write-Host "- 6. Agent user creation permissions (skipped - no Agent ID users)" -ForegroundColor Gray
    }

    if ($hasInheritablePermissions) {
        Write-Host "✓ 7. Admin consent flow configured (commented out)" -ForegroundColor Green
    }
    else {
        Write-Host "- 7. Admin consent flow (skipped - no inheritable permissions)" -ForegroundColor Gray
    }

    if ($allAgentIdentities.Count -gt 0) {
        Write-Host "✓ 8-9. Agent Identity and User Creation Loop completed" -ForegroundColor Green
        Write-Host "    - Created $($allAgentIdentities.Count) Agent $(if ($allAgentIdentities.Count -eq 1) { 'Identity' } else { 'Identities' })" -ForegroundColor Green
        if ($hasAgentIDUsers) {
            Write-Host "    - Created $($allAgentUsers.Count) Agent $(if ($allAgentUsers.Count -eq 1) { 'User' } else { 'Users' })" -ForegroundColor Green
        }
        else {
            Write-Host "    - No Agent Users created (not configured in Phase 5)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "- 8-9. Agent Identity and User creation (not completed)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "Module state:" -ForegroundColor Yellow
    Write-Host "Current Blueprint ID: $blueprint1" -ForegroundColor White
    Write-Host "Current Blueprint App ID: $($script:CurrentAgentBlueprintAppId)" -ForegroundColor White
    Write-Host "Current Service Principal ID: $($principal1.id)" -ForegroundColor White
    Write-Host "Total Agent Identities created: $($allAgentIdentities.Count)" -ForegroundColor White
    Write-Host "Total Agent Users created: $($allAgentUsers.Count)" -ForegroundColor White
    Write-Host "Last Agent Identity ID: $(if ($agentIdentity) { $agentIdentity.id } else { 'None created' })" -ForegroundColor White
    Write-Host "Last Agent User ID: $(if ($agentUser) { $agentUser.id } else { 'None created' })" -ForegroundColor White
    Write-Host "Secret stored: $(if ($secret1) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "Has inheritable permissions: $(if ($hasInheritablePermissions) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "Has Agent ID users: $(if ($hasAgentIDUsers) { 'Yes' } else { 'No' })" -ForegroundColor White

    # Show all created Agent Identity IDs if any exist
    if ($allAgentIdentities.Count -gt 0) {
        Write-Host "" -ForegroundColor White
        Write-Host "All created Agent Identity IDs:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $allAgentIdentities.Count; $i++) {
            Write-Host "  $($i + 1). $($allAgentIdentities[$i].id)" -ForegroundColor White
        }
    }

    # Show all created Agent User IDs if any exist
    if ($allAgentUsers.Count -gt 0) {
        Write-Host "" -ForegroundColor White
        Write-Host "All created Agent User IDs:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $allAgentUsers.Count; $i++) {
            Write-Host "  $($i + 1). $($allAgentUsers[$i].id) ($($allAgentUsers[$i].userPrincipalName))" -ForegroundColor White
        }
    }
}
