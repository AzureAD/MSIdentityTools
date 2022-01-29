<#
.SYNOPSIS
    Compress data using DEFLATE (RFC 1951) and optionally GZIP file format (RFC 1952).
.DESCRIPTION

.EXAMPLE
    PS C:\>Compress-Data 'A string for compression'
    Compress string using Deflate.
.INPUTS
    System.String
.LINK
    https://github.com/jasoth/Utility.PS
#>
function Compress-Data {
    [CmdletBinding()]
    [Alias('Deflate-Data')]
    [OutputType([byte[]])]
    param (
        # Value to convert
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object] $InputObjects,
        # Output gzip format
        [Parameter(Mandatory = $false)]
        [switch] $GZip,
        # Level of compression
        [Parameter(Mandatory = $false)]
        [System.IO.Compression.CompressionLevel] $CompressionLevel = ([System.IO.Compression.CompressionLevel]::Optimal),
        # Input encoding to use for text strings
        [Parameter (Mandatory = $false)]
        [ValidateSet('Ascii', 'UTF32', 'UTF7', 'UTF8', 'BigEndianUnicode', 'Unicode')]
        [string] $Encoding = 'Default',
        # Set gzip OS header byte to unknown
        [Parameter(Mandatory = $false)]
        [switch] $GZipUnknownOS
    )

    begin {
        function Compress ([byte[]]$InputBytes, [bool]$GZip) {
            try {
                $streamInput = New-Object System.IO.MemoryStream -ArgumentList @($InputBytes, $false)
                try {
                    $streamOutput = New-Object System.IO.MemoryStream
                    try {
                        if ($GZip) {
                            $streamCompression = New-Object System.IO.Compression.GZipStream -ArgumentList $streamOutput, $CompressionLevel, $true
                        }
                        else {
                            $streamCompression = New-Object System.IO.Compression.DeflateStream -ArgumentList $streamOutput, $CompressionLevel, $true
                        }
                        $streamInput.CopyTo($streamCompression)
                    }
                    finally { $streamCompression.Dispose() }
                    if ($GZip) {
                        [void] $streamOutput.Seek(8, [System.IO.SeekOrigin]::Begin)
                        switch ($CompressionLevel) {
                            'Optimal' { $streamOutput.WriteByte(2) }
                            'Fastest' { $streamOutput.WriteByte(4) }
                            Default { $streamOutput.WriteByte(0) }
                        }
                        if ($GZipUnknownOS) { $streamOutput.WriteByte(255) }
                        elseif ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) { $streamOutput.WriteByte(11) }
                        elseif ($IsLinux) { $streamOutput.WriteByte(3) }
                        elseif ($IsMacOS) { $streamOutput.WriteByte(7) }
                        else { $streamOutput.WriteByte(255) }
                    }
                    [byte[]] $OutputBytes = $streamOutput.ToArray()
                }
                finally { $streamOutput.Dispose() }
            }
            finally { $streamInput.Dispose() }

            Write-Output $OutputBytes -NoEnumerate
        }

        ## Create list to capture byte stream from piped input.
        [System.Collections.Generic.List[byte]] $listBytes = New-Object System.Collections.Generic.List[byte]
    }

    process {
        if ($InputObjects -is [byte[]]) {
            Write-Output (Compress $InputObjects -GZip:$GZip) -NoEnumerate
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
                elseif ($InputObject -is [string]) {
                    $InputBytes = [Text.Encoding]::$Encoding.GetBytes($InputObject)
                }
                elseif ($InputObject -is [bool] -or $InputObject -is [char] -or $InputObject -is [single] -or $InputObject -is [double] -or $InputObject -is [int16] -or $InputObject -is [int32] -or $InputObject -is [int64] -or $InputObject -is [uint16] -or $InputObject -is [uint32] -or $InputObject -is [uint64]) {
                    $InputBytes = [System.BitConverter]::GetBytes($InputObject)
                }
                elseif ($InputObject -is [guid]) {
                    $InputBytes = $InputObject.ToByteArray()
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
                    Write-Output (Compress $InputBytes -GZip:$GZip) -NoEnumerate
                }
            }
        }
    }

    end {
        ## Output captured byte stream from piped input.
        if ($listBytes.Count -gt 0) {
            Write-Output (Compress $listBytes.ToArray() -GZip:$GZip) -NoEnumerate
        }
    }
}
