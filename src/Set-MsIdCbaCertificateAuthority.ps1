<#
.SYNOPSIS
    Configure certificate authorities for certificate-based authentication
    
.DESCRIPTION
    
    
.EXAMPLE
    PS > $CertificateAuthorities = @'
[
    {
        "Subject":  "CN=DoD Root CA 3, OU=PKI, OU=DoD, O=U.S. Government, C=US",
        "certificate":  "308203733082025BA003020102020101300D06092A864886F70D01010B0500305B310B300906035504061302555331183016060355040A130F552E532E20476F7665726E6D656E74310C300A060355040B1303446F44310C300A060355040B1303504B49311630140603550403130D446F4420526F6F742043412033301E170D3132303332303138343634315A170D3239313233303138343634315A305B310B300906035504061302555331183016060355040A130F552E532E20476F7665726E6D656E74310C300A060355040B1303446F44310C300A060355040B1303504B49311630140603550403130D446F4420526F6F74204341203330820122300D06092A864886F70D01010105000382010F003082010A0282010100A9EC14728AE84B70A3DA100384A6FBA7360D2A3A5216BF30155286054720CFAAA6CD75C4646EEFF16023CB0A6640AEB4C8682A0051684937E959324D95BC4327E9408D3A10CE14BC4318A1F9DECCE78576735E181A235BBD3F1FF2ED8D19CC03D140A48FA720024C275A7936F6A337218E005A0616CAD355966F3129BB720ECBE24851F2D437A435D66FEE17B3B106AB0B1986E8236D311B287865C5DE6252BCC17DEBEEA05D5404FBB2CB2BB2235491824CF0BFBA74403B0C044580675CC5EBA257C31A7F0A2DBD7FB9DCC199B0C807E40C8636943A252FF27DE6973C1B94B4975906C93AE40BD9EAE9FC3B73346FFDE798E4F3A1C2905F1CF53F2ED719D37F0203010001A3423040301D0603551D0E041604146C8A94A277B180721D817A16AAF2DCCE66EE45C0300E0603551D0F0101FF040403020186300F0603551D130101FF040530030101FF300D06092A864886F70D01010B050003820101009F71A4C0B696D28043A048E91F7604F9C53CAD661858639BC3B6E8688A855A426612B4D2E68B887F87F498F5A8C609C91FF02C1FEC82B8F4A54738C1332BDF4C7E9ABE0B0BB1CB0F7C502810CF8A8DA2E9BAAC86D7D4B1935F228F9605B44E0C75917DD3F2E794C29414764F8F0CAB1087583285077586120B5EEA53B40AC84C84921FEBE841863CBAF44E414AD16C584741C3865AF2EEE9F2982782EA2E36D6F8065E82F1A052934409BAD2A9195A58A3A85D206D4F64F830871B90134881CDCA90C70DC1D4983F8EF20E576833128E9909B1F0E4F610F436F249BDEAA338C8564123839ADFA11B357CEB3F41B3F56F4B3A5EAE6F937698D2F1999D45C48E72",
        "isRootAuthority":  true,
        "certificateRevocationListUrl":  "http://crl.disa.mil/crl/DODROOTCA3.crl"
    },
    {
        "Subject":  "CN=DoD Root CA 4, OU=PKI, OU=DoD, O=U.S. Government, C=US",
        "certificate":  "308201EB3082018FA003020102020101300C06082A8648CE3D0403020500305B310B300906035504061302555331183016060355040A130F552E532E20476F7665726E6D656E74310C300A060355040B1303446F44310C300A060355040B1303504B49311630140603550403130D446F4420526F6F742043412034301E170D3132303733303139343832335A170D3332303732353139343832335A305B310B300906035504061302555331183016060355040A130F552E532E20476F7665726E6D656E74310C300A060355040B1303446F44310C300A060355040B1303504B49311630140603550403130D446F4420526F6F7420434120343059301306072A8648CE3D020106082A8648CE3D0301070342000476C8D843CB0F07D22C0F2AD038F182CD4255E7DC1D5A80B708914B54D64FB2668534968D2E3EF4E04A917CCCCD869F11E052A16682C6CB9023EC5F5FF5F03C45A3423040301D0603551D0E04160414BDC1B96B4DF41DEC3090BF6273C08433F2712485300E0603551D0F0101FF040403020186300F0603551D130101FF040530030101FF300C06082A8648CE3D04030205000348003045022100E8618AF7DCAA09A507D2449E82035A445347842399CF5CD3DE4A5ED6BB3535460220760FB8C47C16357FD412ED883D80116B64074C4565DF53AE5F01EDF143D2F5B7",
        "isRootAuthority":  true,
        "certificateRevocationListUrl":  "http://crl.disa.mil/crl/DODROOTCA4.crl"
    }
]
'@
    PS > Set-MsIdCbaCertificateAuthority $CertificateAuthorities

    Configure certificate authorities for certificate-based authentication

