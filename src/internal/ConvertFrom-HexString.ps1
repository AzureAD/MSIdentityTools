<#
.SYNOPSIS
   Convert from Hex String
.DESCRIPTION

.EXAMPLE
    PS C:\>ConvertFrom-HexString "57 68 61 74 20 69 73 20 61 20 68 65 78 20 73 74 72 69 6E 67 3F"
    Convert hex byte string seperated by spaces to string.
.EXAMPLE
    PS C:\>"415343494920737472696E6720746F2068657820737472696E67" | ConvertFrom-HexString -Delimiter "" -Encoding Ascii
    Convert hex byte string with no seperation to ASCII string.
.INPUTS
    System.String
.LINK
    https://github.com/jasoth/Utility.PS
#>
function ConvertFrom-HexString {
    [CmdletBinding()]
    param (
        # Value to convert
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]] $InputObject,
        # Delimiter between Hex pairs
        [Parameter (Mandatory = $false)]
        [string] $Delimiter = ' ',
        # Output raw byte array
        [Parameter (Mandatory = $false)]
        [switch] $RawBytes,
        # Encoding to use for text strings
        [Parameter (Mandatory = $false)]
        [ValidateSet('Ascii', 'UTF32', 'UTF7', 'UTF8', 'BigEndianUnicode', 'Unicode')]
        [string] $Encoding = 'Default'
    )

    process {
        $InputObject = $InputObject -replace '\s', ''
        $listBytes = New-Object object[] $InputObject.Count
        for ($iString = 0; $iString -lt $InputObject.Count; $iString++) {
            [string] $strHex = $InputObject[$iString]
            if ($strHex.Substring(2, 1) -eq $Delimiter) {
                [string[]] $listHex = $strHex -split $Delimiter
            }
            else {
                [string[]] $listHex = New-Object string[] ($strHex.Length / 2)
                for ($iByte = 0; $iByte -lt $strHex.Length; $iByte += 2) {
                    $listHex[[System.Math]::Truncate($iByte / 2)] = $strHex.Substring($iByte, 2)
                }
            }

            [byte[]] $outBytes = New-Object byte[] $listHex.Count
            for ($iByte = 0; $iByte -lt $listHex.Count; $iByte++) {
                $outBytes[$iByte] = [byte]::Parse($listHex[$iByte], [System.Globalization.NumberStyles]::HexNumber)
            }

            if ($RawBytes) { $listBytes[$iString] = $outBytes }
            else {
                $outString = ([Text.Encoding]::$Encoding.GetString($outBytes))
                Write-Output $outString
            }
        }
        if ($RawBytes) {
            return $listBytes
        }
    }
}
