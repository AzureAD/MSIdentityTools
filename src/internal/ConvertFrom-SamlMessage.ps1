<#
.SYNOPSIS
   Convert Saml Message to XML object.
.EXAMPLE
    PS C:\>ConvertFrom-SamlMessage 'Base64String'
    Convert Saml Message to XML object.
.INPUTS
    System.String
.OUTPUTS
    SamlMessage : System.Xml.XmlDocument
#>
function ConvertFrom-SamlMessage {
    [CmdletBinding()]
    [Alias('ConvertFrom-SamlRequest')]
    [Alias('ConvertFrom-SamlResponse')]
    #[OutputType([xml])]
    param (
        # SAML Message
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]] $InputObject
    )

    process {
        foreach ($_InputObject in $InputObject) {
            [byte[]] $bytesInput = $null
            $xmlOutput = New-Object SamlMessage
            try {
                $xmlOutput.LoadXml($_InputObject)
            }
            catch {
                try {
                    $bytesInput = [System.Convert]::FromBase64String($_InputObject)
                }
                catch {
                    $bytesInput = [System.Convert]::FromBase64String([System.Net.WebUtility]::UrlDecode($_InputObject))
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
