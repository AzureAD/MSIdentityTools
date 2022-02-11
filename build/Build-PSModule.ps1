param
(
    # Directory used to base all relative paths
    [Parameter(Mandatory = $false)]
    [string] $BaseDirectory = "..\",
    #
    [Parameter(Mandatory = $false)]
    [string] $OutputDirectory = ".\build\release\",
    #
    [Parameter(Mandatory = $false)]
    [string] $SourceDirectory = ".\src\",
    #
    [Parameter(Mandatory = $false)]
    [string] $ModuleManifestPath,
    #
    [Parameter(Mandatory = $false)]
    [string] $PackagesConfigPath = ".\packages.config",
    #
    [Parameter(Mandatory = $false)]
    [string] $PackagesDirectory = ".\build\packages",
    #
    [Parameter(Mandatory = $false)]
    [string] $LicensePath = ".\LICENSE"
)

Write-Debug @"
Environment Variables
Processor_Architecture: $env:Processor_Architecture
      CurrentDirectory: $((Get-Location).ProviderPath)
          PSScriptRoot: $PSScriptRoot
"@

## Initialize
Import-Module "$PSScriptRoot\CommonFunctions.psm1" -Force -WarningAction SilentlyContinue -ErrorAction Stop

[System.IO.DirectoryInfo] $BaseDirectoryInfo = Get-PathInfo $BaseDirectory -InputPathType Directory -ErrorAction Stop
[System.IO.DirectoryInfo] $OutputDirectoryInfo = Get-PathInfo $OutputDirectory -InputPathType Directory -DefaultDirectory $BaseDirectoryInfo.FullName -ErrorAction SilentlyContinue
[System.IO.DirectoryInfo] $SourceDirectoryInfo = Get-PathInfo $SourceDirectory -InputPathType Directory -DefaultDirectory $BaseDirectoryInfo.FullName -ErrorAction Stop
[System.IO.FileInfo] $ModuleManifestFileInfo = Get-PathInfo $ModuleManifestPath -DefaultDirectory $SourceDirectoryInfo.FullName -DefaultFilename "*.psd1" -ErrorAction Stop
[System.IO.FileInfo] $PackagesConfigFileInfo = Get-PathInfo $PackagesConfigPath -DefaultDirectory $BaseDirectoryInfo.FullName -DefaultFilename "packages.config" -ErrorAction Stop
[System.IO.DirectoryInfo] $PackagesDirectoryInfo = Get-PathInfo $PackagesDirectory -InputPathType Directory -DefaultDirectory $BaseDirectoryInfo.FullName -ErrorAction SilentlyContinue
[System.IO.FileInfo] $LicenseFileInfo = Get-PathInfo $LicensePath -DefaultDirectory $BaseDirectoryInfo.FullName -DefaultFilename "LICENSE" -ErrorAction Stop

## Read Module Manifest
$ModuleManifest = Import-PowerShellDataFile $ModuleManifestFileInfo.FullName
[System.IO.DirectoryInfo] $ModuleOutputDirectoryInfo = Join-Path $OutputDirectoryInfo.FullName (Join-Path $ModuleManifestFileInfo.BaseName $ModuleManifest.ModuleVersion)

## Copy Source Module Code to Module Output Directory
Assert-DirectoryExists $ModuleOutputDirectoryInfo -ErrorAction Stop | Out-Null
Copy-Item ("{0}\*" -f $SourceDirectoryInfo.FullName) -Destination $ModuleOutputDirectoryInfo.FullName -Recurse -Force
Copy-Item $LicenseFileInfo.FullName -Destination (Join-Path $ModuleOutputDirectoryInfo.FullName License.txt) -Force

## NuGet Restore
&$PSScriptRoot\Restore-NugetPackages.ps1 -PackagesConfigPath $PackagesConfigFileInfo.FullName -OutputDirectory $PackagesDirectoryInfo.FullName

## Read Packages Configuration
$xmlPackagesConfig = New-Object xml
$xmlPackagesConfig.Load($PackagesConfigFileInfo.FullName)

## Copy Packages to Module Output Directory
foreach ($package in $xmlPackagesConfig.packages.package) {
    [string[]] $targetFrameworks = $package.targetFramework
    if (!$targetFrameworks) { [string[]] $targetFrameworks = "net45", "netcoreapp2.1" }
    foreach ($targetFramework in $targetFrameworks) {
        [System.IO.DirectoryInfo] $PackageDirectory = Join-Path $PackagesDirectoryInfo.FullName ("{0}.{1}\lib\{2}" -f $package.id, $package.version, $targetFramework)
        [System.IO.DirectoryInfo] $PackageOutputDirectory = "{0}\{1}.{2}\{3}" -f $ModuleOutputDirectoryInfo.FullName, $package.id, $package.version, $targetFramework
        $PackageOutputDirectory
        Assert-DirectoryExists $PackageOutputDirectory -ErrorAction Stop | Out-Null
        Copy-Item ("{0}\*" -f $PackageDirectory) -Destination $PackageOutputDirectory.FullName -Recurse -Force
    }
}

## Get Module Output FileList
$ModuleFileListFileInfo = Get-ChildItem $ModuleOutputDirectoryInfo.FullName -Recurse -File
$ModuleRequiredAssembliesFileInfo = $ModuleFileListFileInfo | Where-Object Extension -EQ '.dll'
$ModuleManifestOutputFileInfo = $ModuleFileListFileInfo | Where-Object Name -EQ $ModuleManifestFileInfo.Name

$ModuleFileList = Get-RelativePath $ModuleFileListFileInfo.FullName -BaseDirectory $ModuleOutputDirectoryInfo.FullName -ErrorAction Stop
#$ModuleRequiredAssemblies = Get-RelativePath $ModuleRequiredAssembliesFileInfo.FullName -BaseDirectory $ModuleOutputDirectoryInfo.FullName -ErrorAction Stop

## Update Module Manifest in Module Output Directory
Update-ModuleManifest -Path $ModuleManifestOutputFileInfo.FullName -FileList $ModuleFileList -NestedModules $ModuleManifest.NestedModules -FunctionsToExport $ModuleManifest.FunctionsToExport -AliasesToExport $ModuleManifest.AliasesToExport #-RequiredAssemblies $ModuleRequiredAssemblies

## Sign Module
&$PSScriptRoot\Sign-PSModule.ps1 | Format-Table Path, Status, StatusMessage
