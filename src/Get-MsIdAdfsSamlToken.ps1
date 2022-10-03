<#
.SYNOPSIS
    Initiates a SAML logon request to and AD FS server to generate log activity and returns the user token.
.DESCRIPTION
    This command will generate log activity on the ADFS server, by requesting a SAML token using Windows or forms authentication.
.EXAMPLE
    PS > Get-MsIdAdfsSamlToken urn:federation:MicrosoftOnline -HostName adfs.contoso.com

    Sign in to an application on an AD FS server using logged user credentials using the SAML protocol.

.EXAMPLE
    PS > $credential = Get-Credential
    PS > Get-MsIdAdfsSamlToken urn:federation:MicrosoftOnline -HostName adfs.contoso.com

    Sign in  to an application on an AD FS server using credentials provided by the user using the SAML endpoint and forms based authentication.

.EXAMPLE
    PS > $SamlIdentifiers =  Get-AdfsRelyingPartyTrust | where { $_.WSFedEndpoint -eq $null } | foreach { $_.Identifier.Item(0) }
    PS > $SamlIdentifiers | foreach { Get-MsIdAdfsSamlToken $_ -HostName adfs.contoso.com }
    
    Get all SAML relying party trusts from the AD FS server and sign in using the logged user credentials.

#>
function Get-MsIdAdfsSamlToken 
{
  [CmdletBinding()]
  [OutputType([string])]
  param(
    # Application identifier
    [Parameter(Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [string]$Issuer,
    # Enter host name for the AD FS server
    [Parameter(Mandatory=$true)]
    [string]$HostName,
    # Provide the credential for the user to be signed in
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential
  )

  if ($null -ne $Credential) 
  {
    Write-Warning "Using credentials sends password in clear text over the network!"
  }


  $login = $null
  $loginFail = ""

  $EncodedSamlRequest = New-MsIdSamlRequest -Issuer $Issuer -DeflateAndEncode

  [System.UriBuilder] $uriAdfs = 'https://{0}/adfs/ls' -f $HostName
  $uriAdfs.Query = ConvertTo-QueryString @{
      SAMLRequest = $EncodedSamlRequest
  }  

  if ($null -ne $Credential) {
    $user = $Credential.UserName
    $form = New-AdfsLoginFormFields -Credential $Credential
    try{
      $login = Invoke-WebRequest -Uri $uriAdfs.Uri -Method POST -Body $form -UseBasicParsing -ErrorAction SilentlyContinue
    }
    catch [System.Net.WebException]{
      $loginFail = $_
    }
  }
  else {
    $userAgent = 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT; Windows NT 10.0; en-US)'
    $user = "$($env:USERDOMAIN)\$($env:UserName)"
    try{
      $login = Invoke-WebRequest -Uri $uriAdfs.Uri -UserAgent $userAgent -UseDefaultCredentials -UseBasicParsing -ErrorAction SilentlyContinue
    }
    catch [System.Net.WebException]{
      $loginFail = $_
    }
  }



  if ($null -eq $login) { Write-Error "HTTP request failed for issuer ""$($Issuer)"" and user: $($user). ERROR: $($loginFail)" }
  elseif ($login.StatusCode -ne 200) { Write-Error "HTTP request failed for issuer ""$($Issuer)"" and user: $($user). ERROR: HTTP status $($login.StatusCode)" }
  elseif ($login.InputFields.Count -le 0) {
    Write-Warning "Login failed for issuer ""$($Issuer)"" and user: $($user)"
  }
  elseif ($login.InputFields[0].outerHTML.Contains("SAMLResponse")) {
    Write-Host "Login sucessful for issuer ""$($Issuer)"" and user: $($user)"
    return $login.Content | Get-ParsedTokenFromResponse -Protocol SAML
  }
  else { Write-Warning "Login failed for issuer ""$($Issuer)"" and user: $($user)" }

  return
}
