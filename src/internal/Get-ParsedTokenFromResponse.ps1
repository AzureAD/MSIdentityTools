<#
.SYNOPSIS
    Parses token from response as plain text string.
.EXAMPLE
    PS C:\>Get-ParsedTokenFromResponse $response
    Parses token from $response as plain text string.
#>
function Get-ParsedTokenFromResponse {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # HTTP response
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string] $HttpResponse,
        [Parameter(Mandatory=$true, Position = 1)]
        # Protocol SAML or WsFed
        [ValidateSet("SAML", "WsFed")]
        [string]$Protocol
  
    )

    $token = ""

    if ($Protocol -eq "SAML") {
        # <input type="hidden" name="SAMLResponse" value="   ...   " />
        if($HttpResponse -match '<input type=\"hidden\" name=\"SAMLResponse\" value=\"(.+)\" \/><noscript>') {
            $token = $Matches[1] | ConvertFrom-Base64String
        }
    }
    else {
        # <input type="hidden" name="wresult" value="   ...   " />
        if($HttpResponse -match '<input type=\"hidden\" name=\"wresult\" value=\"(.+)\" \/><noscript>') {
            [Reflection.Assembly]::LoadWithPartialName('System.Web') | Out-Null
            $token = [System.Web.HttpUtility]::HtmlDecode($Matches[1])
        }
    }


    return $token
}