<#
.SYNOPSIS
    Create a WS-Trust request.
.EXAMPLE
    PS > New-MsIdWsTrustRequest urn:federation:MicrosoftOnline -Endpoint https://adfs.contoso.com/adfs/services/trust/2005/windowstransport

    Create a Ws-Trust request for the application urn:federation:MicrosoftOnline.

#>
function New-MsIdWsTrustRequest {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # Application identifier
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string] $Identifier,
        # Host name for the AD FS server
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,
        # Credential for the user to be signed in
        [Parameter(Mandatory=$false)]
        [pscredential]$Credential
    )

    if ($Credential -ne $null)
    {
        Write-Warning "Using credentials sends password in clear text over the network!"
      
        $username = $Credential.UserName
        $password = ConvertFrom-SecureStringAsPlainText $Credential.Password -Force
        $request = [String]::Format(
            '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://www.w3.org/2005/08/addressing" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><s:Header><a:Action s:mustUnderstand="1">http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</a:Action><a:ReplyTo><a:Address>http://www.w3.org/2005/08/addressing/anonymous</a:Address></a:ReplyTo><a:To s:mustUnderstand="1">{0}</a:To><o:Security s:mustUnderstand="1" xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"><o:UsernameToken u:Id="uuid-52bba51d-e0c7-4bb1-8c99-6f97220eceba-5"><o:Username>{1}</o:Username><o:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">{2}</o:Password></o:UsernameToken></o:Security></s:Header><s:Body><t:RequestSecurityToken xmlns:t="http://schemas.xmlsoap.org/ws/2005/02/trust"><wsp:AppliesTo xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy"><a:EndpointReference><a:Address>{3}</a:Address></a:EndpointReference></wsp:AppliesTo><t:KeySize>0</t:KeySize><t:KeyType>http://schemas.xmlsoap.org/ws/2005/05/identity/NoProofKey</t:KeyType><t:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</t:RequestType><t:TokenType>http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV2.0</t:TokenType></t:RequestSecurityToken></s:Body></s:Envelope>', `
                $Endpoint,
                $username,
                $password,
                $Identifier)
    }
    else
    {
        $request = [String]::Format(
            '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://www.w3.org/2005/08/addressing" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><s:Header><a:Action s:mustUnderstand="1">http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</a:Action><a:ReplyTo><a:Address>http://www.w3.org/2005/08/addressing/anonymous</a:Address></a:ReplyTo><a:To s:mustUnderstand="1">{0}</a:To></s:Header><s:Body><t:RequestSecurityToken xmlns:t="http://schemas.xmlsoap.org/ws/2005/02/trust"><wsp:AppliesTo xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy"><a:EndpointReference><a:Address>{1}</a:Address></a:EndpointReference></wsp:AppliesTo><t:KeySize>0</t:KeySize><t:KeyType>http://schemas.xmlsoap.org/ws/2005/05/identity/NoProofKey</t:KeyType><t:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</t:RequestType><t:TokenType>http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV2.0</t:TokenType></t:RequestSecurityToken></s:Body></s:Envelope>', `
                $Endpoint,
                $Identifier)
    }

    return $request
}