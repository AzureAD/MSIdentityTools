<#
.SYNOPSIS
    Validate the digital signature for JSON Web Signature.
.EXAMPLE
    PS C:\>Confirm-JsonWebSignature $Base64JwsString -SigningCertificate $SigningCertificate
    Validate the JWS string was signed by provided certificate.
.INPUTS
    System.String
#>
function Confirm-JsonWebSignature {
    [CmdletBinding()]
    [Alias('Confirm-Jws')]
    [OutputType([bool])]
    param (
        # JSON Web Signature (JWS)
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string[]] $InputObjects,
        # Certificate used to sign the data
        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $SigningCertificate
    )

    process {
        foreach ($InputObject in $InputObjects) {
            $Jws = ConvertFrom-JsonWebSignature $InputObject
            $JwsData = $InputObject.Substring(0,$InputObject.LastIndexOf('.'))
            [Security.Cryptography.HashAlgorithmName] $HashAlgorithm = [Security.Cryptography.HashAlgorithmName]::"SHA$($Jws.Header.alg.Substring(2,3))"
            switch ($Jws.Header.alg.Substring(0,2)) {
                'RS' {
                    $RSAKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPublicKey($SigningCertificate)
                    [bool] $Result = $RSAKey.VerifyData([System.Text.Encoding]::UTF8.GetBytes($JwsData),$Jws.Signature,$HashAlgorithm,[Security.Cryptography.RSASignaturePadding]::Pkcs1)
                }
                'PS' {
                    $RSAKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPublicKey($SigningCertificate)
                    [bool] $Result = $RSAKey.VerifyData([System.Text.Encoding]::UTF8.GetBytes($JwsData),$Jws.Signature,$HashAlgorithm,[Security.Cryptography.RSASignaturePadding]::Pss)
                }
                'ES' {
                    $ECDsaKey = [System.Security.Cryptography.X509Certificates.ECDsaCertificateExtensions]::GetECDsaPublicKey($SigningCertificate)
                    [bool] $Result = $ECDsaKey.VerifyData([System.Text.Encoding]::UTF8.GetBytes($JwsData),$Jws.Signature,$HashAlgorithm)
                }
            }
            Write-Output $Result
        }
    }
}
