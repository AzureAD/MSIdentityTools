## Set Strict Mode for Module. https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version 3.0

## PowerShell Desktop 5.1 does not dot-source ScriptsToProcess when a specific version is specified on import. This is a bug.
# if ($PSEdition -eq 'Desktop') {
#     $ModuleManifest = Import-PowershellDataFile (Join-Path $PSScriptRoot $MyInvocation.MyCommand.Name.Replace('.psm1','.psd1'))
#     if ($ModuleManifest.ContainsKey('ScriptsToProcess')) {
#         foreach ($Path in $ModuleManifest.ScriptsToProcess) {
#             . (Join-Path $PSScriptRoot $Path)
#         }
#     }
# }
