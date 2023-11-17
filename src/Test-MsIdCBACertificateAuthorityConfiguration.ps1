<#
.SYNOPSIS
    Test & report for common mis-configuration issues with the Entra ID Certificate Trust Store

.INPUTS
    None
.NOTES
    This Powershell cmdlet require Windows command line utility Certutil. This cmdlet can only be run from Windows device.
    
    Since the CRL Distribution Point (CDP) needs to be accessible to Entra ID. It is best to run this script from outside
    a corporate network on an internet connected Windows device.   
.EXAMPLE
    Test-MsIdCBATrustStoreConfiguration
.LINK
    https://aka.ms/aadcba

#>
function Test-MsIdCBATrustStoreConfiguration {

    begin {
            ## Due to Certutil Dependency will only run on Windows.
            Try
            {
            certutil /? | Out-Null
            }
            Catch
            {
            Write-Host Certutil not found. This cmdlet can only run on Windows -ForegroundColor Red
            Break
            }
        }

    process {
# Get Org Info
$OrgInfo = Get-MgOrganization

# Get the list of trusted certificate authorities
$trustedCAs = (Get-MgOrganizationCertificateBasedAuthConfiguration -OrganizationId $OrgInfo.Id).CertificateAuthorities

# Loop through each trusted CA
$CompletedResult = @()
foreach ($ca in $trustedCAs) {
    $crlDLTime = $null
    $crldump = $Null
    $crlAKI = $Null
    $crlTU = $Null
    $crlNU = $null    

    Write-Host "Processing $($ca.Issuer)"
    ### High Level Check for correctly formatted CDP URL
    Write-Host "    CertificateRevocationListUrl Format Validation Test"
    If($ca.CertificateRevocationListUrl)
    {
    $pattern = '^http:\/\/[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&:/~\+#]*[\w\-\@?^=%&/~\+#])\/[^\/]+\.[^\/]+$'
    $crlURLCheckPass = $false
    if ($ca.CertificateRevocationListUrl -match $pattern) {
        Write-Host "      Passed" -ForegroundColor Green
        $crlURLCheckPass = $true
    } elseif ($ca.CertificateRevocationListUrl -match '^https:\/\/') {
        Write-Host "     HTTPS is not allowed" -ForegroundColor Red
    } else {
        Write-Host "     Invalid CDP URL" -ForegroundColor Red
    }
    If(!$crlURLCheckPass)
    {
     ## THis needs to be corrected before other checks
     Write-Host "     This CA CDP needs to be corrected. Additional checks for this CA are not processed" -ForegroundColor Red
     Continue
    }
    }

    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($ca.Certificate)

    $objresult = New-Object System.Object
    $objresult | Add-Member -type NoteProperty -name NotAfter -value $cert.NotAfter
    $objresult | Add-Member -type NoteProperty -name NotBefore -value $cert.NotBefore
    $objresult | Add-Member -type NoteProperty -name Subject -value $cert.Subject
    $objresult | Add-Member -type NoteProperty -name Issuer -value $cert.Issuer
    $objresult | Add-Member -type NoteProperty -name Thumbprint -value $cert.Thumbprint

    ForEach($Extension in $Cert.Extensions) {
        Switch($Extension.Oid.FriendlyName) {
            "Authority Key Identifier" {$objresult | Add-Member -type NoteProperty -name Authority-Key-Identifier -value ($Extension.Format($false)).trimstart("KeyID=")}
            "Subject Key Identifier"   {$objresult | Add-Member -type NoteProperty -name Subject-Key-Identifier -value $Extension.Format($false)}
        } ##Switch
    }## ForEach Extension

    $FullCert = $objresult
    $CompletedResult += $objresult

    # Check the Time validity of the certificate
    $now = Get-Date
    Write-Host "    Certificate Time Validity Test"
    if ($now -lt $FullCert.NotBefore -or $now -gt $FullCert.NotAfter) {
        Write-Host "    Certificate for $($cert.Subject) is not yet valid or expired" -ForegroundColor Red
        continue
    } Else {
        Write-Host "      Passed" -ForegroundColor Green
    }

    # Download the CRL
    $TempDir = [System.IO.Path]::GetTempPath()
    
    If($ca.CertificateRevocationListUrl) {
       Try {
            $crlDLTime = Measure-Command {Invoke-WebRequest -Uri $ca.CertificateRevocationListUrl -OutFile ($TempDir + "crl.crl")}              
        } Catch {}    

        # Check if the CRL was downloaded successfully
        Write-Host "    CRL Download & Latency Test"
        if ($null -eq $crlDLTime) {
            Write-Host "      Failed to download CRL for $($cert.Subject)" -ForegroundColor Red
            continue
        } Else {     
            if($crlDLTime.TotalSeconds -gt 12) {
                Write-Host "      Slow CRL Download (>12 Seconds) for $($cert.Subject)" -ForegroundColor Red
            } Else {
                Write-Host "      CRL Download successful for $($cert.Subject)" -ForegroundColor Green
            }
        }
    } Else {
        Write-Host $cert.Subject is not configured with a CRL - Entra ID will not perform CRL check for this CA -ForegroundColor Yellow
        Continue
    }   

    ## Check CRL Size
    Write-Host "    CRL Size Test"
    $File = Get-ChildItem ($TempDir + "crl.crl")
    $FileMB = [math]::Round($File.Length/1MB,0)
    if($FileMB -gt 44) {
        Write-Host "      CRL is Large - $($FileMB) MB- Users may see intermittent Sign-in errors due to sizes above 45" MB -ForegroundColor Red
    } Else {
        If($FileMB -lt 1)
        {
         Write-Host "      Passed - CRL is < 1MB" -ForegroundColor Green
        }
        Else
        {
         Write-Host "      Passed - CRL is $($FileMB) MB" -ForegroundColor Green
        }
    }

# Validate CA Cert AKI--> SKI Mapping Logic
Write-Host "    Certificate Trust Chain Test"
If($null -eq $FullCert.'Authority-Key-Identifier') {
    If($ca.IsRootAuthority) {
        Write-Host "      CA is configured as a Root Authority --> No Parent Issuer expected in store"
    } Else {
        Write-Host "      CA is not configured as a Root CA but certificate does not contain Authority Key Identifier(AKI) --> This is unexpected" -ForegroundColor Red
    }
} ## Close Without AKI 
Else {
    Write-Host "    Expected Issuer Subject Key Identifier (SKI) : $($FullCert.'Authority-Key-Identifier')"
    If(!$ca.IsRootAuthority) {
        If($FullCert.'Authority-Key-Identifier' -eq $FullCert.'Subject-Key-Identifier') {
            Write-Host "      CA Authority Key Identifier (AKI) and Subject Key Identifier(SKI) are the same and Cert is not marked as isRootAuthority --> This is unexpected"
        } Else {
            If($trustedCAs.IssuerSKI -notcontains $FullCert.'Authority-Key-Identifier') {
                Write-Host "      Certificate issuer $($FullCert.'Authority-Key-Identifier') is not present in the tenant certificate store" -ForegroundColor Red
            } Else {
                Write-Host "      Passed" -ForegroundColor Green
            }
        }
    } Else {
        Write-Host "      CA is configured as a Root Authority --> No Parent Issuer expected in store"
    }
    }## Close with AKI and the AKI --> SKI Validation Test

    # Dump the CRL file using certutil
    Write-Host "   "Running Certutil commands and parsing output *** Can be Slow for Big CRL *** -ForegroundColor White
    $crldump = certutil -dump ($TempDir + "crl.crl")
    # Check for a Next Publish Date in CRLDump and grab before truncating the output for faster processing
        $i = 0
        $crlNP = $Null
    ForEach($Line in $crldump) {
        If ($Line -match "Next CRL Publish") {
            $crlNP = ($crldump[$i+1]).TrimStart(' ') | get-date
            break
        }
        $i++
    }

    ## Shorted CRLDump output for faster parsing
    $i = 0
    ForEach($Line in $crldump) {
        If ($Line -match "CRL Entries:") {
            $crldump = $crldump[0..$i]
            break
        }
        $i++
    }

    $crlAKI = $crldump -match 'KeyID='
    $crlAKI = $crlAKI -replace '        KeyID=',''
    $crlTU = $crldump -match ' ThisUpdate: '
    $crlTU = $crlTU -replace ' ThisUpdate: ','' | get-Date
    $crlNU = $crldump -match ' NextUpdate: '
    $crlNU = $crlNU -replace ' NextUpdate: ','' | get-Date

    # Verify CRL/CERT AKI Match
    If($crlAKI -ne $FullCert.'Subject-Key-Identifier') {
        # Downloaded CRL AKI does not match expected SKI of CA Certificate
        Write-Host "      CRL Authority Key Identifier(AKI) Mismatch" -ForegroundColor Red
        Write-Host "        CRL AKI      : " $crlAKI -ForegroundColor Red
        Write-Host "        Expected AKI : " $FullCert.'Subject-Key-Identifier' -ForegroundColor Red

        ## See if the CRL downloaded AKI matches other CA in Store
        If($trustedCAs.IssuerSKI -contains $crlAKI) {
            $MatchedCA = @()
            $MatchedCA = $trustedCAs | Where-Object {$crlAKI -eq $_.IssuerSki}
            If($MatchedCA) {
                Write-Host "      Downloaded CRL AKI matches another CA certificate in the trusted store : $($MatchedCA.Issuer)" -ForegroundColor Red
            }
        }
    } Else {
        Write-Host "      " Cert SKI matches CRL AKI -ForegroundColor Green
    }

    # Display CRL Lifetime Information 
    Write-Host "    Additional CRL Information"
    Write-Host "      " CRL was Issued on $crlTU
    If($crlNP)
    {
     Write-Host "      " CRL nextPublish is $crlNP
    }
    Else
    {
     Write-Host "      " CRL does not contain nextPublish date
    }
    Write-Host "      " CRL expires on $crlNU
    $TimeLeft = New-TimeSpan -Start $now -End $crlNU
    Write-Host "      " CRL is valid for $TimeLeft.Days Days $TimeLeft.Hours Hours
    # TODO Verify the CRL signature
}##ForEach CA
    }
}
