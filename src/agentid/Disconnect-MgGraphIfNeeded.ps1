<#
.SYNOPSIS
Internal function to disconnect from Microsoft Graph if currently connected

.DESCRIPTION
Safely disconnects from Microsoft Graph and clears the connection tracking state
#>
function Disconnect-MgGraphIfNeeded {
    [CmdletBinding()]
    param()

    try {
        if ($script:LastSuccessfulConnection) {
            Write-Host "Disconnecting from Microsoft Graph (previous connection: $script:LastSuccessfulConnection)" -ForegroundColor Yellow
            Disconnect-MgGraph -ErrorAction SilentlyContinue
            $script:LastSuccessfulConnection = $null
        }
    }
    catch {
        # Silent failure on disconnect - not critical
        Write-Debug "Error during disconnect: $_"
    }
}
