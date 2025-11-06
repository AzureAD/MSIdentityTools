<#
.SYNOPSIS
Disconnects from Microsoft Graph and clears module connection state

.DESCRIPTION
Safely disconnects from Microsoft Graph and resets all module connection tracking variables

.EXAMPLE
Disconnect-MsIdEntraAgentID
#>
function Disconnect-MsIdEntraAgentID {
    [CmdletBinding()]
    param()

    try {
        if ($script:LastSuccessfulConnection) {
            Write-Host "Disconnecting from Microsoft Graph (connection type: $script:LastSuccessfulConnection)" -ForegroundColor Yellow
            Disconnect-MgGraph
            Write-Host "Successfully disconnected from Microsoft Graph" -ForegroundColor Green
        } else {
            Write-Host "No active Microsoft Graph connection found" -ForegroundColor Gray
        }

        # Clear connection tracking state
        $script:LastSuccessfulConnection = $null
    }
    catch {
        Write-Warning "Error during disconnect: $_"
    }
}
