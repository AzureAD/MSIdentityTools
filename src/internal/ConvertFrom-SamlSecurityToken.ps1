<#
.SYNOPSIS
   Convert Saml Security Token structure to PowerShell object.
.EXAMPLE
    PS C:\>ConvertFrom-SamlSecurityToken 'Base64String'
    Convert Saml Security Token to XML object.
.INPUTS
    System.String
#>
function ConvertFrom-SamlSecurityToken {
    [CmdletBinding()]
    [Alias('ConvertFrom-SamlRequest')]
    [Alias('ConvertFrom-SamlResponse')]
    [OutputType([xml])]
    param (
        # SAML Security Token
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]] $InputObjects
        # Encoding to use for text strings
        #[Parameter (Mandatory = $false)]
        #[ValidateSet('Ascii', 'UTF32', 'UTF7', 'UTF8', 'BigEndianUnicode', 'Unicode')]
        #[string] $Encoding = 'Default'
    )

    process {
        foreach ($InputObject in $InputObjects) {
            [byte[]] $bytesInput = $null
            $xmlOutput = New-Object xml
            try {
                $xmlOutput.LoadXml($InputObject)
            }
            catch {
                try {
                    $bytesInput = [System.Convert]::FromBase64String($InputObject)
                }
                catch {
                    $bytesInput = [System.Convert]::FromBase64String([System.Net.WebUtility]::UrlDecode($InputObject))
                }
            }
            if ($bytesInput) {
                try {
                    $streamInput = New-Object System.IO.MemoryStream -ArgumentList @($bytesInput, $false)
                    try {
                        $xmlOutput.Load($streamInput)
                    }
                    catch {
                        $streamInput = New-Object System.IO.MemoryStream -ArgumentList @($bytesInput, $false)
                        try {
                            $streamOutput = New-Object System.IO.MemoryStream
                            try {
                                [System.IO.Compression.DeflateStream] $streamCompression = New-Object System.IO.Compression.DeflateStream -ArgumentList $streamInput, ([System.IO.Compression.CompressionMode]::Decompress), $true
                                $streamCompression.CopyTo($streamOutput)
                            }
                            finally { $streamCompression.Dispose() }
                            $streamOutput.Position = 0
                            $xmlOutput.Load($streamOutput)
                            #[string] $strOutput = ([Text.Encoding]::$Encoding.GetString($streamOutput.ToArray()))
                            #$xmlOutput.LoadXml($strOutput)
                        }
                        finally { $streamOutput.Dispose() }
                    }
                }
                finally { $streamInput.Dispose() }
            }

            Write-Output $xmlOutput
        }
    }
}
