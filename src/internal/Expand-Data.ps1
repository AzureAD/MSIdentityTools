<#
.SYNOPSIS
    Decompress data using DEFLATE (RFC 1951) or GZIP file format (RFC 1952).
.DESCRIPTION

.EXAMPLE
    [byte[]] $byteArray = @(115,84,40,46,41,202,204,75,87,72,203,47,82,72,206,207,45,40,74,45,46,206,204,207,3,0)
    PS C:\>Expand-Data $byteArray
    Decompress string using Deflate.
.INPUTS
    System.String
.LINK
    https://github.com/jasoth/Utility.PS
#>
function Expand-Data {
    [CmdletBinding()]
    [Alias('Decompress-Data')]
    [Alias('Inflate-Data')]
    [OutputType([string], [byte[]])]
    param (
        # Value to convert
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object] $InputObjects,
        # Input is gzip file format
        [Parameter(Mandatory = $false)]
        [switch] $GZip,
        # Output raw byte array
        [Parameter (Mandatory = $false)]
        [switch] $RawBytes,
        # Encoding to use for text strings
        [Parameter (Mandatory = $false)]
        [ValidateSet('Ascii', 'UTF32', 'UTF7', 'UTF8', 'BigEndianUnicode', 'Unicode')]
        [string] $Encoding = 'Default'
    )

    begin {
        function Expand ([byte[]]$InputBytes) {
            try {
                $streamOutput = New-Object System.IO.MemoryStream
                try {
                    $streamInput = New-Object System.IO.MemoryStream -ArgumentList @($InputBytes, $false)
                    try {
                        if ($GZip) {
                            $streamCompression = New-Object System.IO.Compression.GZipStream -ArgumentList $streamInput, ([System.IO.Compression.CompressionMode]::Decompress)
                        }
                        else {
                            $streamCompression = New-Object System.IO.Compression.DeflateStream -ArgumentList $streamInput, ([System.IO.Compression.CompressionMode]::Decompress)
                        }
                        $streamCompression.CopyTo($streamOutput)
                    }
                    catch {
                        Write-Error -Exception $_.Exception.InnerException -Category ([System.Management.Automation.ErrorCategory]::InvalidData) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'ExpandDataFailureInvalidData' -TargetObject $InputBytes -ErrorAction Stop
                    }
                    finally { $streamCompression.Dispose() }
                    [byte[]] $OutputBytes = $streamOutput.ToArray()
                }
                finally { $streamInput.Dispose() }
            }
            finally { $streamOutput.Dispose() }

            Write-Output $OutputBytes
        }

        ## Create list to capture byte stream from piped input.
        [System.Collections.Generic.List[byte]] $listBytes = New-Object System.Collections.Generic.List[byte]
    }

    process {
        if ($InputObjects -is [byte[]]) {
            [byte[]] $outBytes = Expand $InputObjects
            if ($RawBytes) {
                Write-Output $outBytes -NoEnumerate
            }
            else {
                [string] $outString = ([Text.Encoding]::$Encoding.GetString($outBytes))
                Write-Output $outString
            }
        }
        else {
            foreach ($InputObject in $InputObjects) {
                [byte[]] $InputBytes = $null
                if ($InputObject -is [byte]) {
                    ## Populate list with byte stream from piped input.
                    if ($listBytes.Count -eq 0) {
                        Write-Verbose 'Creating byte array from byte stream.'
                        Write-Warning ('For better performance when piping a single byte array, use "Write-Output $byteArray -NoEnumerate | {0}".' -f $MyInvocation.MyCommand)
                    }
                    $listBytes.Add($InputObject)
                }
                elseif ($InputObject -is [byte[]]) {
                    $InputBytes = $InputObject
                }
                elseif ($InputObject -is [bool] -or $InputObject -is [char] -or $InputObject -is [single] -or $InputObject -is [double] -or $InputObject -is [int16] -or $InputObject -is [int32] -or $InputObject -is [int64] -or $InputObject -is [uint16] -or $InputObject -is [uint32] -or $InputObject -is [uint64]) {
                    $InputBytes = [System.BitConverter]::GetBytes($InputObject)
                }
                elseif ($InputObject -is [System.IO.FileSystemInfo]) {
                    if ($PSVersionTable.PSVersion -ge [version]'6.0') {
                        $InputBytes = Get-Content $InputObject.FullName -Raw -AsByteStream
                    }
                    else {
                        $InputBytes = Get-Content $InputObject.FullName -Raw -Encoding Byte
                    }
                }
                else {
                    ## Non-Terminating Error
                    $Exception = New-Object ArgumentException -ArgumentList ('Cannot compress input of type {0}.' -f $InputObject.GetType())
                    Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::ParserError) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'CompressDataFailureTypeNotSupported' -TargetObject $InputObject
                }

                if ($null -ne $InputBytes -and $InputBytes.Count -gt 0) {
                    [byte[]] $outBytes = Expand $InputBytes
                    if ($RawBytes) {
                        Write-Output $outBytes -NoEnumerate
                    }
                    else {
                        [string] $outString = ([Text.Encoding]::$Encoding.GetString($outBytes))
                        Write-Output $outString
                    }
                }
            }
        }
    }

    end {
        ## Output captured byte stream from piped input.
        if ($listBytes.Count -gt 0) {
            [byte[]] $outBytes = Expand $listBytes.ToArray()
            if ($RawBytes) {
                Write-Output $outBytes -NoEnumerate
            }
            else {
                [string] $outString = ([Text.Encoding]::$Encoding.GetString($outBytes))
                Write-Output $outString
            }
        }
    }
}
