<#
.SYNOPSIS
Creates a new Agent User using an Agent Identity

.DESCRIPTION
Creates a new Agent User by posting to the Microsoft Graph users endpoint
using the current Agent Identity ID as the identity parent

.PARAMETER DisplayName
The display name for the Agent User

.PARAMETER UserPrincipalName
The user principal name (email) for the Agent User

.NOTES
Requires an Agent Identity to be created first using New-MsIdAgentIDForAgentIdentityBlueprint (uses stored Agent Identity ID)
The mailNickname is automatically derived from the userPrincipalName

.EXAMPLE
New-MsIdAgentIDUserForAgentId -DisplayName "Agent Identity 26192008" -UserPrincipalName "AgentIdentity26192008@67lxx6.onmicrosoft.com"

.EXAMPLE
New-MsIdAgentIDUserForAgentId  # Will prompt for all required parameters
#>
function New-MsIdAgentIDUserForAgentId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DisplayName,

        [Parameter(Mandatory = $false)]
        [string]$UserPrincipalName
    )

    # Connect using Agent Identity Blueprint credentials
    if (!(ConnectAsAgentIdentityBlueprint)) {
        Write-Error "Failed to connect using Agent Identity Blueprint credentials. Cannot create Agent User."
        return
    }

    # Validate that we have a current Agent Identity ID (from New-MsIdAgentIDForAgentIdentityBlueprint)
    if (-not $script:CurrentAgentIdentityId) {
        Write-Error "No Agent Identity ID found. Please run New-MsIdAgentIDForAgentIdentityBlueprint first to create an Agent Identity."
        return
    }

    # Prompt for missing DisplayName if not provided
    if (-not $DisplayName -or $DisplayName.Trim() -eq "") {
        do {
            $DisplayName = Read-Host "Enter the display name for the Agent User"
        } while (-not $DisplayName -or $DisplayName.Trim() -eq "")
    }

    # Prompt for missing UserPrincipalName if not provided
    if (-not $UserPrincipalName -or $UserPrincipalName.Trim() -eq "") {
        do {
            $UserPrincipalName = Read-Host "Enter the user principal name (email) for the Agent User (e.g., username@domain.onmicrosoft.com)"
        } while (-not $UserPrincipalName -or $UserPrincipalName.Trim() -eq "" -or $UserPrincipalName -notlike "*@*")
    }

    # Validate UserPrincipalName format
    if ($UserPrincipalName -notlike "*@*") {
        Write-Error "Invalid UserPrincipalName format. Must be in email format (e.g., username@domain.com)"
        return
    }

    # Build mailNickname from userPrincipalName by removing the domain
    $mailNickname = $UserPrincipalName.Split('@')[0]

    # Build the request body
    $Body = [PSCustomObject]@{
        "@odata.type" = "microsoft.graph.agentUser"
        displayName = $DisplayName
        userPrincipalName = $UserPrincipalName
        identityParentId = $script:CurrentAgentIdentityId
        mailNickname = $mailNickname
        accountEnabled = $true
    }

    try {
        Write-Host "Creating Agent User '$DisplayName' with UPN '$UserPrincipalName'..." -ForegroundColor Yellow
        Write-Host "Using Agent Identity ID: $script:CurrentAgentIdentityId" -ForegroundColor Gray

        # Convert the body to JSON
        $JsonBody = $Body | ConvertTo-Json -Depth 5
        Write-Host "Request body:" -ForegroundColor Gray
        Write-Host $JsonBody -ForegroundColor Gray

        # Make the REST API call with retry logic
        $retryCount = 0
        $maxRetries = 10
        $agentUser = $null
        $success = $false

        while ($retryCount -lt $maxRetries -and -not $success) {
            try {
                $agentUser = Invoke-MgRestMethod -Method POST -Uri "https://graph.microsoft.com/beta/users/" -Body $JsonBody -ContentType "application/json" -ErrorAction Stop
                $success = $true
            }
            catch {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Write-Host "Attempt $retryCount failed. Waiting 10 seconds before retry..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 10
                }
                else {
                    Write-Error "Failed to create Agent User after $maxRetries attempts: $_"
                    throw
                }
            }
        }

        Write-Host "Agent User created successfully!" -ForegroundColor Green
        Write-Host "Agent User ID: $($agentUser.id)" -ForegroundColor Cyan
        Write-Host "Display Name: $($agentUser.displayName)" -ForegroundColor Cyan
        Write-Host "User Principal Name: $($agentUser.userPrincipalName)" -ForegroundColor Cyan
        Write-Host "Mail Nickname: $($agentUser.mailNickname)" -ForegroundColor Cyan

        # Store the Agent User ID in module state (could be useful for future operations)
        $script:CurrentAgentUserId = $agentUser.id

        return $agentUser
    }
    catch {
        Write-Error "Failed to create Agent User: $_"
        throw
    }
}
