<#
.SYNOPSIS
    Imports the AD FS PowerShell module.
.DESCRIPTION
    Imports the AD FS PowerShell module if not imported and returns $true. Returns $false in case it is not installed.
.EXAMPLE
    PS > if (Import-AdfsModule) { Write-Host 'AD FS PowerShell module is present' }

    Displays a string if the AD FS module was sucessfully imported.
#>
function Import-AdfsModule {
    $module = 'ADFS'
    
    if(-not(Get-Module -Name $module)) {
        if(Get-Module -ListAvailable | Where-Object { $_.name -eq $module }) {
            Import-Module -Name $module
            $true
        }
        else { $false }
    }
    else { $true } #module already loaded
}
