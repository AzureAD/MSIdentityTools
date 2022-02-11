<#
.SYNOPSIS
    Test if current PowerShell process is elevated to local administrator privileges.
.DESCRIPTION
    Test if current PowerShell process is elevated to local administrator privileges.
.EXAMPLE
    PS C:\>Test-PsElevation
    Test is current PowerShell process is elevated.
.LINK
    https://github.com/jasoth/Utility.PS
#>
function Test-PsElevation {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $WindowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $WindowsPrincipal = New-Object 'System.Security.Principal.WindowsPrincipal' $WindowsIdentity
        $LocalAdministrator = [System.Security.Principal.WindowsBuiltInRole]::Administrator
        return $WindowsPrincipal.IsInRole($LocalAdministrator)
    }
    catch { 
        if ($_.Exception.InnerException) {
            Write-Error -Exception $_.Exception.InnerException -Category $_.CategoryInfo.Category -CategoryActivity $_.CategoryInfo.Activity -ErrorId $_.FullyQualifiedErrorId -TargetObject $_.TargetObject
        }
        else { Write-Error -ErrorRecord $_ }
    }
}
