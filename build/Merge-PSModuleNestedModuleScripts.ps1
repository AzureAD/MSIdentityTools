param
(
    # Path to Module Manifest
    [Parameter(Mandatory = $false)]
    [string] $ModuleManifestPath = ".\release\*\*.*.*",
    #
    [Parameter(Mandatory = $false)]
    [string] $OutputModulePath,
    #
    [Parameter(Mandatory = $false)]
    [switch] $MergeWithRootModule,
    #
    [Parameter(Mandatory = $false)]
    [switch] $RemoveNestedModuleScriptFiles
)

## Initialize
Import-Module "$PSScriptRoot\CommonFunctions.psm1" -Force -WarningAction SilentlyContinue -ErrorAction Stop

[System.IO.FileInfo] $ModuleManifestFileInfo = Get-PathInfo $ModuleManifestPath -DefaultFilename "*.psd1" -ErrorAction Stop
#[System.IO.DirectoryInfo] $ModuleSourceDirectoryInfo = $ModuleManifestFileInfo.Directory
#[System.IO.DirectoryInfo] $ModuleOutputDirectoryInfo = $OutputModuleFileInfo.Directory

## Read Module Manifest
$ModuleManifest = Import-PowerShellDataFile $ModuleManifestFileInfo.FullName

if ($OutputModulePath) {
    [System.IO.FileInfo] $OutputModuleFileInfo = Get-PathInfo $OutputModulePath -InputPathType File -DefaultFilename "$($ModuleManifestFileInfo.BaseName).psm1" -ErrorAction SilentlyContinue
}
else {
    [System.IO.FileInfo] $OutputModuleFileInfo = Get-PathInfo $ModuleManifest.RootModule -InputPathType File -DefaultDirectory $ModuleManifestFileInfo.DirectoryName -ErrorAction SilentlyContinue
}

if ($OutputModuleFileInfo.Extension -eq ".psm1") {

    [System.IO.FileInfo] $RootModuleFileInfo = Get-PathInfo $ModuleManifest.RootModule -InputPathType File -DefaultDirectory $ModuleManifestFileInfo.DirectoryName -ErrorAction SilentlyContinue
    [System.IO.FileInfo[]] $NestedModulesFileInfo = $ModuleManifest.NestedModules | Get-PathInfo -InputPathType File -DefaultDirectory $ModuleManifestFileInfo.DirectoryName -ErrorAction SilentlyContinue
    [System.IO.FileInfo[]] $ScriptsToProcessFileInfo = $ModuleManifest.ScriptsToProcess | Get-PathInfo -InputPathType File -DefaultDirectory $ModuleManifestFileInfo.DirectoryName -ErrorAction SilentlyContinue

    if ($MergeWithRootModule) {
        [string] $RootModulePreamble = @()

        ## Add Module Manifest as Comment
        #$RootModulePreamble += "<#`r`n{0}`r`n#>`r`n`r`n" -f (Get-Content $ModuleManifestFileInfo.FullName -Raw)

        ## Add Requires Statements
        if ($ModuleManifest.PowerShellVersion) { $RootModulePreamble += "#Requires -Version {0}`r`n" -f $ModuleManifest.PowerShellVersion }
        if ($ModuleManifest.CompatiblePSEditions) { $RootModulePreamble += "#Requires -PSEdition {0}`r`n" -f ($ModuleManifest.CompatiblePSEditions -join ',') }
        foreach ($RequiredAssembly in $ModuleManifest.RequiredAssemblies) {
            $RootModulePreamble += "#Requires -Assembly $_`r`n"
        }
        foreach ($RequiredModule in $ModuleManifest.RequiredModules) {
            $RootModulePreamble += ConvertTo-PsString -Compact -RemoveTypes ([hashtable], [string]) | ForEach-Object { "#Requires -Module $_`r`n" }
        }
        $RootModulePreamble += "`r`n"

        ## Split module parameters from the rest of the module content
        [string] $RootModuleContent = $null
        if ($RootModuleFileInfo.Extension -eq ".psm1" -and (Get-Content $RootModuleFileInfo.FullName -Raw) -match "(?s)^(.*\n\s*param\s*[(](?:[^()]|(?'Nested'[(])|(?'-Nested'[)]))*[)]\s*)?(.*)$") {
            $RootModulePreamble += $Matches[1]
            if ($Matches[1]) { $RootModulePreamble += "`r`n" }
            $RootModuleContent = $Matches[2]
        }

        $RootModulePreamble += "#region NestedModule Scripts`r`n"

        Set-Content $OutputModuleFileInfo.FullName -Value $RootModulePreamble -Encoding utf8BOM
    }

    ## Add Nested Module Scripts
    $NestedModulesFileInfo | Where-Object Extension -EQ '.ps1' | Get-Content -Raw | Add-Content $OutputModuleFileInfo.FullName -Encoding utf8BOM

    if ($MergeWithRootModule) {
        function Join-ModuleMembers ([string[]]$Members) {
            if ($Members.Count -gt 0) {
                return "'{0}'" -f ($Members -join "','")
            }
            else { return "" }
        }

        ## Add remainder of root module content
        $NestedModuleEndRegion = "#endregion`r`n"
        $ExportModuleMember += "Export-ModuleMember -Function @({0}) -Cmdlet @({1}) -Variable @({2}) -Alias @({3})" -f (Join-ModuleMembers $ModuleManifest.FunctionsToExport), (Join-ModuleMembers $ModuleManifest.CmdletsToExport), (Join-ModuleMembers $ModuleManifest.VariablesToExport), (Join-ModuleMembers $ModuleManifest.AliasesToExport)
        
        $NestedModuleEndRegion, $RootModuleContent, $ExportModuleMember | Add-Content $OutputModuleFileInfo.FullName -Encoding utf8BOM
    }

    if ($RemoveNestedModuleScriptFiles) {
        ## Remove Nested Module Scripts
        $NestedModulesFileInfo | Where-Object Extension -EQ '.ps1' | Where-Object { $_.FullName -notin $ScriptsToProcessFileInfo.FullName } | Remove-Item
        ## Remove Empty Directories
        Get-ChildItem $ModuleManifestFileInfo.DirectoryName -Recurse -Directory | Where-Object { !(Get-ChildItem $_.FullName -Recurse -File) } | Remove-Item -Recurse
    }
}
