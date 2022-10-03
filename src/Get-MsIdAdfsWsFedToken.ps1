<#
.SYNOPSIS
    Initiates a Ws-Fed logon request to and AD FS server to generate log activity and returns the user token.
.DESCRIPTION
    This command will generate log activity on the ADFS server, by requesting a Ws-Fed token using the windows or forms authentication.
.EXAMPLE
    PS C:\>Get-MsIdAdfsWsFedToken urn:federation:MicrosoftOnline -HostName adfs.contoso.com
    Sign in to an application on an AD FS server using logged user credentials using the Ws-Fed protocol.
.EXAMPLE
    PS C:\>$credential = Get-Credential
    PS C:\>Get-MsIdAdfsWsFedToken urn:federation:MicrosoftOnline -HostName adfs.contoso.com
    Sign in  to an application on an AD FS server using credentials provided by the user using the Ws-Fed endpoint and forms based authentication.
.EXAMPLE
    PS C:\>$WsFedIdentifiers = Get-AdfsRelyingPartyTrust | where { $_.WSFedEndpoint -ne $null -and $_.Identifier -notcontains "urn:federation:MicrosoftOnline" } | foreach { $_.Identifier.Item(0) }
    PS C:\>$WsFedIdentifiers | foreach { Get-MsIdAdfsWsFedToken $_ -HostName adfs.contoso.com }
    Get all Ws-Fed relying party trusts from the AD FS server excluding Azure AD and sign in using the logged user credentials.
#>
function Get-MsIdAdfsWsFedToken 
{
  [CmdletBinding()]
  [OutputType([string])]
  param(
    # Enter the application identifier
    [Parameter(Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [string]$WtRealm,
    # Enter host name for the AD FS server
    [Parameter(Mandatory=$true)]
    [string]$HostName,
    # Provide the credential for the user to be signed in
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential
  )

  $login = $null
  $loginFail = ""

  # Defaults to Ws-Fed request
  [System.UriBuilder] $uriAdfs = 'https://{0}/adfs/ls' -f $HostName
  $uriAdfs.Query = ConvertTo-QueryString @{
    'client-request-id' = New-Guid
    wa = 'wsignin1.0'
    wtrealm = $WtRealm
  }  

    
  if ($null -ne $Credential) {
    Write-Warning "Using credentials sends password in clear text over the network!"

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


  if ($null -eq $login) { Write-Error "HTTP request failed for WtRealm ""$($WtRealm)"" and user: $($user). ERROR: $($loginFail)" }
  elseif ($login.StatusCode -ne 200) { Write-Error "HTTP request failed for WtRealm ""$($WtRealm)"" and user: $($user). ERROR: HTTP status $($login.StatusCode)" }
  elseif ($login.InputFields.Count -le 0) {
    Write-Warning "Login failed for WtRealm ""$($WtRealm)"" and user: $($user)" 
  }
  elseif ($login.InputFields[0].outerHTML.Contains("wsignin1.0")) {
    Write-Host "Login sucessful for WtRealm ""$($WtRealm)"" and user: $($user)"
    return $login.Content | Get-ParsedTokenFromResponse -Protocol WsFed
  }
  else { Write-Warning "Login failed for WtRealm ""$($WtRealm)"" and user: $($user)" }

  return
}
