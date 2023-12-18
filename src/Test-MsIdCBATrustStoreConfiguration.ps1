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
            try {
            if (-not(get-module -Name Microsoft.Graph.Identity.DirectoryManagement)) {
                    import-module Microsoft.Graph.Identity.DirectoryManagement
                }
                if (-not(get-module -Name Microsoft.Graph.Identity.SignIns)) {
                    import-module Microsoft.Graph.Identity.SignIns
                }
            }
            catch {
                Write-Host Microsoft Graph SDK not found. Install the Microwsoft Graph SDK -ForegroundColor Red
                Break
            }
            try {
                $context = Get-MgContext
                if ($null -eq $context) {
                                            $UPN = Read-Host "Enter UserPrincipalName"
                                            $UPNRegex = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
                                            
                                            if ($UPN -match $UPNRegex) 
                                            {
                                                #Write-Host "The UPN '$UPN' is in the correct format."
                                                $AzureEnvs = Get-MgEnvironment
                                                $CloudName = $null
                                                $TenantName = $UPN.Split('@')[1]
                                                $URL = "https://login.microsoftonline.com/$TenantName/v2.0/.well-known/openid-configuration"
                                                $JSON = Invoke-WebRequest -Uri $URL | ConvertFrom-Json
                                                $CloudName = ($AzureEnvs | Where-Object{($_.GraphEndpoint -split "//")[1] -eq  $JSON.msgraph_host}).name
                                                If($CloudName)
                                                {
                                                    Connect-MgGraph -Environment $CloudName -NoWelcome
                                                }else
                                                {
                                                    Write-Error "Unable to determine Azure Cloud Environment. Run Connect-MgGraph prior to this Powershell Cmdlet"
                                                }
                                            }else 
                                            {
                                                Write-Error "The UPN '$UPN' is not in the correct format."
                                            }               
                                        }
                }
            catch {
                Write-Host Unable to Sign-in to MSGraph -ForegroundColor Red
                Break
            }            
                
            
        }

    process {
# Get Org Info
$OrgInfo = Get-MgOrganization

# Get the list of trusted certificate authorities
$trustedCAs = (Get-MgOrganizationCertificateBasedAuthConfiguration -OrganizationId $OrgInfo.Id).CertificateAuthorities

# Check for a single CA 
If($trustedCAs.count -eq 0)
{
    Write-Host "No Certificate Authorities are present in $($OrgInfo.DisplayName - $($OrgInfo.Id))" -ForegroundColor Red
    Break
}

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
    
    If($ca.CertificateRevocationListUrl)
    {
     Write-Host "    CertificateRevocationListUrl Format Validation Test"
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
If(($FullCert | Get-Member).name -contains 'Authority-Key-Identifier')
 {
  If([string]::IsNullOrEmpty($FullCert.'Authority-Key-Identifier')) ##Check for Empty AKI
  {
    If($ca.IsRootAuthority)
        {
         Write-Host "      CA is configured as a Root Authority --> No Parent Issuer expected in store(AKI Present and Empty)"
        }
   Else {
        Write-Host "      CA is not configured as a Root CA and certificate contains empty Authority Key Identifier(AKI) --> This is unexpected" -ForegroundColor Red
        }
  } ## Close Present but Empty AKI 
Else ## Non-Empty AKI
  {
    Write-Host "    Expected Issuer Subject Key Identifier (SKI) : $($FullCert.'Authority-Key-Identifier')"
    If(!$ca.IsRootAuthority) 
        {
         If($FullCert.'Authority-Key-Identifier' -eq $FullCert.'Subject-Key-Identifier')
            {
             Write-Host "      CA Authority Key Identifier (AKI) and Subject Key Identifier(SKI) are the same and Cert is not marked as isRootAuthority --> This is unexpected"
            } 
         Else
            { ## Non-Empty AKI Non-Root
             If($trustedCAs.IssuerSKI -notcontains $FullCert.'Authority-Key-Identifier') 
                {
                 Write-Host "      Certificate issuer $($FullCert.'Authority-Key-Identifier') is not present in the tenant certificate store" -ForegroundColor Red
                }
            Else 
                {
                 Write-Host "      Passed" -ForegroundColor Green
                }
            }
        } ##Close Non Empty NonRoot    
    Else 
        {
         #Non Empty Root
         If($FullCert.'Authority-Key-Identifier' -eq $FullCert.'Subject-Key-Identifier') 
               {
                 Write-Host "      Passed" -ForegroundColor Green
               } 
        elseif([string]::IsNullOrEmpty($FullCert.'Authority-Key-Identifier'))
            ##Check for Empty AKI
               {
                Write-Host "      Passed Certificate issuer is marked as Root and contains empty AKI" -ForegroundColor Green
               }
           Else{
                Write-Host "      Certificate issuer is marked as Root but contains AKI that does not match SKI --> This is unexpected"
               }
    }   
  }##Close Non-Empty AKI
 }## Close with AKI 
 else ## Handle No AKI in Cert at all
     {
        If($ca.IsRootAuthority) 
        {
            Write-Host "      Passed" -ForegroundColor Green
        } 
         Else
        {
            Write-Host "      CA Certificate is not marked as Root and doesnot contain AKI --> This is unexpected"            
        }
     }## Close No AKI

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
    # Check CRL Time Validity
    Write-Host "    CRL Time Validity Test"
    if ($now -lt $crlTU -or $now -gt $crlNU) {
        Write-Host "    CRL for $($cert.Subject) downloaded from $($ca.CertificateRevocationListUrl) is not yet valid or expired" -ForegroundColor Red
    } Else {
        Write-Host "      Passed" -ForegroundColor Green
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
}##Close Process
}## Close Function
#Test-MsIdCBATrustStoreConfiguration
