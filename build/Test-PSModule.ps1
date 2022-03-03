param
(
    #
    [Parameter(Mandatory = $false)]
    [string] $ModuleManifestPath = ".\src\*.psd1",
    #
    [Parameter(Mandatory = $false)]
    [string] $PSModuleCacheDirectory = ".\build\TestResult\PSModuleCache",
    #
    [Parameter(Mandatory = $false)]
    [string] $PesterConfigurationPath = ".\build\PesterConfiguration.psd1",
    #
    [Parameter(Mandatory = $false)]
    [string] $ModuleTestsDirectory = ".\tests"
)

## Initialize
Import-Module "$PSScriptRoot\CommonFunctions.psm1" -Force -WarningAction SilentlyContinue -ErrorAction Stop

[System.IO.FileInfo] $ModuleManifestFileInfo = Get-PathInfo $ModuleManifestPath -DefaultFilename "*.psd1" -ErrorAction Stop | Select-Object -Last 1
[System.IO.DirectoryInfo] $PSModuleCacheDirectoryInfo = Get-PathInfo $PSModuleCacheDirectory -InputPathType Directory -SkipEmptyPaths -ErrorAction SilentlyContinue
[System.IO.FileInfo] $PesterConfigurationFileInfo = Get-PathInfo $PesterConfigurationPath -DefaultFilename 'PesterConfiguration.psd1' -ErrorAction SilentlyContinue
[System.IO.DirectoryInfo] $ModuleTestsDirectoryInfo = Get-PathInfo $ModuleTestsDirectory -InputPathType Directory -ErrorAction SilentlyContinue

## Restore Module Dependencies
&$PSScriptRoot\Restore-PSModuleDependencies.ps1 -ModuleManifestPath $ModuleManifestPath -PSModuleCacheDirectory $PSModuleCacheDirectoryInfo.FullName | Out-Null

Import-Module Pester -MinimumVersion 5.0.0
#$PSModule = Import-Module $ModulePath -PassThru -Force

$PesterConfiguration = New-PesterConfiguration (Import-PowerShellDataFile $PesterConfigurationFileInfo.FullName)
$PesterConfiguration.Run.Container = New-PesterContainer -Path $ModuleTestsDirectoryInfo.FullName -Data @{ ModulePath = $ModuleManifestFileInfo.FullName }
$PesterConfiguration.CodeCoverage.Path = Split-Path $ModuleManifestFileInfo.FullName -Parent
#$PesterConfiguration.CodeCoverage.OutputPath = [IO.Path]::ChangeExtension($PesterConfiguration.CodeCoverage.OutputPath.Value, "$($PSVersionTable.PSVersion).xml")
#$PesterConfiguration.TestResult.OutputPath = [IO.Path]::ChangeExtension($PesterConfiguration.TestResult.OutputPath.Value, "$($PSVersionTable.PSVersion).xml")
Invoke-Pester -Configuration $PesterConfiguration
