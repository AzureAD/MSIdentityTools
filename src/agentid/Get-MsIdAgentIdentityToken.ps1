function Get-MsIdAgentIdentityToken {
    <#
    .SYNOPSIS
    Acquires an access token for an agent identity using client credentials.

    .DESCRIPTION
    To create a new agent identity for this session use Invoke-MsIdAgentIdInteractive.

    The token is returned as a SecureString.

    .PARAMETER BlueprintAppId
    The blueprint application ID. If not provided, the blueprint created in this session is used.

    .PARAMETER AgentIdentityAppId
    The agent identity application ID. If not provided, the blueprint created in this session is used.

    .PARAMETER Scope
    The scope to acquire a token for (e.g., User.Read). If not provided, the default scope is used (https://graph.microsoft.com/.default).

    .PARAMETER Mode
    Authentication mode: AutonomousApp (default), OBO, or AutonomousUser.

    .PARAMETER UserToken
    User token for OBO mode (required when Mode is OBO).

    .PARAMETER UserUpn
    User UPN for AutonomousUser mode (required when Mode is AutonomousUser).

    .EXAMPLE
    $token = Get-AgentIdentityToken -BlueprintAppId "12345..." -AgentIdentityAppId "87654..." -Scope "https://graph.microsoft.com/.default"

    .EXAMPLE
    $token = Get-AgentIdentityToken -BlueprintAppId "12345..." -AgentIdentityAppId "87654..." -Scope "https://graph.microsoft.com/.default" -Mode OBO -UserToken $userToken

    .OUTPUTS
    String containing the access token
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$BlueprintAppId,

        [Parameter(Mandatory = $false)]
        [string]$AgentIdentityAppId,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$BlueprintSecret,

        [Parameter(Mandatory = $false)]
        [string]$Scope,

        [Parameter(Mandatory = $false)]
        [ValidateSet('AutonomousApp', 'OBO', 'AutonomousUser')]
        [string]$Mode = 'AutonomousApp',

        [Parameter(Mandatory = $false)]
        [string]$UserToken,

        [Parameter(Mandatory = $false)]
        [string]$UserUpn
    )

    try {
        if (-not $BlueprintAppId) {
            if (-not $script:CurrentAgentBlueprintAppId) {
                throw "No BlueprintAppId provided and no current blueprint available. Please provide a BlueprintAppId."
            }
            $BlueprintAppId = $script:CurrentAgentBlueprintAppId
            Write-Host "Using stored Blueprint App ID: $BlueprintAppId" -ForegroundColor Gray
        }

        if (-not $AgentIdentityAppId) {
            if (-not $script:CurrentAgentIdentityAppId) {
                throw "No AgentIdentityAppId provided and no current agent identity available. Please provide an AgentIdentityAppId."
            }
            $AgentIdentityAppId = $script:CurrentAgentIdentityAppId
            Write-Host "Using stored Agent Identity App ID: $AgentIdentityAppId" -ForegroundColor Gray
        }

        if (-not $BlueprintSecret) {
            if (-not $script:LastClientSecret) {
                throw "No BlueprintSecret provided and no current client secret available. Please provide a BlueprintSecret."
            }
            $BlueprintSecret = $script:LastClientSecret
            Write-Host "Using stored Blueprint Client Secret." -ForegroundColor Gray
        }
        else {
            $BlueprintSecret = $script:LastClientSecret
        }

        if (-not $Scope) {
            $Scope = "https://graph.microsoft.com/.default"
            Write-Host "Using default scope: $Scope" -ForegroundColor Gray
        }

        # Validate parameters based on mode
        if ($Mode -eq 'OBO' -and [string]::IsNullOrEmpty($UserToken)) {
            throw "UserToken is required for OBO mode"
        }

        if ($Mode -eq 'AutonomousUser' -and [string]::IsNullOrEmpty($UserUpn)) {
            throw "UserUpn is required for AutonomousUser mode"
        }
        $tenantId = (Get-MgContext).TenantId

        $tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

        # Step 1: Get parent app token for fmi_path
        Write-Host "Step 1: Acquiring parent app token with fmi_path..."
        $parentTokenBody = @{
            grant_type    = "client_credentials"
            client_id     = $BlueprintAppId
            client_secret = ($BlueprintSecret | ConvertFrom-SecureString -AsPlainText)
            scope         = "api://AzureADTokenExchange/.default"
            fmi_path      = $AgentIdentityAppId
        }

        $parentTokenResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $parentTokenBody -ContentType "application/x-www-form-urlencoded"
        $parentToken = $parentTokenResponse.access_token

        if ([string]::IsNullOrEmpty($parentToken)) {
            throw "Failed to acquire parent app token"
        }

        Write-Verbose "Parent app token acquired successfully"

        # Step 2: Acquire agent identity token based on mode
        if ($Mode -eq 'AutonomousApp') {
            Write-Verbose "Step 2: Acquiring agent identity token (AutonomousApp mode)..."
            $agentTokenBody = @{
                grant_type            = "client_credentials"
                client_id             = $AgentIdentityAppId
                client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
                client_assertion      = $parentToken
                scope                 = $Scope
            }

            $agentTokenResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $agentTokenBody -ContentType "application/x-www-form-urlencoded"
            $agentToken = $agentTokenResponse.access_token
        }
        elseif ($Mode -eq 'OBO') {
            Write-Verbose "Step 2: Acquiring agent identity token (OBO mode)..."
            $agentTokenBody = @{
                grant_type            = "urn:ietf:params:oauth:grant-type:jwt-bearer"
                client_id             = $AgentIdentityAppId
                client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
                client_assertion      = $parentToken
                assertion             = $UserToken
                requested_token_use   = "on_behalf_of"
                scope                 = $Scope
            }

            $agentTokenResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $agentTokenBody -ContentType "application/x-www-form-urlencoded"
            $agentToken = $agentTokenResponse.access_token
        }
        elseif ($Mode -eq 'AutonomousUser') {
            Write-Verbose "Step 2: Acquiring agent identity token (AutonomousUser mode)..."

            # Step 2a: Get FIC exchange token
            Write-Verbose "Step 2a: Acquiring FIC exchange token..."
            $ficTokenBody = @{
                grant_type            = "client_credentials"
                client_id             = $AgentIdentityAppId
                client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
                client_assertion      = $parentToken
                scope                 = "api://AzureADTokenExchange/.default"
            }

            $ficTokenResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $ficTokenBody -ContentType "application/x-www-form-urlencoded"
            $ficExchangeToken = $ficTokenResponse.access_token

            if ([string]::IsNullOrEmpty($ficExchangeToken)) {
                throw "Failed to acquire FIC exchange token"
            }

            Write-Verbose "FIC exchange token acquired successfully"

            # Step 2b: Use user_fic grant
            Write-Verbose "Step 2b: Acquiring agent token with user_fic grant..."
            $agentTokenBody = @{
                grant_type                         = "user_fic"
                client_id                          = $AgentIdentityAppId
                username                           = $UserUpn
                user_federated_identity_credential = $ficExchangeToken
                scope                              = $Scope
                client_assertion_type              = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
                client_assertion                   = $parentToken
            }

            $agentTokenResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $agentTokenBody -ContentType "application/x-www-form-urlencoded"
            $agentToken = $agentTokenResponse.access_token
        }

        if ([string]::IsNullOrEmpty($agentToken)) {
            throw "Failed to acquire agent identity token"
        }

        Write-Verbose "Agent identity token acquired successfully"
        return ConvertTo-SecureString $agentToken -AsPlainText
    }
    catch {
        Write-Error "Failed to acquire agent identity token: $_"
        throw
    }
}
