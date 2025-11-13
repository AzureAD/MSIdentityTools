## Set Strict Mode for Module. https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version 3.0

## Display Warning on old PowerShell versions. https://docs.microsoft.com/en-us/powershell/scripting/install/PowerShell-Support-Lifecycle#powershell-end-of-support-dates
if ($PSVersionTable.PSVersion -lt [version]'7.0') {
    Write-Warning 'It is recommended to use this module with the latest version of PowerShell which can be downloaded here: https://aka.ms/install-powershell'
}

#Write-Warning 'It is recommended to update Microsoft Graph PowerShell SDK modules frequently because many commands in this module depend on them.'

class SamlMessage : xml {}

#region AgentID

# Module-level variable to store the current Agent Blueprint ID
$script:CurrentAgentBlueprintId = $null

# Module-level variable to store the current Agent Blueprint App ID
$script:CurrentAgentBlueprintAppId = $null

# Module-level variable to store the current Agent Blueprint Secret
$script:CurrentAgentBlueprintSecret = $null

# Module-level variable to store the current Agent Identity Blueprint Service Principal ID
$script:CurrentAgentBlueprintServicePrincipalId = $null

# Module-level variable to cache the Microsoft Graph Service Principal ID
$script:MSGraphServicePrincipalId = $null

# Module-level variable to store the last configured inheritable scopes
$script:LastConfiguredInheritableScopes = $null

# Module-level variable to store the current Agent Identity ID
$script:CurrentAgentIdentityId = $null

# Module-level variable to store the current Agent Identity App ID
$script:CurrentAgentIdentityAppId = $null

# Module-level variable to store the current tenant ID
$script:CurrentTenantId = $null

# Module-level variable to store the last client secret
$script:LastClientSecret = $null

# Module-level variable to track the last successful connection type
$script:LastSuccessfulConnection = $null

# Module-level variable to store the current Agent User ID
$script:CurrentAgentUserId = $null

#endregion AgentID
