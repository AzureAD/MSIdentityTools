#Requires -Version 7.0

param
(
    # Path to Module Manifest
    [parameter(Mandatory = $false)]
    [string] $ModuleManifestPath = "..\src",
    # Path to the wiki folder
    [parameter(Mandatory = $false)]
    [string] $wikiPath = "..\.wiki"

)

## Initialize
Import-Module "$PSScriptRoot\CommonFunctions.psm1" -Force -WarningAction SilentlyContinue -ErrorAction Stop

# Get the module file info
[System.IO.FileInfo] $ModuleManifestFileInfo = Get-PathInfo $ModuleManifestPath -DefaultFilename "*.psd1" -ErrorAction Stop

# Get the module name
$moduleName = $ModuleManifestFileInfo.BaseName

## Import module
Import-Module -Name $ModuleManifestFileInfo.FullName

## Get Commands Help from module
$helps = Get-Command -module $moduleName  | Where-Object { $_.CommandType -eq "Function"} | Get-Help -full

$cmdletsmd = @"
# Cmdlets contained in the $moduleName Module

| Command | Synopsys |
| --- | --- |

"@

## Generate documentation for each command and add it to commandlets list
New-Item -Path $wikiPath -ItemType "Directory" -ErrorAction:SilentlyContinue
foreach($help in $helps) {
    $cmdletsmd += "| [$($help.Name)](./$($help.Name)) | $($help.Synopsis.Trim()) |`n"
    # title
    $md = @"
# $($help.Name)

Reference

Module: [$moduleName](./)


"@
    # Synopsis
    if (![string]::IsNullOrWhiteSpace($help.Synopsis)) {
        $md += @"
## Synopsis

$($help.Synopsis.Trim())


"@
    }
    # Syntax
    $cmd = Get-Command -Name $help.name

    $md += @"
## Syntax


"@
    foreach($paramSet in $cmd.ParameterSets) {
        $name = ""
        if (!$paramSet.Name.StartsWith("__")) {
            $name = $paramSet.Name
        }
        $default = ""
        if ($paramSet.IsDefault) {
            $default = "(Default)"
        }
        if ($name) {
            $md += @"
### $($name) $default


"@
        }
        $md += @"
``````powershell
$($cmd.Name) $($paramSet.ToString())
``````


"@
    }
    # Description
    $description = $help.Description | Out-String
    if (![string]::IsNullOrWhiteSpace($description)) {
        $md += @"
## Description

$($description.Trim())


"@
    }
    # examples
    if($help.examples.example.Count -gt 0) {
        $md += @"
## Examples


"@
        for($i = 0; $i -lt $help.examples.example.Count; $i += 1) {
            # example
            $md += @"
### Example $($i+1)

``````powershell
$($help.examples.example[$i].code.Trim())
``````


"@
            $remarks = ($help.examples.example[$i].remarks | Out-String).Trim()
            # remarks for example
            if (![string]::IsNullOrWhiteSpace($remarks)) {
    $md += @"
$remarks


"@
            }
        } 
    }
    # Parameters
    if($help.parameters.parameter.count -gt 0) {
        $md += @"
## Parameters


"@
        # output each paramter
        foreach($param in $help.parameters.parameter) {
            $defaultValue = "None"
            if (![string]::IsNullOrWhiteSpace($param.defaultValue)) {
                $defaultValue = $param.defaultValue.Trim()
            }
            $md += @"
### -$($param.name.Trim())

  $($param.description.Text.Trim())

``````yaml
Type: $($param.type.name.Trim())
Required: $($param.required.ToString())
Default value: $defaultValue
Accept pipeline input: $($param.pipelineInput)
Accept wildcard characters: $($param.globbing)
``````


"@
        }
    }
    # input types
    if($help.inputTypes.inputType.type.name.Count -gt 0) {
        $md += @"
## Inputs


"@
        foreach($inputType in $help.inputTypes.inputType.type.name) {
            $md += @"
``````
$($inputType)
``````


"@
        }        
    }
    # result types
    if($help.returnValues.returnValue.type.name.Count -gt 0) {
        $md += @"
## Outputs


"@
        foreach($returnValue in $help.returnValues.returnValue.type.name) {
            $md += @"
``````
$($returnValue)
``````


"@
        }        
    }
    # aliases
    $aliases = $(get-alias -definition $help.Name -ErrorAction SilentlyContinue)
    if($aliases.Count -gt 0){
        $md += @"
## Aliases


"@
        foreach($alias in $aliases) {
            $md += @"
- $($alias.Name)

"@
        }
        $md += "`n"
    }
    # related links
    if ($help.relatedLinks.navigationLink.Count -gt 0) {
        $md += @"
## Related Links


"@
        foreach($link in $help.relatedLinks.navigationLink) {
            $title = ""
            $href = ""
            # get the proper link
            if ($link.uri) {
                $title = $link.uri
                if ($link.linkText) {
                    $title = $link.linkText
                }
                $href = $link.uri
            } elseif ($link.linkText) {
                $title = $link.linkText
                $href = "./$($link.linkText)"
            } else {
                continue
            }
            $md += @"
- [$title]($href)

"@
        }
        $md += "`n"
    }
    $md | Out-File -FilePath (Join-Path -Path $wikiPath -ChildPath "$($help.Name).md") -Force
}
$cmdletsmd | Out-File -FilePath (Join-Path -Path $wikiPath -ChildPath "Cmdlets.md") -Force