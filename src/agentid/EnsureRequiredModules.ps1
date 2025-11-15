<#
.SYNOPSIS
Ensures that required PowerShell modules are installed and imported

.DESCRIPTION
Checks for required modules and installs them if they are not available.
Handles version conflicts by checking if compatible versions are already loaded.
#>
function EnsureRequiredModules {
    [CmdletBinding()]
    param()

    $requiredModules = @(
        'Microsoft.Graph.Applications',
        'Microsoft.Graph.Identity.SignIns',
        'Microsoft.Graph.Users',
        'Microsoft.Graph.Identity.DirectoryManagement'
    )

    # Check if there are version conflicts in loaded modules
    $loadedGraphModules = Get-Module -Name Microsoft.Graph.* 
    $hasVersionConflict = $false
    
    if ($loadedGraphModules) {
        $authModule = $loadedGraphModules | Where-Object { $_.Name -eq 'Microsoft.Graph.Authentication' }
        $otherModules = $loadedGraphModules | Where-Object { $_.Name -ne 'Microsoft.Graph.Authentication' }
        
        # Check if loaded modules have different versions of dependencies
        foreach ($mod in $otherModules) {
            $authDep = $mod.RequiredModules | Where-Object { $_.Name -eq 'Microsoft.Graph.Authentication' }
            if ($authDep -and $authModule -and $authDep.Version -ne $authModule.Version) {
                Write-Verbose "Version conflict detected: $($mod.Name) requires Microsoft.Graph.Authentication $($authDep.Version) but $($authModule.Version) is loaded"
                $hasVersionConflict = $true
                break
            }
        }
    }

    # If there's a version conflict, we need to start fresh
    if ($hasVersionConflict) {
        Write-Host "Detected module version conflicts. Removing all Microsoft.Graph modules from session..." -ForegroundColor Yellow
        Get-Module -Name Microsoft.Graph.* | Remove-Module -Force -ErrorAction SilentlyContinue
    }

    foreach ($module in $requiredModules) {
        # Check if module is already loaded with compatible version
        $loadedModule = Get-Module -Name $module
        if ($loadedModule -and -not $hasVersionConflict) {
            Write-Verbose "Module $module is already loaded (version $($loadedModule.Version))"
            continue
        }

        # Install if not available
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
