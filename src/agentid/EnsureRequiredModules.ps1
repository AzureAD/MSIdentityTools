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
        'Microsoft.Graph.Identity.SignIns'
    )

    foreach ($module in $requiredModules) {
        Write-Host "Checking module: $module" -ForegroundColor Yellow

        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-Host "Module $module not found. Installing..." -ForegroundColor Red
            try {
                Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
                Write-Host "Successfully installed $module" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to install module $module`: $_"
                return $false
            }
        }
        else {
            Write-Host "Module $module is already installed" -ForegroundColor Green
        }

        # Import the module if not already imported
        if (!(Get-Module -Name $module)) {
            try {
                Import-Module -Name $module -Force
                Write-Host "Successfully imported $module" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to import module $module`: $_"
                return $false
            }
        }
    }

    return $true
}
