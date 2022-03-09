<#
.SYNOPSIS
   Create New Saml Request.
   
.EXAMPLE
    PS > New-MsIdSamlRequest -Issuer 'urn:microsoft:adfs:claimsxray'

    Create New Saml Request for Claims X-Ray.

.INPUTS
    System.String

.OUTPUTS
    SamlMessage : System.Xml.XmlDocument, System.String

#>
function New-MsIdSamlRequest {
    [CmdletBinding()]
    #[OutputType([xml], [string])]
    param (
        # Azure AD uses this attribute to populate the InResponseTo attribute of the returned response.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $Issuer,
        # If provided, this parameter must match the RedirectUri of the cloud service in Azure AD.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $AssertionConsumerServiceURL,
        # If this is true, Azure AD will attempt to authenticate the user silently using the session cookie.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $IsPassive,
        # If true, it means that the user will be forced to re-authenticate, even if they have a valid session with Azure AD.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $ForceAuthn,
        # Tailors the name identifier in the subjects of assertions.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ArgumentCompleter({
                param ( $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters )
                'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
                'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
                'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified'
            })]
        [string] $NameIDPolicyFormat,
        # Specifies the authentication context requirements of authentication statements returned in response to a request or query.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ArgumentCompleter({
                param ( $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters )
                'urn:oasis:names:tc:SAML:2.0:ac:classes:Password'
                'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport'
                'urn:oasis:names:tc:SAML:2.0:ac:classes:InternetProtocolPassword'
                'urn:oasis:names:tc:SAML:2.0:ac:classes:SecureRemotePassword'
                'urn:oasis:names:tc:SAML:2.0:ac:classes:Kerberos'
                'urn:oasis:names:tc:SAML:2.0:ac:classes:X509'
                'urn:oasis:names:tc:SAML:2.0:ac:classes:TLSClient'
                'urn:oasis:names:tc:SAML:2.0:ac:classes:Unspecified'
                'urn:oasis:names:tc:SAML:1.0:am:password'
                'urn:oasis:names:tc:SAML:1.0:am:X509-PKI'
                'urn:federation:authentication:windows'
                'http://schemas.microsoft.com/ws/2008/06/identity/authenticationmethod/password'
                'http://schemas.microsoft.com/ws/2008/06/identity/authenticationmethod/secureremotepassword'
                'http://schemas.microsoft.com/ws/2008/06/identity/authenticationmethod/windows'
                'http://schemas.microsoft.com/ws/2008/06/identity/authenticationmethod/kerberos'
                'http://schemas.microsoft.com/ws/2008/06/identity/authenticationmethod/tlsclient'
                'urn:ietf:rfc:1510'
                'urn:ietf:rfc:2246'
                'urn:ietf:rfc:2945'
            })]
        [string[]] $RequestedAuthnContext,
        # Specifies the comparison method used to evaluate the requested context classes or statements, one of "exact", "minimum", "maximum", or "better".
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('exact', 'minimum', 'maximum', 'better')]
        [string] $RequestedAuthnContextComparison,
        # Deflate and Base64 Encode the Saml Request
        [Parameter(Mandatory = $false)]
        [switch] $DeflateAndEncode,
        # Url Encode the Deflated and Base64 Encoded Saml Request
        [Parameter(Mandatory = $false)]
        [switch] $UrlEncode
    )

    begin {
        $pathSamlRequest = Join-Path $PSScriptRoot 'internal\SamlRequestTemplate.xml'
    }

    process {
        $xmlSamlRequest = New-Object SamlMessage
        $xmlSamlRequest.Load($pathSamlRequest)
        $xmlSamlRequest.AuthnRequest.ID = 'id{0}' -f (New-Guid).ToString("N")
        $xmlSamlRequest.AuthnRequest.IssueInstant = (Get-Date).ToUniversalTime().ToString('o')
        $xmlSamlRequest.AuthnRequest.Issuer.'#text' = $Issuer
        if ($AssertionConsumerServiceURL) { $xmlSamlRequest.AuthnRequest.SetAttribute('AssertionConsumerServiceURL', $AssertionConsumerServiceURL) }
        if ($PSBoundParameters.ContainsKey('IsPassive')) { $xmlSamlRequest.AuthnRequest.SetAttribute('IsPassive', $IsPassive.ToString().ToLowerInvariant()) }
        if ($PSBoundParameters.ContainsKey('ForceAuthn')) { $xmlSamlRequest.AuthnRequest.SetAttribute('ForceAuthn', $ForceAuthn.ToString().ToLowerInvariant()) }
        if ($NameIDPolicyFormat) { (Resolve-XmlElement $xmlSamlRequest.DocumentElement -Prefix samlp -LocalName NameIDPolicy -NamespaceURI $xmlSamlRequest.DocumentElement.NamespaceURI -CreateMissing).SetAttribute('Format', $NameIDPolicyFormat) }
        if ($RequestedAuthnContext) {
            $AuthnContextClassRefTemplate = $xmlSamlRequest.AuthnRequest.RequestedAuthnContext.ChildNodes[0]
            foreach ($AuthnContext in $RequestedAuthnContext) {
                $AuthnContextClassRef = $AuthnContextClassRefTemplate.Clone()
                $AuthnContextClassRef.'#text' = $AuthnContext
                [void]$xmlSamlRequest.AuthnRequest.RequestedAuthnContext.AppendChild($AuthnContextClassRef)
            }
            [void]$xmlSamlRequest.AuthnRequest.RequestedAuthnContext.RemoveChild($AuthnContextClassRefTemplate)
            if ($RequestedAuthnContextComparison) { $xmlSamlRequest.AuthnRequest.RequestedAuthnContext.SetAttribute('Comparison', $RequestedAuthnContextComparison) }
        }

        if ($DeflateAndEncode) {
            $EncodedSamlRequest = $xmlSamlRequest.OuterXml | Compress-Data | ConvertTo-Base64String
            if ($UrlEncode) { Write-Output ([System.Net.WebUtility]::UrlEncode($EncodedSamlRequest)) }
            else { Write-Output $EncodedSamlRequest }
        }
        else {
            Write-Output $xmlSamlRequest
        }
    }
}
