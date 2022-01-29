<#
.SYNOPSIS
    Convert splatable PowerShell paramters to PowerShell parameter string syntax.
.EXAMPLE
    PS C:\>ConvertTo-PsParameterString @{ key1='value1'; key2='value2' }
    Convert hashtable to PowerShell parameters string.
.INPUTS
    System.String
.LINK
    https://github.com/jasoth/Utility.PS
#>
function ConvertTo-PsParameterString {
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
        function GetPsParameterString ($InputObject) {
            $OutputString = New-Object System.Text.StringBuilder

            ## Add Value
            switch ($InputObject.GetType()) {
                { $_.Equals([Hashtable]) -or $_.Equals([System.Collections.Specialized.OrderedDictionary]) -or $_.FullName.StartsWith('System.Collections.Generic.Dictionary') -or ($_.BaseType -and $_.BaseType.FullName.StartsWith('System.Collections.Generic.Dictionary')) } {
                    foreach ($Parameter in $InputObject.GetEnumerator()) {
                        [string] $ParameterValue = (ConvertTo-PsString $Parameter.Value -Compact:$Compact -NoEnumerate)
                        if ($ParameterValue.StartsWith('[')) { $ParameterValue = '({0})' -f $ParameterValue }
                        [void]$OutputString.AppendFormat(' -{0} {1}', $Parameter.Key, $ParameterValue)
                    }
                    break
                }
                { $_.BaseType.Equals([Array]) -or $_.Equals([System.Collections.ArrayList]) -or $_.FullName.StartsWith('System.Collections.Generic.List') } {
                    foreach ($Parameter in $InputObject) {
                        [string] $ParameterValue = (ConvertTo-PsString $Parameter -Compact:$Compact -NoEnumerate)
                        if ($ParameterValue.StartsWith('[')) { $ParameterValue = '({0})' -f $ParameterValue }
                        [void]$OutputString.AppendFormat(' {0}', $ParameterValue)
                    }
                    break
                }
                Default {
                    $Exception = New-Object ArgumentException -ArgumentList ('Cannot convert input of type {0} to PowerShell parameter string. Use -NoEnumerate if providing a single splatable array.' -f $InputObject.GetType())
                    Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::ParserError) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'ConvertPowerShellParameterStringFailureTypeNotSupported' -TargetObject $InputObject -ErrorAction Stop
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
        if ($PSCmdlet.MyInvocation.ExpectingInput -or $NoEnumerate) {
            GetPsParameterString $InputObjects
        }
        else {
            foreach ($InputObject in $InputObjects) {
                GetPsParameterString $InputObject
            }
        }
    }

    end {
        if ($NoEnumerate) {
            $OutputArray = New-Object System.Text.StringBuilder
            if ($PSVersionTable.PSVersion -ge [version]'6.0') {
                [void]$OutputArray.AppendJoin('', $listOutputString)
            }
            else {
                [void]$OutputArray.Append(($listOutputString -join ''))
            }
            Write-Output $OutputArray.ToString()
        }
    }
}
