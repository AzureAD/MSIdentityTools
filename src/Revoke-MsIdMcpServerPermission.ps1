function Revoke-MsIdMcpServerPermission {
    <#
    .SYNOPSIS
    Revokes delegated permissions from MCP clients for the Microsoft MCP Server for Enterprise.

    .DESCRIPTION
    This cmdlet revokes OAuth2 delegated permissions from MCP clients (like VS Code or Visual Studio)
    to access the Microsoft MCP Server for Enterprise. You can specify predefined clients or
    provide custom MCP client app IDs.

    .PARAMETER MCPClient
    Specifies the predefined MCP client(s) to revoke permissions from. Valid values are:
    - VisualStudio: Visual Studio
    - VisualStudioCode: Visual Studio Code
    - VisualStudioMSAL: Visual Studio MSAL

    .PARAMETER MCPClientServicePrincipalId
    Specifies custom service principal ID(s) to revoke permissions from. Must be valid GUIDs.

    .PARAMETER Scopes
    Specific scopes to revoke. If not specified, all permissions are revoked.

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Revoke-MsIdMcpServerPermission
    Revokes all permissions from Visual Studio Code (default MCP client if none specified).

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Revoke-MsIdMcpServerPermission -MCPClient VisualStudioCode -Scopes 'Group.Read.All'
    Revokes specific permissions from Visual Studio Code.

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Revoke-MsIdMcpServerPermission -MCPClient 'VisualStudio', 'VisualStudioCode'
    Revokes all permissions from Visual Studio and Visual Studio Code.

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Revoke-MsIdMcpServerPermission -MCPClientServicePrincipalId '12345678-1234-1234-1234-123456789012'
    Revokes all permissions from a custom MCP client using its service principal ID.

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Revoke-MsIdMcpServerPermission -VisualStudioClient 'VisualStudioMSAL' -Scopes 'User.Read.All'
    Revokes specific permissions from Visual Studio MSAL client.

    .EXAMPLE
    Connect-MgGraph -Scopes DelegatedPermissionGrant.ReadWrite.All, Application.ReadWrite.All
    Revoke-MsIdMcpServerPermission -MCPClientServicePrincipalId '12345678-1234-1234-1234-123456789012' -Scopes 'User.Read.All'
    Revokes specific permissions from a custom MCP client.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'PredefinedClients')]
    param(
        [Parameter(ParameterSetName = 'PredefinedClients', Mandatory = $false)]
        [ValidateSet('VisualStudioCode', 'VisualStudio', 'VisualStudioMSAL', 'ChatGpt', 'ClaudeDesktop')]
        [string[]]$MCPClient = @('VisualStudioCode'),

        [Parameter(ParameterSetName = 'CustomClients', Mandatory = $true)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string[]]$MCPClientServicePrincipalId,

        [Parameter(ParameterSetName = 'PredefinedClients', Mandatory = $false)]
        [Parameter(ParameterSetName = 'CustomClients', Mandatory = $false)]
        [string[]]$Scopes
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'Get-MgServicePrincipal', 'Get-MgOauth2PermissionGrant', 'Remove-MgOauth2PermissionGrant', 'Update-MgOauth2PermissionGrant' -MinimumVersion 2.8.0 -ErrorVariable CriticalError)) { return }

        function Get-ServicePrincipal([string]$appId, [string]$name) {
            $sp = Get-MgServicePrincipal -Filter "appId eq '$appId'" -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $sp) {
                throw "Service principal for $name not found. App ID: $appId"
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

        function Update-GrantScopes([string]$clientSpId, [string]$resourceSpId, [string[]]$targetScopes) {
            $grant = Get-Grant -clientSpId $clientSpId -resourceSpId $resourceSpId | Select-Object -First 1

            if (-not $grant) {
                Write-Verbose "No existing grant found for this client."
                return $null
            }

            if (-not $targetScopes -or $targetScopes.Count -eq 0) {
                Write-Verbose "Removing entire permission grant..."
                Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $grant.Id -Confirm:$false
                return $null
            }

            $targetString = ($targetScopes | Sort-Object -Unique) -join ' '

            $currentScope = if ($grant.Scope) { $grant.Scope } else { "" }
            if ($currentScope -ceq $targetString) {
                Write-Verbose "Grant already has the correct scopes."
                return $grant
            }

            Write-Verbose "Updating permission grant with remaining scopes..."
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

        # Resolve MCP clients
        $resolvedClients = Resolve-MCPClient -MCPClients $MCPClient -CustomServicePrincipalIds $MCPClientServicePrincipalId
        Write-Verbose "Resolved $($resolvedClients.Count) MCP client(s): $($resolvedClients.Name -join ', ')"        # Get service principals for the resolved clients
        $clientSps = @()
        foreach ($client in $resolvedClients) {
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
                continue
            }
        }

        if ($clientSps.Count -eq 0) {
            Write-Warning "No MCP client service principals could be found."
            return
        }

        Write-Host "Operating on $($clientSps.Count) MCP client(s): $($clientSps.Name -join ', ')" -ForegroundColor Cyan        # Process each client service principal
        $results = @()
        $allCurrentScopes = @()

        # First pass: collect all current scopes across all clients
        foreach ($clientSp in $clientSps) {
            $currentGrant = Get-Grant -ClientSpId $clientSp.Sp.Id -ResourceSpId $resourceSp.Id
            if ($currentGrant -and $currentGrant.Scope) {
                $currentScopes = ($currentGrant.Scope -split '\s+' | Where-Object { $_ }) | Sort-Object -Unique
                $allCurrentScopes += $currentScopes
            }
        }

        $allCurrentScopes = $allCurrentScopes | Sort-Object -Unique

        if (-not $allCurrentScopes -and $clientSps.Count -gt 1) {
            Write-Warning "No scopes currently granted to any of the MCP clients."
            return
        }        # Determine operation scope
        if ($Scopes) {
            # Revoke specific scopes
            $scopesToRevoke = $Scopes | Sort-Object -Unique
            $invalidScopes = $scopesToRevoke | Where-Object { $_ -notin $allCurrentScopes }
            if ($invalidScopes) {
                Write-Warning "The following scopes are not currently granted to any client: $($invalidScopes -join ', ')"
            }

            $validScopesToRevoke = $scopesToRevoke | Where-Object { $_ -in $allCurrentScopes }
            if (-not $validScopesToRevoke) {
                Write-Warning "No valid scopes to revoke."
                return
            }

            $actionDescription = "Revoke scopes '$($validScopesToRevoke -join ', ')' from $($clientSps.Count) MCP client(s): $($clientSps.Name -join ', ')"
        }
        else {
            # Revoke all scopes
            $validScopesToRevoke = $allCurrentScopes
            $actionDescription = "Revoke ALL permissions from $($clientSps.Count) MCP client(s): $($clientSps.Name -join ', ')"
        }

        # Confirm action for all clients
        if ($PSCmdlet.ShouldProcess("$($clientSps.Count) MCP client(s)", $actionDescription)) {
            # Second pass: process each client
            foreach ($clientSp in $clientSps) {
                try {
                    $currentGrant = Get-Grant -ClientSpId $clientSp.Sp.Id -ResourceSpId $resourceSp.Id

                    if (-not $currentGrant) {
                        $results += @{
                            Client          = $clientSp.Name
                            Success         = $true
                            Action          = "No existing grant"
                            RemovedScopes   = @()
                            RemainingScopes = @()
                            Error           = $null
                        }
                        continue
                    }

                    # Get current scopes for this specific client
                    $currentClientScopes = if ($currentGrant.Scope) {
                        ($currentGrant.Scope -split '\s+' | Where-Object { $_ }) | Sort-Object -Unique
                    }
                    else {
                        @()
                    }

                    if (-not $currentClientScopes) {
                        $results += @{
                            Client          = $clientSp.Name
                            Success         = $true
                            Action          = "No scopes to revoke"
                            RemovedScopes   = @()
                            RemainingScopes = @()
                            Error           = $null
                        }
                        continue
                    }

                    # Calculate remaining scopes for this client
                    if ($Scopes) {
                        $remainingScopes = $currentClientScopes | Where-Object { $_ -notin $validScopesToRevoke }
                        $actualRemovedScopes = $currentClientScopes | Where-Object { $_ -in $validScopesToRevoke }
                    }
                    else {
                        $remainingScopes = @()
                        $actualRemovedScopes = $currentClientScopes
                    }

                    # Update the grant
                    $result = Update-GrantScopes -clientSpId $clientSp.Sp.Id -resourceSpId $resourceSp.Id -targetScopes $remainingScopes

                    $results += @{
                        Client          = $clientSp.Name
                        Success         = $true
                        Action          = if ($remainingScopes.Count -eq 0) { "All permissions revoked" } else { "Partial revocation" }
                        RemovedScopes   = $actualRemovedScopes
                        RemainingScopes = $remainingScopes
                        Error           = $null
                    }
                }
                catch {
                    $results += @{
                        Client          = $clientSp.Name
                        Success         = $false
                        Action          = "Failed"
                        RemovedScopes   = @()
                        RemainingScopes = @()
                        Error           = $_.Exception.Message
                    }
                }
            }

            # Display results
            # Use measure-object to count successes and failures
            $successCount = ($results | Where-Object Success | Measure-Object).Count
            $errorCount = ($results | Where-Object { -not $_.Success } | Measure-Object).Count

            Write-Host "`nResults Summary:" -ForegroundColor Yellow
            Write-Host "Successfully processed: $successCount client(s)" -ForegroundColor Green
            if ($errorCount -gt 0) {
                Write-Host "Failed to process: $errorCount client(s)" -ForegroundColor Red
            }

            foreach ($result in $results) {
                if ($result.Success) {
                    Write-Host "`n✓ $($result.Client): $($result.Action)" -ForegroundColor Green

                    if ($result.RemovedScopes.Count -gt 0) {
                        Write-Host "  Revoked scopes:" -ForegroundColor Yellow
                        $result.RemovedScopes | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
                    }

                    if ($result.RemainingScopes.Count -gt 0) {
                        Write-Host "  Remaining scopes:" -ForegroundColor Yellow
                        $result.RemainingScopes | ForEach-Object { Write-Host "    - $_" -ForegroundColor Green }
                    }
                }
                else {
                    Write-Host "`n✗ Failed to process $($result.Client)" -ForegroundColor Red
                    Write-Host "  Error: $($result.Error)" -ForegroundColor Red
                }
            }
        }
    }
}
