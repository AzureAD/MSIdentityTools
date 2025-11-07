<#
.SYNOPSIS
Ensures that required PowerShell modules are installed and imported

.DESCRIPTION
Checks for required modules and installs them if they are not available
#>
function EnsureRequiredModules {
    [CmdletBinding()]
    param()

    $requiredModules = @(
        'Microsoft.Graph.Authentication',
        'Microsoft.Graph.Applications',
        'Microsoft.Graph.Identity.SignIns',
        'Microsoft.Graph.Users',
        'Microsoft.Graph.Identity.DirectoryManagement'
    )

    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-Host "Module $module not found. Installing..." -ForegroundColor Yellow
            try {
                Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
                Write-Host "Successfully installed $module" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to install module $module`: $_"
                return $false
            }
        }

        # Import the module if not already imported
        if (!(Get-Module -Name $module)) {
            try {
                Import-Module -Name $module -Force
            }
            catch {
                Write-Error "Failed to import module $module`: $_"
                return $false
            }
        }
    }

    return $true
}
