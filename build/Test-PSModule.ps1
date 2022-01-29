param
(
    # Directory used to base all relative paths
    [Parameter(Mandatory = $false)]
    [string] $BaseDirectory = "..\",
    #
    [Parameter(Mandatory = $false)]
    [string] $ModuleDirectory = ".\build\release\MSIdentityTools",
    #
    [Parameter(Mandatory = $false)]
    [string] $ModuleManifestPath,
    #
    [Parameter(Mandatory = $false)]
    [string] $ModuleTestsDirectory = ".\tests",
    #
    [Parameter(Mandatory = $false)]
    [string[]] $PowerShellPaths = @(
        'pwsh'
        'powershell'
        'D:\Software\PowerShell-6.2.4-win-x64\pwsh.exe'
    ),
    #
    [Parameter(Mandatory = $false)]
    [switch] $NoNewWindow
)

Write-Debug @"
Environment Variables
Processor_Architecture: $env:Processor_Architecture
      CurrentDirectory: $((Get-Location).ProviderPath)
          PSScriptRoot: $PSScriptRoot
"@

## Initialize
Import-Module "$PSScriptRoot\CommonFunctions.psm1" -Force -WarningAction SilentlyContinue -ErrorAction Stop
.\Build-PSModule.ps1

[System.IO.DirectoryInfo] $BaseDirectoryInfo = Get-PathInfo $BaseDirectory -InputPathType Directory -ErrorAction Stop
[System.IO.DirectoryInfo] $ModuleDirectoryInfo = Get-PathInfo $ModuleDirectory -InputPathType Directory -DefaultDirectory $BaseDirectoryInfo.FullName -ErrorAction SilentlyContinue
[System.IO.FileInfo] $ModuleManifestFileInfo = Get-PathInfo $ModuleManifestPath -DefaultDirectory $ModuleDirectoryInfo.FullName -DefaultFilename "*.psd1" -ErrorAction SilentlyContinue
[System.IO.DirectoryInfo] $ModuleTestsDirectoryInfo = Get-PathInfo $ModuleTestsDirectory -InputPathType Directory -DefaultDirectory $BaseDirectoryInfo.FullName -ErrorAction SilentlyContinue

##
if ($ModuleManifestFileInfo.Exists) {
    [string] $ModulePath = $ModuleManifestFileInfo.FullName
}
else {
    [string] $ModulePath = $ModuleDirectoryInfo.FullName
}

$strScriptBlockTest = 'Import-Module {0};' -f $ModulePath

$ScriptBlockTest = {
    param ([string]$ModulePath, [string]$TestsDirectory)
    ## Force WindowsPowerShell to load correct version of built-in modules when launched from PowerShell 6+
    if ($PSVersionTable.PSEdition -eq 'Desktop') { Import-Module 'Microsoft.PowerShell.Management', 'Microsoft.PowerShell.Utility', 'CimCmdlets' -MaximumVersion 5.9.9.9 }
    Import-Module Pester -MaximumVersion 4.99
    $PSModule = Import-Module $ModulePath -PassThru

    Set-ExecutionPolicy Bypass -Scope Process
    $CodeCoverage = Invoke-Pester @{ Path = (Join-Path $TestsDirectory "*"); Parameters = @{ ModulePath = $ModulePath } } -CodeCoverage (Join-Path $PSModule.ModuleBase "*") -PassThru
}
$strScriptBlockTest = 'Invoke-Command -ScriptBlock {{ {0} }} -ArgumentList {1}' -f $ScriptBlockTest, (($ModulePath, $ModuleTestsDirectoryInfo.FullName | ConvertTo-PsString -Compact) -join ',')

#[string] $strScriptBlockTest = Get-Content (Join-Path $BaseDirectoryInfo.FullName 'tests\Get-X509Certificate.tests.ps1') -Raw

[string[]] $ArgumentList = ('-NoProfile', '-ExecutionPolicy', 'AllSigned', '-EncodedCommand', [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($strScriptBlockTest)))
if (!$NoNewWindow) { $ArgumentList += '-NoExit' }
foreach ($Path in $PowerShellPaths) {
    Start-Process $Path -ArgumentList $ArgumentList -NoNewWindow:$NoNewWindow -Wait:$NoNewWindow
}
