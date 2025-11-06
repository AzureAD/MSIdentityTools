function Grant-MsIdMcpServerPermission {
    <#
    .SYNOPSIS
    Grants delegated permissions to MCP clients for the Microsoft MCP Server for Enterprise.

    .DESCRIPTION
    This cmdlet grants OAuth2 delegated permissions to MCP clients (like VS Code or Visual Studio)
    to access the Microsoft MCP Server for Enterprise. You can specify predefined clients or
    provide custom MCP client app IDs.

    .PARAMETER MCPClient
    Specifies the Visual Studio client(s) to grant permissions to. Can be one or more of:
    'VisualStudioCode', 'VisualStudio', 'VisualStudioMSAL'.
    Either this parameter or MCPClientServicePrincipalId must be specified.

    .PARAMETER MCPClientServicePrincipalId
    The service principal ID(s) of custom MCP client(s) to grant permissions to.
    Must be valid GUID format(s).
    Either this parameter or MCPClient must be specified.

    .PARAMETER Scopes
    Specific scopes to grant. If not specified, all available scopes are granted.

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Grant-MsIdMcpServerPermission
    Grants all available permissions to Visual Studio Code (default MCP client if none specified).

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Grant-MsIdMcpServerPermission -MCPClient 'VisualStudioCode'
    Grants all available permissions to Visual Studio Code.

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Grant-MsIdMcpServerPermission -MCPClient 'VisualStudio', 'VisualStudioCode'
    Grants all available permissions to Visual Studio and Visual Studio Code.

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Grant-MsIdMcpServerPermission -MCPClientServicePrincipalId '12345678-1234-1234-1234-123456789012'
    Grants all available permissions to a custom MCP client using its service principal ID.

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Grant-MsIdMcpServerPermission -MCPClient 'VisualStudioCode' -Scopes 'MCP.User.Read.All', 'MCP.Group.Read.All'
    Grant specific permissions to Visual Studio Code.

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Grant-MsIdMcpServerPermission -MCPClient 'VisualStudioMSAL' -Scopes 'MCP.User.Read.All'
    Grants specific permissions to Visual Studio MSAL client.

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Grant-MsIdMcpServerPermission -MCPClientServicePrincipalId '12345678-1234-1234-1234-123456789012' -Scopes 'MCP.User.Read.All'
    Grants specific permissions to a custom MCP client.
    #>
    [CmdletBinding(DefaultParameterSetName = 'PredefinedClients')]
    param(
        [Parameter(ParameterSetName = 'PredefinedClients', Mandatory = $false)]
        [Parameter(ParameterSetName = 'PredefinedClientsScopes', Mandatory = $true)]
        [ValidateSet('VisualStudioCode', 'VisualStudio', 'VisualStudioMSAL', 'ChatGpt', 'ClaudeDesktop')]
        [string[]]$MCPClient = @('VisualStudioCode'),

        [Parameter(ParameterSetName = 'CustomClients', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CustomClientsScopes', Mandatory = $true)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string[]]$MCPClientServicePrincipalId,

        [Parameter(ParameterSetName = 'PredefinedClients', Mandatory = $false)]
        [Parameter(ParameterSetName = 'PredefinedClientsScopes', Mandatory = $true)]
        [Parameter(ParameterSetName = 'CustomClientsScopes', Mandatory = $true)]
        [string[]]$Scopes
    )

    begin {

        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'Get-MgServicePrincipal', 'Get-MgOauth2PermissionGrant', 'New-MgOauth2PermissionGrant', 'Update-MgOauth2PermissionGrant', 'Remove-MgOauth2PermissionGrant' -MinimumVersion 2.8.0 -ErrorVariable CriticalError)) { return }

        # Make sure required scopes are present
        if ($null -eq (Get-MgContext) -or -not (Get-MgContext).Scopes.Contains('DelegatedPermissionGrant.ReadWrite.All') -or -not (Get-MgContext).Scopes.Contains('Application.ReadWrite.All')) {
            Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
        }

        function Get-ServicePrincipal([string]$appId, [string]$name) {
            $sp = Get-MgServicePrincipal -Filter "appId eq '$appId'" -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $sp) {
                Write-Verbose "Creating service principal for $name ..."
                $sp = New-MgServicePrincipal -AppId $appId
            }
            return $sp
        }

        function Get-Grant {
            param(
                [Parameter(Mandatory)] [string] $ClientSpId,
                [Parameter(Mandatory)] [string] $ResourceSpId
            )
            Get-MgOauth2PermissionGrant `
                -Filter "clientId eq '$ClientSpId' and resourceId eq '$ResourceSpId' and consentType eq 'AllPrincipals'" `
                -Top 1 `
                -Property "id,scope,clientId,resourceId,consentType" `
                -ErrorAction SilentlyContinue |
            Select-Object -First 1
        }

        function Set-ExactScopes([string]$clientSpId, [string]$resourceSpId, [string[]]$targetScopes) {
            $targetString = ($targetScopes | Sort-Object -Unique) -join ' '
            $grant = Get-Grant -clientSpId $clientSpId -resourceSpId $resourceSpId | Select-Object -First 1

            if (-not $targetScopes -or $targetScopes.Count -eq 0) {
                if ($grant) {
                    Write-Verbose "Removing existing grant..."
                    Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $grant.Id -Confirm:$false
                }
                return $null
            }

            if (-not $grant) {
                Write-Verbose "Creating new permission grant..."
                $body = @{
                    clientId    = $clientSpId
                    resourceId  = $resourceSpId
                    consentType = "AllPrincipals"
                    scope       = $targetString
                }
                return (@(New-MgOauth2PermissionGrant -BodyParameter $body)[0])
            }

            $currentScope = if ($grant.Scope) { $grant.Scope } else { "" }
            if ($currentScope -ceq $targetString) {
                Write-Verbose "Grant already has the correct scopes."
                return $grant
            }

            Write-Verbose "Updating existing permission grant..."
            Update-MgOauth2PermissionGrant -OAuth2PermissionGrantId $grant.Id -BodyParameter @{ scope = $targetString }
            return Get-Grant -clientSpId $clientSpId -resourceSpId $resourceSpId
        }

        # Constants
        $resourceAppId = "e8c77dc2-69b3-43f4-bc51-3213c9d915b4"  # Microsoft MCP Server for Enterprise
        $predefinedClients = @{
            "VisualStudioCode" = @{ Name = "Visual Studio Code"; AppId = "aebc6443-996d-45c2-90f0-388ff96faa56" }
            "VisualStudio"     = @{ Name = "Visual Studio"; AppId = "04f0c124-f2bc-4f59-8241-bf6df9866bbd" }
            "VisualStudioMSAL" = @{ Name = "Visual Studio MSAL"; AppId = "62e61498-0c88-438b-a45c-2da0517bebe6" }
            "ChatGpt"          = @{ Name = "ChatGPT"; AppId = "e0476654-c1d5-430b-ab80-70cbd947616a" }
            "ClaudeDesktop"    = @{ Name = "Claude Desktop"; AppId = "08ad6f98-a4f8-4635-bb8d-f1a3044760f0" }
        }

        function Resolve-MCPClient {
            param(
                [string[]]$MCPClients,
                [string[]]$CustomServicePrincipalIds
            )

            $resolvedClients = @()

            # Process MCP clients
            if ($MCPClients) {
                foreach ($client in $MCPClients) {
                    if ($predefinedClients.ContainsKey($client)) {
                        $clientInfo = $predefinedClients[$client]
                        $resolvedClients += @{
                            Name     = $clientInfo.Name
                            AppId    = $clientInfo.AppId
                            IsCustom = $false
                        }
                    }
                }
            }

            # Process custom service principal IDs
            if ($CustomServicePrincipalIds) {
                foreach ($spId in $CustomServicePrincipalIds) {
                    $resolvedClients += @{
                        Name     = "Custom MCP Client"
                        AppId    = $spId
                        IsCustom = $true
                    }
                }
            }

            return $resolvedClients
        }
    }

    process {
        if ($CriticalError) { return }

        # Get resource service principal
        $resourceSp = Get-ServicePrincipal $resourceAppId "Microsoft MCP Server for Enterprise"

        # Get available delegated scopes
        $availableScopes = $resourceSp.Oauth2PermissionScopes | Where-Object IsEnabled | Select-Object -ExpandProperty Value
        if (-not $availableScopes) {
            throw "Resource app exposes no enabled delegated (user) scopes."
        }
        $availableScopes = $availableScopes | Sort-Object -Unique

        # Resolve MCP clients
        $clients = Resolve-MCPClient -MCPClients $MCPClient -CustomServicePrincipalIds $MCPClientServicePrincipalId
        Write-Verbose "Resolved $($clients.Count) MCP client(s): $($clients.Name -join ', ')"

        # Get service principals for the resolved clients
        $clientSps = @()
        foreach ($client in $clients) {
            try {
                $sp = Get-ServicePrincipal $client.AppId $client.Name
                $clientSps += @{
                    Sp       = $sp
                    Name     = $client.Name
                    IsCustom = $client.IsCustom
                }
                Write-Verbose "Found service principal for: $($client.Name)"
            }
            catch {
                Write-Warning "Could not get service principal for $($client.Name) (App ID: $($client.AppId)): $($_.Exception.Message)"
            }
        }

        if ($clientSps.Count -eq 0) {
            throw "No MCP client service principals could be found or created."
        }

        Write-Host "Operating on $($clientSps.Count) MCP client(s): $($clientSps.Name -join ', ')" -ForegroundColor Cyan

        # Determine target scopes
        if ($PSCmdlet.ParameterSetName -like '*Scopes') {
            # Validate specified scopes
            $invalidScopes = $Scopes | Where-Object { $_ -notin $availableScopes }
            if ($invalidScopes) {
                throw "Invalid scopes (not available on resource): $($invalidScopes -join ', ')"
            }
            $targetScopes = $Scopes | Sort-Object -Unique
            Write-Host "Granting specific scopes: $($targetScopes -join ', ')" -ForegroundColor Cyan
        }
        else {
            # Grant all available scopes (default behavior)
            $targetScopes = $availableScopes
            Write-Host "Granting all available scopes: $($targetScopes -join ', ')" -ForegroundColor Cyan
        }

        # Apply the permission grants to all client service principals
        $results = @()
        foreach ($clientSp in $clientSps) {
            try {
                $grant = Set-ExactScopes -clientSpId $clientSp.Sp.Id -resourceSpId $resourceSp.Id -targetScopes $targetScopes
                $results += @{
                    Client  = $clientSp.Name
                    Grant   = $grant
                    Success = $true
                    Error   = $null
                }
            }
            catch {
                $results += @{
                    Client  = $clientSp.Name
                    Grant   = $null
                    Success = $false
                    Error   = $_.Exception.Message
                }
            }
        }

        # Display results
        $successCount = ($results | Where-Object Success | Measure-Object).Count
        $errorCount = ($results | Where-Object { -not $_.Success } | Measure-Object).Count

        Write-Host "`nResults Summary:" -ForegroundColor Yellow
        Write-Host "Successfully processed: $successCount client(s)" -ForegroundColor Green
        if ($errorCount -gt 0) {
            Write-Host "Failed to process: $errorCount client(s)" -ForegroundColor Red
        }

        foreach ($result in $results) {
            if ($result.Success) {
                if ($result.Grant) {
                    Write-Host "`n✓ Successfully granted permissions to $($result.Client)" -ForegroundColor Green
                    Write-Host "  Grant ID: $($result.Grant.Id)" -ForegroundColor Gray

                    # Display granted scopes
                    $grantedScopes = ($result.Grant.Scope -split '\s+' | Where-Object { $_ }) | Sort-Object
                    Write-Host "  Granted scopes:" -ForegroundColor Yellow
                    $grantedScopes | ForEach-Object { Write-Host "    - $_" -ForegroundColor Green }
                }
                else {
                    Write-Host "`n⚠ No permissions were granted to $($result.Client) (empty scope list)" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "`n✗ Failed to grant permissions to $($result.Client)" -ForegroundColor Red
                Write-Host "  Error: $($result.Error)" -ForegroundColor Red
            }
        }
    }
}
