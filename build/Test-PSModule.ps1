param
(
    #
    [Parameter(Mandatory = $false)]
    [string] $ModuleManifestPath = ".\src\*.psd1",
    #
    [Parameter(Mandatory = $false)]
    [string] $PesterConfigurationPath = ".\build\PesterConfiguration.psd1",
    #
    [Parameter(Mandatory = $false)]
    [string] $ModuleTestsDirectory = ".\tests",
    #
    [Parameter(Mandatory = $false)]
    [string[]] $PowerShellPaths = @(
        'pwsh'
        #'powershell'
    ),
    #
    [Parameter(Mandatory = $false)]
    [switch] $NoNewWindow
)

## Initialize
Import-Module "$PSScriptRoot\CommonFunctions.psm1" -Force -WarningAction SilentlyContinue -ErrorAction Stop

[System.IO.FileInfo] $ModuleManifestFileInfo = Get-PathInfo $ModuleManifestPath -DefaultFilename '*.psd1' -ErrorAction Stop
[System.IO.DirectoryInfo] $ModuleTestsDirectoryInfo = Get-PathInfo $ModuleTestsDirectory -InputPathType Directory -ErrorAction SilentlyContinue
[System.IO.FileInfo] $PesterConfigurationFileInfo = Get-PathInfo $PesterConfigurationPath -DefaultFilename 'PesterConfiguration.psd1' -ErrorAction SilentlyContinue

[scriptblock] $ScriptBlockTest = {
    param ([string]$ModulePath, [string]$TestsDirectory, [string]$PesterConfigurationPath)
    ## Force WindowsPowerShell to load correct version of built-in modules when launched from PowerShell 6+
    if ($PSVersionTable.PSEdition -eq 'Desktop') { Import-Module 'Microsoft.PowerShell.Management', 'Microsoft.PowerShell.Utility', 'CimCmdlets' -MaximumVersion 5.9.9.9 }
    Import-Module Pester -MinimumVersion 5.0.0
    #$PSModule = Import-Module $ModulePath -PassThru -Force

    $PesterConfiguration = New-PesterConfiguration (Import-PowerShellDataFile $PesterConfigurationPath)
    $PesterConfiguration.Run.Container = New-PesterContainer -Path $TestsDirectory -Data @{ ModulePath = $ModulePath }
    $PesterConfiguration.CodeCoverage.Path = Split-Path $ModulePath -Parent
    #$PesterConfiguration.CodeCoverage.OutputPath = [IO.Path]::ChangeExtension($PesterConfiguration.CodeCoverage.OutputPath.Value, "$($PSVersionTable.PSVersion).xml")
    #$PesterConfiguration.TestResult.OutputPath = [IO.Path]::ChangeExtension($PesterConfiguration.TestResult.OutputPath.Value, "$($PSVersionTable.PSVersion).xml")
    Invoke-Pester -Configuration $PesterConfiguration
}
$strScriptBlockTest = 'Invoke-Command -ScriptBlock {{ {0} }} -ArgumentList {1}, {2}, {3}' -f $ScriptBlockTest, $ModuleManifestFileInfo.FullName, $ModuleTestsDirectoryInfo.FullName, $PesterConfigurationFileInfo.FullName

[string[]] $ArgumentList = ('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($strScriptBlockTest)))
if (!$NoNewWindow) { $ArgumentList += '-NoExit' }
foreach ($Path in $PowerShellPaths) {
    Start-Process $Path -ArgumentList $ArgumentList -NoNewWindow:$NoNewWindow -Wait:$NoNewWindow
}
