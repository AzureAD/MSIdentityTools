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


"@
    # Synopsis
    if (![string]::IsNullOrWhiteSpace($help.Synopsis)) {
        $md += @"
## Synopsis

$($help.Synopsis.Trim())


"@
    }
    # Syntax
    if (![string]::IsNullOrWhiteSpace($help.Syntax)) {
        $md += @"
## Syntax

``````powershell
$(($help.Syntax | Out-String).Trim())
``````

"@
    }
    # Description
    if (![string]::IsNullOrWhiteSpace($help.Description)) {
        $md += @"
## Description

$($help.Description.Trim())

"@
    }
    # Parameters
    if($help.parameters.parameter.count -gt 0) {
        $md += @"
## Parameters


"@
        # output each paramter
        foreach($param in $help.parameters.parameter) {
            $md += @"
- $($param.name.Trim())$(if($param.required.ToBoolean($null)){"*"}): ``````$($param.type.name.Trim())``````

  $($param.description.Text.Trim())


"@
            if (![string]::IsNullOrWhiteSpace($param.defaultValue) -and $param.type.name -ne "SwitchParameter") {
                $md += @"
  Default value: "$($param.defaultValue.Trim())"


"@
            }
        }
        # add remark about required paramters
        $md += @"
> ```*```: required parameter


"@
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
    # examples
    if($help.examples.example.Count -gt 0) {
        $md += @"
## Examples


"@
        for($i = 0; $i -lt $help.examples.example.Count; $i += 1) {
            $md += @"
### Example $($i+1)

``````powershell
$($help.examples.example[$i].code.Trim())
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