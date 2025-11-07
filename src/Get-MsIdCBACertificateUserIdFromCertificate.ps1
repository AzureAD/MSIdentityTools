# ------------------------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
# ------------------------------------------------------------------------------

<#
.SYNOPSIS
    Generates an object representing all the values contained in a certificate file that can be used in Entra ID for configuring CertificateUserIDs in Certificate-Based Authentication.

.DESCRIPTION
    Retrieves and returns an object with the properties 'PrincipalName', 'RFC822Name', 'IssuerAndSubject', 'Subject', 'SKI', 'SHA1PublicKey', and 'IssuerAndSerialNumber' from a certificate file for use in CertificateUserIDs configuration in Certificate-Based Authentication, according to the guidelines outlined in the Microsoft documentation for certificate-based authentication

.PARAMETER Path
    The path to the certificate file. The file can be in .cer or .pem format.

.PARAMETER Certificate
    An X509Certificate2 object

.PARAMETER CertificateMapping
    The certificate mapping property to retrieve. Valid values are PrincipalName, RFC822Name, IssuerAndSubject, Subject, SKI, SHA1PublicKey, and IssuerAndSerialNumber.

.EXAMPLE
    PS > Get-MsIdCBACertificateUserIdFromCertificate -Path "C:\path\to\certificate.cer"

    This command retrieves all the possible certificate mappings and returns an object to represent them.

.EXAMPLE
    PS > Get-MsIdCBACertificateUserIdFromCertificate -Certificate $cert

    This command retrieves all the possible certificate mappings and returns an object to represent them.

.EXAMPLE
    PS > Get-MsIdCBACertificateUserIdFromCertificate -Path "C:\path\to\certificate.cer" -CertificateMapping Subject

    This command retrieves and returns the PrincipalName property.

.OUTPUTS
    Returns an object containing the certificateUserIDs that can be used with the given certificate.

    ```
    @{
        PrincipalName = "X509:<PN>bob@woodgrove.com"
        RFC822Name = "X509:<RFC822>user@woodgrove.com"
        IssuerAndSubject = "X509:<I>DC=com,DC=contoso,CN=CONTOSO-DC-CA<S>DC=com,DC=contoso,OU=UserAccounts,CN=mfatest"
        Subject = "X509:<S>DC=com,DC=contoso,OU=UserAccounts,CN=mfatest"
        SKI = "X509:<SKI>aB1cD2eF3gH4iJ5kL6mN7oP8qR"
        SHA1PublicKey = "X509:<SHA1-PUKEY>cD2eF3gH4iJ5kL6mN7oP8qR9sT"
        IssuerAndSerialNumber = "X509:<I>DC=com,DC=contoso,CN=CONTOSO-DC-CA<SR>eF3gH4iJ5kL6mN7oP8qR9sT0uV"
    }
    ```

#>

