## Set Strict Mode for Module. https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version 3.0

## Display Warning on old PowerShell versions. https://docs.microsoft.com/en-us/powershell/scripting/install/PowerShell-Support-Lifecycle#powershell-end-of-support-dates
if ($PSVersionTable.PSVersion -lt [version]'7.0') {
    Write-Warning 'It is recommended to use this module with the latest version of PowerShell which can be downloaded here: https://aka.ms/install-powershell'
}

class SamlMessage : xml {}
