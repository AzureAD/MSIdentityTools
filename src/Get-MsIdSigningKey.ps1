<#
.SYNOPSIS
    Get signing keys used by Azure AD
.EXAMPLE
    PS C:\>Get-MsIdAADSigningKey
    Get common Azure AD signing keys
.EXAMPLE
    PS C:\>Get-MsIdAADSigningKey.ps1 -Tenant <tenandId>
    Get Azure AD signing keys for the given tenant..
.EXAMPLE
    PS C:\>Get-MsIdAADSigningKey.ps1 -Tenant <tenandId> -Latest
    Get the latest Azure AD signing key for the given tenant.
.EXAMPLE
    PS C:\>Get-MsIdSigningKey -DownloadPath C:\temp
    Export the certificates to a folder destination
#>
function Get-MsIdSigningKey{
    Param(
        # Tenant ID
        $Tenant = "common",

        # Cloud environment
        $Environment="prod",

        # Return the latest certificate
        [switch]$Latest,

        # Location to save certificate
        [string]$DownloadPath
    )

    process {

        $authority = "https://login.microsoftonline.com/"
        if($Environment.ToLower() -eq "china"){ $authority = "https://login.chinacloudapi.cn/" }

        $keysUrl = "$authority$Tenant/discovery/keys";
        $keysJson = ConvertFrom-Json (Invoke-WebRequest $keysUrl).Content

        $certs = @()
        foreach ($key in $keysJson.keys) {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($key.x5c)
            $cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @(,$bytes)

            $certs += new-object PSObject -Property @{ 'Kid'=$key.kid; 'Thumbprint'=$cert.Thumbprint; 'NotAfter'=$cert.NotAfter; 'NotBefore'=$cert.NotBefore; 'Cert'=$cert }
        }

        if ($Latest) {
            $certs = $certs | sort -Descending {$_.NotBefore} | Select -First 1
        }

        if ($DownloadPath) {
            foreach ($cert in $certs) {
                $path = Join-Path $DownloadPath ($cert.Thumbprint.ToLower() + ".cer")
                [System.IO.File]::WriteAllBytes($path, $cert.Cert.Export("Cert"));
                Write-Host "Certificate successfully exported to $path"
            }
        }

        Write-Output $certs 
    }

}

$x = Get-MsIdSigningKey