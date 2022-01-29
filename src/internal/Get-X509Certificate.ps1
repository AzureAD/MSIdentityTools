<#
.SYNOPSIS
    Get certificate object for X509 certificate.
.DESCRIPTION
    Get certificate object for X509 certificate.
.EXAMPLE
    PS C:\>[byte[]] $DERCert = @(48,130,4,18,48,130,2,250,160,3,2,1,2,2,15,0,193,0,139,60,60,136,17,209,62,246,99,236,223,64,48,13,6,9,42,134,72,134,247,13,1,1,4,5,0,48,112,49,43,48,41,6,3,85,4,11,19,34,67,111,112,121,114,105,103,104,116,32,40,99,41,32,49,57,57,55,32,77,105,99,114,111,115,111,102,116,32,67,111,114,112,46,49,30,48,28,6,3,85,4,11,19,21,77,105,99,114,111,115,111,102,116,32,67,111,114,112,111,114,97,116,105,111,110,49,33,48,31,6,3,85,4,3,19,24,77,105,99,114,111,115,111,102,116,32,82,111,111,116,32,65,117,116,104,111,114,105,116,121,48,30,23,13,57,55,48,49,49,48,48,55,48,48,48,48,90,23,13,50,48,49,50,51,49,48,55,48,48,48,48,90,48,112,49,43,48,41,6,3,85,4,11,19,34,67,111,112,121,114,105,103,104,116,32,40,99,41,32,49,57,57,55,32,77,105,99,114,111,115,111,102,116,32,67,111,114,112,46,49,30,48,28,6,3,85,4,11,19,21,77,105,99,114,111,115,111,102,116,32,67,111,114,112,111,114,97,116,105,111,110,49,33,48,31,6,3,85,4,3,19,24,77,105,99,114,111,115,111,102,116,32,82,111,111,116,32,65,117,116,104,111,114,105,116,121,48,130,1,34,48,13,6,9,42,134,72,134,247,13,1,1,1,5,0,3,130,1,15,0,48,130,1,10,2,130,1,1,0,169,2,189,193,112,230,59,242,78,27,40,159,151,120,94,48,234,162,169,141,37,95,248,254,149,76,163,183,254,157,162,32,62,124,81,162,155,162,143,96,50,107,209,66,100,121,238,172,118,201,84,218,242,235,156,134,28,143,159,132,102,179,197,107,122,98,35,214,29,60,222,15,1,146,232,150,196,191,45,102,154,154,104,38,153,208,58,44,191,12,181,88,38,193,70,231,10,62,56,150,44,169,40,57,168,236,73,131,66,227,132,15,187,154,108,85,97,172,130,124,161,96,45,119,76,233,153,180,100,59,154,80,28,49,8,36,20,159,169,231,145,43,24,230,61,152,99,20,96,88,5,101,159,29,55,82,135,247,167,239,148,2,198,27,211,191,85,69,179,137,128,191,58,236,84,148,78,174,253,167,122,109,116,78,175,24,204,150,9,40,33,0,87,144,96,105,55,187,75,18,7,60,86,255,91,251,164,102,10,8,166,210,129,86,87,239,182,59,94,22,129,119,4,218,246,190,174,128,149,254,176,205,127,214,167,26,114,92,60,202,188,240,8,163,34,48,179,6,133,201,179,32,119,19,133,223,2,3,1,0,1,163,129,168,48,129,165,48,129,162,6,3,85,29,1,4,129,154,48,129,151,128,16,91,208,112,239,105,114,158,35,81,126,20,178,77,142,255,203,161,114,48,112,49,43,48,41,6,3,85,4,11,19,34,67,111,112,121,114,105,103,104,116,32,40,99,41,32,49,57,57,55,32,77,105,99,114,111,115,111,102,116,32,67,111,114,112,46,49,30,48,28,6,3,85,4,11,19,21,77,105,99,114,111,115,111,102,116,32,67,111,114,112,111,114,97,116,105,111,110,49,33,48,31,6,3,85,4,3,19,24,77,105,99,114,111,115,111,102,116,32,82,111,111,116,32,65,117,116,104,111,114,105,116,121,130,15,0,193,0,139,60,60,136,17,209,62,246,99,236,223,64,48,13,6,9,42,134,72,134,247,13,1,1,4,5,0,3,130,1,1,0,149,232,11,192,141,243,151,24,53,237,184,1,36,216,119,17,243,92,96,50,159,158,11,203,62,5,145,136,143,201,58,230,33,242,240,87,147,44,181,160,71,200,98,239,252,215,204,59,59,90,169,54,84,105,254,36,109,63,201,204,170,222,5,124,221,49,141,61,159,16,112,106,187,254,18,79,24,105,192,252,208,67,227,17,90,32,79,234,98,123,175,170,25,200,43,55,37,45,190,101,161,18,138,37,15,99,163,247,84,28,249,33,201,214,21,243,82,172,110,67,50,7,253,130,23,248,229,103,108,13,81,246,189,241,82,199,189,231,196,48,252,32,49,9,136,29,149,41,26,77,213,29,2,165,241,128,224,3,180,91,244,177,221,200,87,238,101,73,199,82,84,182,180,3,40,18,255,144,214,240,8,143,126,184,151,197,171,55,44,228,122,228,168,119,227,118,160,0,208,106,63,193,210,54,138,224,65,18,168,53,106,27,106,219,53,225,212,28,4,228,168,69,4,200,90,51,56,110,77,28,13,98,183,10,162,140,211,213,84,63,70,205,28,85,166,112,219,18,58,135,147,117,159,167,210,160)
    PS C:\>Get-X509Certificate $DERCert -Verbose
    Get certificate details from binary (DER) encoded X509 certificate.
