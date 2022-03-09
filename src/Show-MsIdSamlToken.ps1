<#
.SYNOPSIS
   Show Saml Security Token decoded in Web Browser.
   
.EXAMPLE
    PS > Show-MsIdSamlToken 'Base64String'

    Show Saml Security Token decoded in Web Browser.

.INPUTS
    System.String

#>
function Show-MsIdSamlToken {
    [CmdletBinding()]
    [Alias('Show-SamlResponse')]
    param (
        # SAML Security Token
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]] $Tokens,
        # URL Endpoint to send SAML Security Token
        [Parameter(Mandatory = $false)]
        [string] $SamlEndpoint = 'https://adfshelp.microsoft.com/ClaimsXray/TokenResponse'
    )

    begin {
        Write-Warning ('The token is being sent to the following service [{0}]. This command is intended for troubleshooting and should only be used if you trust the service endpoint receiving the token.' -f $SamlEndpoint)

        function GetAvailableLocalTcpPort {
            $TcpListner = New-Object System.Net.Sockets.TcpListener -ArgumentList ([ipaddress]::Loopback, 0)
            try {
                $TcpListner.Start();
                return $TcpListner.LocalEndpoint.Port
            }
            finally { $TcpListner.Stop() }
        }

        function RespondToLocalHttpRequest {
            [CmdletBinding()]
            param (
                # HttpListener Object
                [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
                [System.Net.HttpListener] $HttpListener,
                # HTTP Message Body
                [Parameter(Mandatory = $true)]
                [byte[]] $MessageBody
            )

            ## Wait for HTTP Request
            $HttpListenerContext = $HttpListener.GetContext()

            ## Response to HTTP Request
            Write-Verbose ('{0} => {1}' -f $HttpListenerContext.Request.UserHostAddress, $HttpListenerContext.Request.Url)
            #$MessageBody = [System.Text.Encoding]::UTF8.GetBytes($Html)
            $HttpListenerContext.Response.ContentLength64 = $MessageBody.Length
            $HttpListenerContext.Response.OutputStream.Write($MessageBody, 0, $MessageBody.Length)
            $HttpListenerContext.Response.OutputStream.Close()
        }

        ## Get HTML Content
        $pathHtml = Join-Path $PSScriptRoot 'internal\SamlRedirect.html'
        if ($PSVersionTable.PSVersion -ge [version]'6.0') {
            $bytesHtml = Get-Content $pathHtml -Raw -AsByteStream
        }
        else {
            $bytesHtml = Get-Content $pathHtml -Raw -Encoding Byte
        }

        ## Generate local HTTP URL and Listener
        [System.UriBuilder] $uriSamlRedirect = New-Object System.UriBuilder -Property @{
            Scheme = 'http'
            Host   = 'localhost'
            Port   = GetAvailableLocalTcpPort
        }
        $HttpListener = New-Object System.Net.HttpListener
        $HttpListener.Prefixes.Add($uriSamlRedirect.Uri.AbsoluteUri)
    }

    process {
        foreach ($Token in $Tokens) {
            $uriSamlRedirect.Fragment = ConvertTo-QueryString @{
                SAMLResponse = $Token
                ReplyURL     = $SamlEndpoint
            }

            try {
                $HttpListener.Start()
                Start-Process $uriSamlRedirect.Uri.AbsoluteUri
                $HttpListener | RespondToLocalHttpRequest -MessageBody $bytesHtml
            }
            finally { $HttpListener.Stop() }
        }
    }

    end {
        $HttpListener.Dispose()
    }
}
