<#
.SYNOPSIS
    Output the first non-null value from list of input values.

.EXAMPLE
    PS > Skip-NullValue $null, 'winner', 'loser'

    Return the first non-null value which is 'winner'.

.EXAMPLE
    PS > Skip-NullValue $null, '', ([guid]::Empty), 0, ([int]-1), 'winner', 'loser' -SkipEmpty -SkipZero -SkipNegativeNumber

    Return the first non-null, non-empty, non-zero, and non-negative value which is 'winner'.

.INPUTS
    System.Object

.LINK
    https://github.com/jasoth/Utility.PS
#>
function Skip-NullValue {
    [CmdletBinding()]
    [Alias('Coalesce')]
    param (
        # Values to coalesce
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        [object] $InputObject,
        # Skip over empty values
        [Parameter(Mandatory = $false)]
        [switch] $SkipEmpty,
        # Skip over zero values
        [Parameter(Mandatory = $false)]
        [switch] $SkipZero,
        # Skip over negative values
        [Parameter(Mandatory = $false)]
        [switch] $SkipNegativeNumber,
        # Default value when no other values 
        [Parameter(Mandatory = $false)]
        [object] $DefaultValue = $null
    )

    process {
        foreach ($Object in $InputObject) {
            ## Check is value is null
            if ($null -ne $Object) {
            
                Write-Debug "ObjectType: $($Object.GetType()) | Object: $Object"

                [bool]$TestEmpty = try { $SkipEmpty -and $Object -eq ($Object.GetType())::Empty } catch { $false }
                [bool]$TestZero = try { $SkipZero -and $Object -eq 0 } catch { $false }
                [bool]$TestNegativeNumber = try { $SkipNegativeNumber -and $Object -lt 0 } catch { $false }

                Write-Debug "TestEmpty: $TestEmpty | TestZero: $TestZero | TestNegativeNumber: $TestNegativeNumber"

                if (!($TestEmpty -or $TestZero -or $TestNegativeNumber)) {
                    return $Object
                }

            }
        }

        return $DefaultValue
    }
}