.EXAMPLE
    PS C:\>[string] $Base64Cert = 'MIIEEjCCAvqgAwIBAgIPAMEAizw8iBHRPvZj7N9AMA0GCSqGSIb3DQEBBAUAMHAxKzApBgNVBAsTIkNvcHlyaWdodCAoYykgMTk5NyBNaWNyb3NvZnQgQ29ycC4xHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWljcm9zb2Z0IFJvb3QgQXV0aG9yaXR5MB4XDTk3MDExMDA3MDAwMFoXDTIwMTIzMTA3MDAwMFowcDErMCkGA1UECxMiQ29weXJpZ2h0IChjKSAxOTk3IE1pY3Jvc29mdCBDb3JwLjEeMBwGA1UECxMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNyb3NvZnQgUm9vdCBBdXRob3JpdHkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCpAr3BcOY78k4bKJ+XeF4w6qKpjSVf+P6VTKO3/p2iID58UaKboo9gMmvRQmR57qx2yVTa8uuchhyPn4Rms8VremIj1h083g8BkuiWxL8tZpqaaCaZ0Dosvwy1WCbBRucKPjiWLKkoOajsSYNC44QPu5psVWGsgnyhYC13TOmZtGQ7mlAcMQgkFJ+p55ErGOY9mGMUYFgFZZ8dN1KH96fvlALGG9O/VUWziYC/OuxUlE6u/ad6bXROrxjMlgkoIQBXkGBpN7tLEgc8Vv9b+6RmCgim0oFWV++2O14WgXcE2va+roCV/rDNf9anGnJcPMq88AijIjCzBoXJsyB3E4XfAgMBAAGjgagwgaUwgaIGA1UdAQSBmjCBl4AQW9Bw72lyniNRfhSyTY7/y6FyMHAxKzApBgNVBAsTIkNvcHlyaWdodCAoYykgMTk5NyBNaWNyb3NvZnQgQ29ycC4xHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWljcm9zb2Z0IFJvb3QgQXV0aG9yaXR5gg8AwQCLPDyIEdE+9mPs30AwDQYJKoZIhvcNAQEEBQADggEBAJXoC8CN85cYNe24ASTYdxHzXGAyn54Lyz4FkYiPyTrmIfLwV5MstaBHyGLv/NfMOztaqTZUaf4kbT/JzKreBXzdMY09nxBwarv+Ek8YacD80EPjEVogT+pie6+qGcgrNyUtvmWhEoolD2Oj91Qc+SHJ1hXzUqxuQzIH/YIX+OVnbA1R9r3xUse958Qw/CAxCYgdlSkaTdUdAqXxgOADtFv0sd3IV+5lScdSVLa0AygS/5DW8AiPfriXxas3LOR65Kh343agANBqP8HSNorgQRKoNWobats14dQcBOSoRQTIWjM4bk0cDWK3CqKM09VUP0bNHFWmcNsSOoeTdZ+n0qA='
    PS C:\>$Base64Cert | Get-X509Certificate -Verbose
    Get certificate details from Base64 encoded X509 certificate.