function Get-MsIdCBACertificateUserIdFromCertificate {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        [Parameter(Mandatory = $false)]
        [ValidateSet("PrincipalName", "RFC822Name", "IssuerAndSubject", "Subject", "SKI", "SHA1PublicKey", "IssuerAndSerialNumber")]
        [string]$CertificateMapping
    )

    function Get-Certificate {
        param (
            [string]$filePath
        )
        if ($filePath.EndsWith(".cer")) {
            return [System.Security.Cryptography.X509Certificates.X509Certificate]::new($filePath)
        } elseif ($filePath.EndsWith(".pem")) {
            $pemContent = Get-Content -Path $filePath -Raw
            $pemContent = $pemContent -replace "-----BEGIN CERTIFICATE-----", ""
            $pemContent = $pemContent -replace "-----END CERTIFICATE-----", ""
            $pemContent = $pemContent -replace  "(\r\n|\n|\r)", ""
            $pemBytes = [Convert]::FromBase64String($pemContent)
            $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate]::new($pemBytes)

            return $certificate
        } else {
            throw "Unsupported certificate format. Please provide a .cer or .pem file."
        }
    }

    function Get-DistinguishedNameAsString {
        param (
            [System.Security.Cryptography.X509Certificates.X500DistinguishedName]$distinguishedName
        )

        $dn = $distinguishedName.Decode([System.Security.Cryptography.X509Certificates.X500DistinguishedNameFlags]::UseNewLines -bor [System.Security.Cryptography.X509Certificates.X500DistinguishedNameFlags]::DoNotUsePlusSign)

        $dn = $dn -replace "(\r\n|\n|\r)", ","
        return $dn.TrimEnd(',')
    }

    function Get-SerialNumberAsLittleEndianHexString {
        param (
            [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert
        )

        $littleEndianSerialNumber = $cert.GetSerialNumber()

        if ($littleEndianSerialNumber.Length -eq 0)
        {
            return ""
        }

        [System.Array]::Reverse($littleEndianSerialNumber)
        $hexString = -join ($littleEndianSerialNumber | ForEach-Object { $_.ToString("x2") })
        return $hexString
    }

    function Get-SubjectKeyIdentifier {
        param (
            [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert
        )
        foreach ($extension in $cert.Extensions) {
            if ($extension.Oid.Value -eq "2.5.29.14") {
                $ski = New-Object System.Security.Cryptography.X509Certificates.X509SubjectKeyIdentifierExtension -ArgumentList $extension, $false
                return $ski.SubjectKeyIdentifier
            }
        }

        return ""
    }

    # Function to generate certificate mapping fields
    function Get-CertificateMappingFields {
        param (
            [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert
        )
        $subject = Get-DistinguishedNameAsString -distinguishedName $cert.SubjectName
        $issuer = Get-DistinguishedNameAsString -distinguishedName $cert.IssuerName
        $serialNumber = Get-SerialNumberAsLittleEndianHexString -cert $cert
        $thumbprint = $cert.Thumbprint
        $principalName = $cert.GetNameInfo([System.Security.Cryptography.X509Certificates.X509NameType]::UpnName, $false)
        $emailName = $cert.GetNameInfo([System.Security.Cryptography.X509Certificates.X509NameType]::EmailName, $false)
        $subjectKeyIdentifier = Get-SubjectKeyIdentifier -cert $cert
        $sha1PublicKey = $cert.GetCertHashString()

        return @{
            "SubjectName" = $subject
            "IssuerName" = $issuer
            "SerialNumber" = $serialNumber
            "Thumbprint" = $thumbprint
            "PrincipalName" = $principalName
            "EmailName" = $emailName
            "SubjectKeyIdentifier" = $subjectKeyIdentifier
            "Sha1PublicKey" = $sha1PublicKey
        }
    }

    function Get-CertificateUserIds {
        param (
            [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert
        )

        $mappingFields = Get-CertificateMappingFields -cert $cert

        $certUserIDs = @{
            "PrincipalName" = ""
            "RFC822Name" = ""
            "IssuerAndSubject" = ""
            "Subject" = ""
            "SKI" = ""
            "SHA1PublicKey" = ""
            "IssuerAndSerialNumber" = ""
        }

        if (-not [string]::IsNullOrWhiteSpace($mappingFields.PrincipalName))
        {
            $certUserIDs.PrincipalName = "X509:<PN>$($mappingFields.PrincipalName)"
        }

        if (-not [string]::IsNullOrWhiteSpace($mappingFields.EmailName))
        {
            $certUserIDs.RFC822Name = "X509:<RFC822>$($mappingFields.EmailName)"
        }

        if ((-not [string]::IsNullOrWhiteSpace($mappingFields.IssuerName)) -and (-not [string]::IsNullOrWhiteSpace($mappingFields.SubjectName)))
        {
            $certUserIDs.IssuerAndSubject = "X509:<I>$($mappingFields.IssuerName)<S>$($mappingFields.SubjectName)"
        }

        if (-not [string]::IsNullOrWhiteSpace($mappingFields.SubjectName))
        {
            $certUserIDs.Subject = "X509:<S>$($mappingFields.SubjectName)"
        }

        if (-not [string]::IsNullOrWhiteSpace($mappingFields.SubjectKeyIdentifier))
        {
            $certUserIDs.SKI = "X509:<SKI>$($mappingFields.SubjectKeyIdentifier)"
        }

        if (-not [string]::IsNullOrWhiteSpace($mappingFields.Sha1PublicKey))
        {
            $certUserIDs.SHA1PublicKey = "X509:<SHA1-PUKEY>$($mappingFields.Sha1PublicKey)"
        }

        if ((-not [string]::IsNullOrWhiteSpace($mappingFields.IssuerName)) -and (-not [string]::IsNullOrWhiteSpace($mappingFields.SerialNumber)))
        {
            $certUserIDs.IssuerAndSerialNumber = "X509:<I>$($mappingFields.IssuerName)<SR>$($mappingFields.SerialNumber)"
        }

        return $certUserIDs
    }

    function Main
    {
        $cert = $Certificate
        if ($null -eq $cert)
        {
            $cert = Get-Certificate -filePath $Path
        }

        $mappings = Get-CertificateUserIds -cert $cert

        if ($CertificateMapping -eq "")
        {
            return $mappings
        }
        else
        {
            $value = $mappings[$CertificateMapping]
            return "$($value)"
        }
    }

    # Call main function
    return Main
}
