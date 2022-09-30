<#
.SYNOPSIS
    Initiates a Ws-Trust logon request to and AD FS server to generate log activity and returns the user token.
.DESCRIPTION
    This command will generate log activity on the ADFS server, by requesting a Ws-Trust token using the windows transport or user name mixed endpoint.
.EXAMPLE
    PS C:\>Get-MsIdAdfsWsTrustToken urn:federation:MicrosoftOnline -HostName adfs.contoso.com
    Sign in to an application on an AD FS server using logged user credentials using the WindowsTransport endpoint.
.EXAMPLE
    PS C:\>$credential = Get-Credential
    PS C:\>Get-MsIdAdfsWsTrustToken urn:federation:MicrosoftOnline -HostName adfs.contoso.com -Credential $credential
    Sign in  to an application on an AD FS server using credentials provided by the user using the UserNameMixed endpoint.
.EXAMPLE
    PS C:\>$identifiers =  Get-AdfsRelyingPartyTrust | foreach { $_.Identifier.Item(0) }
    PS C:\>$identifiers | foreach { Get-MsIdAdfsWsTrustToken $_ -HostName adfs.contoso.com }
    Get all relying party trusts from the AD FS server and sign in using the logged user credentials.
#>
function Get-MsIdAdfsWsTrustToken 
{
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true,
      HelpMessage = 'Enter the application identifier')]
    [string]$Identifier,
    [Parameter(Mandatory=$true,
      HelpMessage = 'Enter host name for the AD FS server')]
    [string]$HostName,
    [Parameter(Mandatory=$false,
      HelpMessage = 'Provide the credential for the user to be signed in.')]
    [pscredential]$Credential
  )

  $login = $null
  $loginFail = ""

  if ($null -ne $Credential) {
    $user = $Credential.UserName

    [System.UriBuilder] $uriAdfs = 'https://{0}/adfs/services/trust/2005/usernamemixed' -f $HostName

    $wstrustRequest = New-MsIdWsTrustRequest $Identifier -Endpoint $uriAdfs.Uri -Credential $Credential
    try{
      $login = Invoke-WebRequest $uriAdfs.Uri -Method Post -Body $wstrustRequest -ContentType "application/soap+xml" -UseBasicParsing -ErrorAction SilentlyContinue
    }
    catch [System.Net.WebException]{
      $loginFail = $_
    }
  }
  else {
    $user = "$($env:USERDOMAIN)\$($env:UserName)"

    [System.UriBuilder] $uriAdfs = 'https://{0}/adfs/services/trust/2005/windowstransport' -f $HostName

    $wstrustRequest = New-MsIdWsTrustRequest $Identifier -Endpoint $uriAdfs.Uri
    try{
      $login = Invoke-WebRequest $uriAdfs.Uri -Method Post -Body $wstrustRequest -ContentType "application/soap+xml" -UseDefaultCredentials -UseBasicParsing -ErrorAction SilentlyContinue
    }
    catch [System.Net.WebException]{
      $loginFail = $_
    }
  }



  if ($null -eq $login) { Write-Error "HTTP request failed for identifier ""$($identifier)"" and user: $($user). ERROR: $($loginFail)" }
  elseif ($login.StatusCode -ne 200) { Write-Error "HTTP request failed for identifier ""$($identifier)"" and user: $($user). ERROR: HTTP status $($login.StatusCode)" }
  elseif ($login.Headers["Content-Type"].Contains("application/soap+xml")) {
      Write-Host "Login sucessful for identifier ""$($Identifier)"" and user: $($user)"
      return $login.Content
  }
  else { Write-Warning "Login failed for identifier ""$($Identifier)"" and user: $($user)" }

  return
}
