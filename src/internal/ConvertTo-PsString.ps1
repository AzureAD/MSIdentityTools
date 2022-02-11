<#
.SYNOPSIS
    Convert PowerShell data types to PowerShell string syntax.
.DESCRIPTION

.EXAMPLE
    PS C:\>ConvertTo-PsString @{ key1='value1'; key2='value2' }
    Convert hashtable to PowerShell string.
.INPUTS
    System.String
.LINK
    https://github.com/jasoth/Utility.PS
#>
function ConvertTo-PsString {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        #
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [AllowNull()]
        [object] $InputObjects,
        #
        [Parameter(Mandatory = $false)]
        [switch] $Compact,
        #
        [Parameter(Mandatory = $false, Position = 1)]
        [type[]] $RemoveTypes = ([string], [bool], [int], [long]),
        #
        [Parameter(Mandatory = $false)]
        [switch] $NoEnumerate
    )

    begin {
        if ($Compact) {
            [System.Collections.Generic.Dictionary[string, type]] $TypeAccelerators = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::get
            [System.Collections.Generic.Dictionary[type, string]] $TypeAcceleratorsLookup = New-Object 'System.Collections.Generic.Dictionary[type,string]'
            foreach ($TypeAcceleratorKey in $TypeAccelerators.Keys) {
                if (!$TypeAcceleratorsLookup.ContainsKey($TypeAccelerators[$TypeAcceleratorKey])) {
                    $TypeAcceleratorsLookup.Add($TypeAccelerators[$TypeAcceleratorKey], $TypeAcceleratorKey)
                }
            }
        }

        function Resolve-Type {
            param (
                #
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
                [type] $ObjectType,
                #
                [Parameter(Mandatory = $false, Position = 1)]
                [switch] $Compact,
                #
                [Parameter(Mandatory = $false, Position = 1)]
                [type[]] $RemoveTypes
            )

            [string] $OutputString = ''
            if ($ObjectType.IsGenericType -or ($ObjectType.BaseType -and $ObjectType.BaseType.IsGenericType)) {
                if (!$ObjectType.IsGenericType) { $ObjectType = $ObjectType.BaseType }
                if ($ObjectType.FullName.StartsWith('System.Collections.Generic.Dictionary')) {
                    #$OutputString += '[hashtable]'
                    if ($Compact) {
                        $OutputString += '(Invoke-Command { $D = New-Object ''Collections.Generic.Dictionary['
                    }
                    else {
                        $OutputString += '(Invoke-Command { $D = New-Object ''System.Collections.Generic.Dictionary['
                    }
                    $iInput = 0
                    foreach ($GenericTypeArgument in $ObjectType.GenericTypeArguments) {
                        if ($iInput -gt 0) { $OutputString += ',' }
                        $OutputString += Resolve-Type $GenericTypeArgument -Compact:$Compact -RemoveTypes @()
                        $iInput++
                    }
                    $OutputString += ']'''
                }
                elseif ($InputObject.GetType().FullName -match '^(System.(Collections.Generic.[a-zA-Z]+))`[0-9]\[(?:\[(.+?), .+?, Version=.+?, Culture=.+?, PublicKeyToken=.+?\],?)+?\]$') {
                    if ($Compact) {
                        $OutputString += '[{0}[' -f $Matches[2]
                    }
                    else {
                        $OutputString += '[{0}[' -f $Matches[1]
                    }
                    $iInput = 0
                    foreach ($GenericTypeArgument in $ObjectType.GenericTypeArguments) {
                        if ($iInput -gt 0) { $OutputString += ',' }
                        $OutputString += Resolve-Type $GenericTypeArgument -Compact:$Compact -RemoveTypes @()
                        $iInput++
                    }
                    $OutputString += ']]'
                }
            }
            elseif ($ObjectType -eq [System.Collections.Specialized.OrderedDictionary]) {
                $OutputString += '[ordered]'  # Explicit cast does not work with full name. Only [ordered] works.
            }
            elseif ($Compact) {
                if ($ObjectType -notin $RemoveTypes) {
                    if ($TypeAcceleratorsLookup.ContainsKey($ObjectType)) {
                        $OutputString += '[{0}]' -f $TypeAcceleratorsLookup[$ObjectType]
                    }
                    elseif ($ObjectType.FullName.StartsWith('System.')) {
                        $OutputString += '[{0}]' -f $ObjectType.FullName.Substring(7)
                    }
                    else {
                        $OutputString += '[{0}]' -f $ObjectType.FullName
                    }
                }
            }
            else {
                $OutputString += '[{0}]' -f $ObjectType.FullName
            }
            return $OutputString
        }

        function GetPSString ($InputObject) {
            $OutputString = New-Object System.Text.StringBuilder

            if ($null -eq $InputObject) { [void]$OutputString.Append('$null') }
            else {
                ## Add Casting
                [void]$OutputString.Append((Resolve-Type $InputObject.GetType() -Compact:$Compact -RemoveTypes $RemoveTypes))

                ## Add Value
                switch ($InputObject.GetType()) {
                    { $_.Equals([String]) } {
                        [void]$OutputString.AppendFormat("'{0}'", $InputObject.Replace("'", "''")) #.Replace('"','`"')
                        break
                    }
                    { $_.Equals([Char]) } {
                        [void]$OutputString.AppendFormat("'{0}'", ([string]$InputObject).Replace("'", "''"))
                        break
                    }
                    { $_.Equals([Boolean]) -or $_.Equals([switch]) } {
                        [void]$OutputString.AppendFormat('${0}', $InputObject)
                        break
                    }
                    { $_.Equals([DateTime]) } {
                        [void]$OutputString.AppendFormat("'{0}'", $InputObject.ToString('O'))
                        break
                    }
                    { $_.Equals([guid]) } {
                        [void]$OutputString.AppendFormat("'{0}'", $InputObject)
                        break
                    }
                    { $_.BaseType -and $_.BaseType.Equals([Enum]) } {
                        [void]$OutputString.AppendFormat('::{0}', $InputObject)
                        break
                    }
                    { $_.BaseType -and $_.BaseType.Equals([ValueType]) } {
                        [void]$OutputString.AppendFormat('{0}', $InputObject)
                        break
                    }
                    { $_.BaseType.Equals([System.IO.FileSystemInfo]) -or $_.Equals([System.Uri]) } {
                        [void]$OutputString.AppendFormat("'{0}'", $InputObject.ToString().Replace("'", "''")) #.Replace('"','`"')
                        break
                    }
                    { $_.Equals([System.Xml.XmlDocument]) } {
                        [void]$OutputString.AppendFormat("'{0}'", $InputObject.OuterXml.Replace("'", "''")) #.Replace('"','""')
                        break
                    }
                    { $_.Equals([Hashtable]) -or $_.Equals([System.Collections.Specialized.OrderedDictionary]) } {
                        [void]$OutputString.Append('@{')
                        $iInput = 0
                        foreach ($enumHashtable in $InputObject.GetEnumerator()) {
                            if ($iInput -gt 0) { [void]$OutputString.Append(';') }
                            [void]$OutputString.AppendFormat('{0}={1}', (ConvertTo-PsString $enumHashtable.Key -Compact:$Compact -NoEnumerate), (ConvertTo-PsString $enumHashtable.Value -Compact:$Compact -NoEnumerate))
                            $iInput++
                        }
                        [void]$OutputString.Append('}')
                        break
                    }
                    { $_.FullName.StartsWith('System.Collections.Generic.Dictionary') -or ($_.BaseType -and $_.BaseType.FullName.StartsWith('System.Collections.Generic.Dictionary')) } {
                        $iInput = 0
                        foreach ($enumHashtable in $InputObject.GetEnumerator()) {
                            [void]$OutputString.AppendFormat('; $D.Add({0},{1})', (ConvertTo-PsString $enumHashtable.Key -Compact:$Compact -NoEnumerate), (ConvertTo-PsString $enumHashtable.Value -Compact:$Compact -NoEnumerate))
                            $iInput++
                        }
                        [void]$OutputString.Append('; $D })')
                        break
                    }
                    { $_.BaseType -and $_.BaseType.Equals([Array]) } {
                        [void]$OutputString.Append('(Write-Output @(')
                        $iInput = 0
                        for ($iInput = 0; $iInput -lt $InputObject.Count; $iInput++) {
                            if ($iInput -gt 0) { [void]$OutputString.Append(',') }
                            [void]$OutputString.Append((ConvertTo-PsString $InputObject[$iInput] -Compact:$Compact -RemoveTypes $InputObject.GetType().DeclaredMembers.Where( { $_.Name -eq 'Set' })[0].GetParameters()[1].ParameterType -NoEnumerate))
                        }
                        [void]$OutputString.Append(') -NoEnumerate)')
                        break
                    }
                    { $_.Equals([System.Collections.ArrayList]) } {
                        [void]$OutputString.Append('@(')
                        $iInput = 0
                        for ($iInput = 0; $iInput -lt $InputObject.Count; $iInput++) {
                            if ($iInput -gt 0) { [void]$OutputString.Append(',') }
                            [void]$OutputString.Append((ConvertTo-PsString $InputObject[$iInput] -Compact:$Compact -NoEnumerate))
                        }
                        [void]$OutputString.Append(')')
                        break
                    }
                    { $_.FullName.StartsWith('System.Collections.Generic.List') } {
                        [void]$OutputString.Append('@(')
                        $iInput = 0
                        for ($iInput = 0; $iInput -lt $InputObject.Count; $iInput++) {
                            if ($iInput -gt 0) { [void]$OutputString.Append(',') }
                            [void]$OutputString.Append((ConvertTo-PsString $InputObject[$iInput] -Compact:$Compact -RemoveTypes $_.GenericTypeArguments -NoEnumerate))
                        }
                        [void]$OutputString.Append(')')
                        break
                    }
                    ## Convert objects with object initializers
                    { $_ -is [object] -and ($_.GetConstructors() | ForEach-Object { if ($_.IsPublic -and !$_.GetParameters()) { $true } }) } {
                        [void]$OutputString.Append('@{')
                        $iInput = 0
                        foreach ($Item in ($InputObject | Get-Member -MemberType Property, NoteProperty)) {
                            if ($iInput -gt 0) { [void]$OutputString.Append(';') }
                            $PropertyName = $Item.Name
                            [void]$OutputString.AppendFormat('{0}={1}', (ConvertTo-PsString $PropertyName -Compact:$Compact -NoEnumerate), (ConvertTo-PsString $InputObject.$PropertyName -Compact:$Compact -NoEnumerate))
                            $iInput++
                        }
                        [void]$OutputString.Append('}')
                        break
                    }
                    Default {
                        $Exception = New-Object ArgumentException -ArgumentList ('Cannot convert input of type {0} to PowerShell string.' -f $InputObject.GetType())
                        Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::ParserError) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'ConvertPowerShellStringFailureTypeNotSupported' -TargetObject $InputObject
                    }
                }
            }

            if ($NoEnumerate) {
                $listOutputString.Add($OutputString.ToString())
            }
            else {
                Write-Output $OutputString.ToString()
            }
        }

        if ($NoEnumerate) {
            $listOutputString = New-Object System.Collections.Generic.List[string]
        }
    }

    process {
        if ($PSCmdlet.MyInvocation.ExpectingInput -or $NoEnumerate -or $null -eq $InputObjects) {
            GetPSString $InputObjects
        }
        else {
            foreach ($InputObject in $InputObjects) {
                GetPSString $InputObject
            }
        }
    }

    end {
        if ($NoEnumerate) {
            if (($null -eq $InputObjects -and $listOutputString.Count -eq 0) -or $listOutputString.Count -gt 1) {
                Write-Warning ('To avoid losing strong type on outermost enumerable type when piping, use "Write-Output $Array -NoEnumerate | {0}".' -f $MyInvocation.MyCommand)
                $OutputArray = New-Object System.Text.StringBuilder
                [void]$OutputArray.Append('(Write-Output @(')
                if ($PSVersionTable.PSVersion -ge [version]'6.0') {
                    [void]$OutputArray.AppendJoin(',', $listOutputString)
                }
                else {
                    [void]$OutputArray.Append(($listOutputString -join ','))
                }
                [void]$OutputArray.Append(') -NoEnumerate)')
                Write-Output $OutputArray.ToString()
            }
            else {
                Write-Output $listOutputString[0]
            }

        }
    }
}
