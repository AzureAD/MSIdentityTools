<#
.SYNOPSIS
Opens admin consent page in browser for Agent Identity Blueprint Principal to inherit permissions

.DESCRIPTION
Launches the system browser with the admin consent URL for the Agent Identity Blueprint Principal.
This allows the administrator to grant permissions that the blueprint can inherit and use.
Uses the stored AgentBlueprintId from the last New-AgentIdentityBlueprint call.

.PARAMETER AgentBlueprintId
Optional. The Application ID (AppId) of the Agent Identity Blueprint to grant consent for.
If not provided, uses the stored ID from the last blueprint creation.

.PARAMETER Scope
Optional. The permission scopes to request consent for. Defaults to "user.read mail.read".
Use space-separated scope names (e.g., "user.read mail.read calendars.read").

.PARAMETER RedirectUri
Optional. The redirect URI after consent. Defaults to "https://entra.microsoft.com/TokenAuthorize".

.PARAMETER State
Optional. State parameter for the consent request. Defaults to a random value.

.EXAMPLE
New-MsIdAgentIdentityBlueprint -DisplayName "My Blueprint" -SponsorUserIds @("user1")
Add-MsIdPermissionsToInheritToAgentIdentityBlueprintPrincipal

.EXAMPLE
Add-MsIdPermissionsToInheritToAgentIdentityBlueprintPrincipal -Scope "user.read mail.read calendars.read"

.EXAMPLE
Add-MsIdPermissionsToInheritToAgentIdentityBlueprintPrincipal -AgentBlueprintId "7c0c1226-1e81-41a5-ad6c-532c95504443" -Scope "user.read"

.OUTPUTS
Returns an object with the consent URL and parameters used
#>
function Add-MsIdPermissionsToInheritToAgentIdentityBlueprintPrincipal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$AgentBlueprintId,

        [Parameter(Mandatory=$false)]
        [string]$Scope = "user.read mail.read",

        [Parameter(Mandatory=$false)]
        [string]$RedirectUri = "https://entra.microsoft.com/TokenAuthorize",

        [Parameter(Mandatory=$false)]
        [string]$State
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

    # Prompt for scopes if not provided or if using defaults
    if (-not $Scope -or $Scope.Trim() -eq "" -or $Scope -eq "user.read mail.read") {
        $suggestedScope = "user.read mail.read"  # Default fallback

        # Use previously configured inheritable scopes as suggestion if available
        if ($script:LastConfiguredInheritableScopes -and $script:LastConfiguredInheritableScopes.Count -gt 0) {
            # Convert array to space-separated string and make lowercase for consistency
            $suggestedScope = ($script:LastConfiguredInheritableScopes | ForEach-Object { $_.ToLower() }) -join " "
            Write-Host "Found previously configured inheritable scopes from Add-MsIdInheritablePermissionsToAgentIdentityBlueprint" -ForegroundColor Green
        }

        Write-Host "Enter permission scopes for admin consent." -ForegroundColor Yellow
        Write-Host "These scopes will be requested during the admin consent flow." -ForegroundColor Gray
        Write-Host "Suggested (from inheritable permissions): $suggestedScope" -ForegroundColor Cyan
        Write-Host "You can edit these scopes before submitting." -ForegroundColor Gray

        # Pre-populate with suggested scopes and allow editing
        Write-Host "Current scopes: $suggestedScope" -ForegroundColor Yellow
        $userInput = Read-Host "Edit permission scopes (space-separated, press Enter to use current)"
        if ($userInput -and $userInput.Trim() -ne "") {
            $Scope = $userInput.Trim()
        } else {
            $Scope = $suggestedScope
            Write-Host "Using suggested scopes: $Scope" -ForegroundColor Cyan
        }
    }

    # Generate a random state if not provided
    if (-not $State) {
        $State = "xyz$(Get-Random -Minimum 100 -Maximum 999999)"
    }

    # Ensure we're connected to Microsoft Graph to get tenant ID
    $context = Get-MgContext
    if (-not $context) {
        Write-Host "Not connected to Microsoft Graph. Attempting to connect..." -ForegroundColor Yellow
        Connect-MsIdEntraAsUser
        $context = Get-MgContext
    }

    if (-not $context.TenantId) {
        throw "Unable to determine tenant ID. Please ensure you're connected to Microsoft Graph."
    }

    $tenantId = $context.TenantId
    Write-Host "Connected to Microsoft Graph as: $($context.Account)" -ForegroundColor Green
    Write-Host "Tenant ID: $tenantId" -ForegroundColor Cyan

    try {
        Write-Host "Preparing admin consent page for Agent Identity Blueprint Principal..." -ForegroundColor Green

        # URL encode the parameters
        $encodedClientId = [System.Web.HttpUtility]::UrlEncode($AgentBlueprintId)
        $encodedScope = [System.Web.HttpUtility]::UrlEncode($Scope)
        $encodedRedirectUri = [System.Web.HttpUtility]::UrlEncode($RedirectUri)
        $encodedState = [System.Web.HttpUtility]::UrlEncode($State)

        # Build the admin consent URL
        $requestUri = "https://login.microsoftonline.com/$tenantId/v2.0/adminconsent" +
            "?client_id=$encodedClientId" +
            "&scope=$encodedScope" +
            "&redirect_uri=$encodedRedirectUri" +
            "&state=$encodedState"

        Write-Host "Admin Consent Request Details:" -ForegroundColor Cyan
        Write-Host "  Client ID (Agent Blueprint): $AgentBlueprintId" -ForegroundColor White
        Write-Host "  Tenant ID: $tenantId" -ForegroundColor White
        Write-Host "  Requested Scopes: $Scope" -ForegroundColor White
        Write-Host "  Redirect URI: $RedirectUri" -ForegroundColor White
        Write-Host "  State: $State" -ForegroundColor White
        Write-Host ""
        Write-Host "Admin Consent URL:" -ForegroundColor Yellow
        Write-Host $requestUri -ForegroundColor Cyan
        Write-Host ""

        # Launch the system browser with the consent URL
        try {
            Write-Host "Opening admin consent page in system browser..." -ForegroundColor Green
            Start-Process $requestUri
            Write-Host "✓ Admin consent page opened in browser successfully" -ForegroundColor Green
            Write-Host ""
            Write-Host "Please complete the admin consent process in the browser window." -ForegroundColor Yellow
            Write-Host "After consent is granted, the Agent Blueprint will be able to inherit the requested permissions." -ForegroundColor Yellow
        }
        catch {
            Write-Error "Error opening admin consent page in browser: $($_.Exception.Message)"
            Write-Host "You can manually copy and paste the above URL into your browser." -ForegroundColor Yellow
            throw
        }

        # Create a result object with consent information
        $consentResult = [PSCustomObject]@{
            AgentBlueprintId = $AgentBlueprintId
            TenantId = $tenantId
            RequestedScopes = $Scope
            RedirectUri = $RedirectUri
            State = $State
            ConsentUrl = $requestUri
            Action = "Browser Launched"
            Timestamp = Get-Date
        }

        return $consentResult
    }
    catch {
        Write-Error "Failed to launch admin consent page for Agent Identity Blueprint Principal: $_"
        throw
    }
}