.EXAMPLE
    PS C:\>Get-Item "certificateFile.cer" | Get-X509Certificate
    Get certificate details from .cer file.
.INPUTS
    System.Object
.LINK
    https://github.com/jasoth/Utility.PS
#>
function Get-X509Certificate {
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2], [System.Security.Cryptography.X509Certificates.X509Certificate2Collection])]
    param (
        # X.509 certificate that is binary (DER) encoded or Base64-encoded
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [object] $InputObjects,
        # Only return the end-entity certificate
        [Parameter(Mandatory = $false)]
        [switch] $EndEntityCertificateOnly
    )

    begin {
        ## Create list to capture byte stream from piped input.
        [System.Collections.Generic.List[byte]] $listBytes = New-Object System.Collections.Generic.List[byte]

        function Transform ([byte[]]$InputBytes) {
            $X509CertificateCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
            $X509CertificateCollection.Import($InputBytes, $null, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet)
            Write-Output $X509CertificateCollection -NoEnumerate
        }
    }

    process {
        if ($InputObjects -is [byte[]]) {
            $X509CertificateCollection = Transform $InputObjects
            if ($EndEntityCertificateOnly) { Write-Output $X509CertificateCollection[-1] }
            else { Write-Output $X509CertificateCollection }
        }
        else {
            foreach ($InputObject in $InputObjects) {
                [byte[]] $inputBytes = $null
                if ($InputObject -is [byte]) {
                    ## Populate list with byte stream from piped input.
                    if ($listBytes.Count -eq 0) {
                        Write-Verbose 'Creating byte array from byte stream.'
                        Write-Warning ('For better performance when piping a single byte array, use "Write-Output $byteArray -NoEnumerate | {0}".' -f $MyInvocation.MyCommand)
                    }
                    $listBytes.Add($InputObject)
                }
                elseif ($InputObject -is [byte[]]) {
                    $inputBytes = $InputObject
                }
                elseif ($InputObject -is [SecureString]) {
                    Write-Verbose 'Decrypting SecureString and decoding Base64 string to byte array.'
                    if ($PSVersionTable.PSVersion -ge [version]'7.0') {
                        $inputBytes = [System.Convert]::FromBase64String((ConvertFrom-SecureString $InputObject -AsPlainText))
                    }
                    else {
                        $inputBytes = [System.Convert]::FromBase64String((ConvertFrom-SecureStringAsPlainText $InputObject -Force))
                    }
                }
                elseif ($InputObject -is [string]) {
                    Write-Verbose 'Decoding Base64 string to byte array.'
                    $inputBytes = [System.Convert]::FromBase64String($InputObject)
                }
                elseif ($InputObject -is [System.IO.FileSystemInfo]) {
                    Write-Verbose 'Decoding file content to byte array.'
                    if ($PSVersionTable.PSVersion -ge [version]'6.0') {
                        $inputBytes = Get-Content $InputObject.FullName -Raw -AsByteStream
                    }
                    else {
                        $inputBytes = Get-Content $InputObject.FullName -Raw -Encoding Byte
                    }
                }
                else {
                    # Otherwise, write a terminating error message indicating that input object type is not supported.
                    $errorMessage = 'Cannot convert input of type {0} to X.509 certificate.' -f $InputObject.GetType()
                    Write-Error -Message $errorMessage -Category ([System.Management.Automation.ErrorCategory]::ParserError) -ErrorId 'GetX509CertificateFailureTypeNotSupported' -ErrorAction Stop
                }

                ## Only write output if the input is not a byte stream.
                if ($listBytes.Count -eq 0) {
                    $X509CertificateCollection = Transform $inputBytes
                    if ($EndEntityCertificateOnly) { Write-Output $X509CertificateCollection[-1] }
                    else { Write-Output $X509CertificateCollection }
                }
            }
        }
    }

    end {
        ## Output captured byte stream from piped input.
        if ($listBytes.Count -gt 0) {
            $X509CertificateCollection = Transform $listBytes
            if ($EndEntityCertificateOnly) { Write-Output $X509CertificateCollection[-1] }
            else { Write-Output $X509CertificateCollection }
        }
    }
}
