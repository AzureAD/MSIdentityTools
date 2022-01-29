param
(
    # Directory used to base all relative paths
    [Parameter(Mandatory=$false)]
    [string] $BaseDirectory = "..\",
    #
    [Parameter(Mandatory=$false)]
    [string] $OutputDirectory = ".\build\release\",
    #
    [Parameter(Mandatory=$false)]
    [string] $SourceDirectory = ".\src\",
    #
    [Parameter(Mandatory=$false)]
    [string] $ModuleManifestPath,
    #
    [Parameter(Mandatory=$false)]
    [X509Certificate] $SigningCertificate = (Get-ChildItem Cert:\CurrentUser\My\E7413D745138A6DC584530AECE27CEFDDA9D9CD6 -CodeSigningCert),
    #
    [Parameter(Mandatory=$false)]
    [string] $TimestampServer = 'http://timestamp.digicert.com'
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

## Read Module Manifest
$ModuleManifest = Import-PowershellDataFile $ModuleManifestFileInfo.FullName
[System.IO.DirectoryInfo] $ModuleOutputDirectoryInfo = Join-Path $OutputDirectoryInfo.FullName (Join-Path $ModuleManifestFileInfo.BaseName $ModuleManifest.ModuleVersion)

## Sign PowerShell Files
Set-AuthenticodeSignature (Join-Path $ModuleOutputDirectoryInfo.FullName '*.ps*1*') -Certificate $SigningCertificate -HashAlgorithm SHA256 -IncludeChain NotRoot -TimestampServer $TimestampServer