.INPUTS
    System.String

#>
function Set-MsIdCbaCertificateAuthority {
    [CmdletBinding()]
    param (
        # Root and intermediate certificates
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = 'Certificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2[]] $Certificate,
        # CertificateAuthority Configuration or File Path
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'InputObject')]
        [object] $InputObject,
        # 
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $CertificateRevocationListUrl,
        # 
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $IsRootAuthority
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'Get-MgOrganization', 'Get-MgOrganizationCertificateBasedAuthConfiguration' -MinimumVersion 1.9.2 -RequireListPermissions -ErrorVariable CriticalError)) { return }
    }

    process {
        if ($CriticalError) { return }

        [System.Collections.Generic.List[pscustomobject]] $CertificateAuthorities = New-Object System.Collections.Generic.List[pscustomobject]
        if ($PSCmdlet.ParameterSetName -eq 'InputObject') {
            $Certificate = New-Object 'System.Collections.Generic.List[System.Security.Cryptography.X509Certificates.X509Certificate2]'
            ## Generate configuration
            if ($InputObject -is [string]) {
                switch -regex ($InputObject) {
                    '^\w{3,5}://.*\.jsonc?$' {
                        #json uri input
                        $CertificateAuthorities = Invoke-RestMethod $InputObject
                    }
                    '.jsonc?$' {
                        #json file input
                        $CertificateAuthorities = Get-Content $InputObject -Raw | ConvertFrom-Json
                    }
                    '^[[{][\S\s]*?"certificate":[\S\s]*[}\]]$' {
                        #json input
                        $CertificateAuthorities = ConvertFrom-Json $InputObject
                    }
                    default {
                        # check for raw certificate
                        foreach ($obj in $InputObject) {
                            switch -regex ($obj) {
                                '^[A-Za-z0-9+/\r\n]+={0,2}$' {
                                    Get-X509Certificate $obj
                                }
                                '.*\.(cer)$' {
                                    $Certificate = Get-Item $obj | Get-X509Certificate
                                }
                                default {
                                    # assume binary or error?
                                }
                            }
                            $Certificate.Add($Certificate)
                        }
                    }
                }
                ## Parse certificate
                foreach ($CertificateAuthority in $CertificateAuthorities) {
                    $CertificateAuthority.certificate = $CertificateAuthority.certificate | Get-X509Certificate
                }
            }
        }

        foreach ($_Certificate in $Certificate) {
            $CertificateAuthority = @{
                certificate                  = $_Certificate
                isRootAuthority              = $null
                certificateRevocationListUrl = $null
            }
            $CertificateAuthorities.Add($CertificateAuthority)
        }

        #Get existing certificate configuration
        $OrganizationId = Get-MgOrganization -Select id | Select-Object -ExpandProperty Id
        #$CbaConfiguration = Get-MgOrganizationCertificateBasedAuthConfiguration -OrganizationId $OrganizationId

        ## Build payload
        $certificateBasedAuthConfiguration = @{
            certificateAuthorities = New-Object System.Collections.Generic.List[pscustomobject]
        }
        foreach ($CertificateAuthority in $CertificateAuthorities) {
            $IsRootAuthorityAuto = $CertificateAuthority.certificate.Subject -eq $CertificateAuthority.certificate.Issuer

            $CA = @{
                certificate                  = ConvertTo-Base64String $CertificateAuthority.certificate.GetRawCertData()
                isRootAuthority              = if ($PSBoundParameters.ContainsKey('IsRootAuthority')) { [bool]$IsRootAuthority } else { Skip-NullValue $CertificateAuthority.isRootAuthority, $IsRootAuthorityAuto }
                certificateRevocationListUrl = Skip-NullValue $CertificateRevocationListUrl, $CertificateAuthority.certificateRevocationListUrl -SkipEmpty
            }
            $certificateBasedAuthConfiguration.certificateAuthorities.Add($CA)
        }

        ## Replace list of CAs in Azure AD
        Invoke-MgGraphRequest -Method POST "v1.0/organization/$OrganizationId/certificateBasedAuthConfiguration" -Body (ConvertTo-Json $certificateBasedAuthConfiguration -Depth 5)

        ## ToDo: Add logic to keep existing certificate authorities? Rather than overwrite everything with new config?
    }
}
