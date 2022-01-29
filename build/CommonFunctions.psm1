Set-StrictMode -Version 2.0

function Get-RelativePath {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        # Input Paths
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
        [string[]] $Paths,
        # Directory to base relative paths. Default is current directory.
        [Parameter(Mandatory=$false, Position=2)]
        [string] $BaseDirectory = (Get-Location).ProviderPath
    )

    process {
        foreach ($Path in $Paths) {
            if (!$BaseDirectory.EndsWith('\') -and !$BaseDirectory.EndsWith('/')) { $BaseDirectory += '\' }
            [uri] $uriPath = $Path
            [uri] $uriBaseDirectory = $BaseDirectory
            [uri] $uriRelativePath = $uriBaseDirectory.MakeRelativeUri($uriPath)
            [string] $RelativePath = '.\{0}' -f $uriRelativePath.ToString().Replace("/", "\");
            Write-Output $RelativePath
        }
    }
}

function Get-FullPath {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        # Input Paths
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
        [string[]] $Paths,
        # Directory to base relative paths. Default is current directory.
        [Parameter(Mandatory=$false, Position=2)]
        [string] $BaseDirectory = (Get-Location).ProviderPath
    )

    process {
        foreach ($Path in $Paths) {
            [string] $AbsolutePath = $Path
            if (![System.IO.Path]::IsPathRooted($AbsolutePath)) {
                $AbsolutePath = (Join-Path $BaseDirectory $AbsolutePath)
            }
            [string] $AbsolutePath = [System.IO.Path]::GetFullPath($AbsolutePath)
            Write-Output $AbsolutePath
        }
    }
}

function Resolve-FullPath {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        # Input Paths
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
        [string[]] $Paths,
        # Directory to base relative paths. Default is current directory.
        [Parameter(Mandatory=$false, Position=2)]
        [string] $BaseDirectory = (Get-Location).ProviderPath,
        # Resolves items in all child directories of the specified locations.
        [Parameter(Mandatory=$false)]
        [switch] $Recurse,
        # Resolves items in all parent directories of the specified locations.
        [Parameter(Mandatory=$false)]
        [switch] $RecurseUp
    )

    process {
        foreach ($Path in $Paths) {
            [string] $AbsolutePath = $Path
            if (![System.IO.Path]::IsPathRooted($AbsolutePath)) {
                $AbsolutePath = (Join-Path $BaseDirectory $AbsolutePath)
            }
            [string[]] $AbsoluteOutputPaths = Resolve-Path $AbsolutePath
            if ($Recurse) {
                $RecurseBaseDirectory = Join-Path (Split-Path $AbsolutePath -Parent) "**"
                $RecurseFilename = Split-Path $AbsolutePath -Leaf
                $RecursePath = Join-Path $RecurseBaseDirectory $RecurseFilename
                $AbsoluteOutputPaths += Resolve-Path $RecursePath
            }
            if ($RecurseUp) {
                $RecurseBaseDirectory = Split-Path $AbsolutePath -Parent
                $RecurseFilename = Split-Path $AbsolutePath -Leaf
                while ($RecurseBaseDirectory -match "[\\/]") {
                    $RecurseBaseDirectory = Split-Path $RecurseBaseDirectory -Parent
                    if ($RecurseBaseDirectory) {
                        $RecursePath = Join-Path $RecurseBaseDirectory $RecurseFilename
                        $AbsoluteOutputPaths += Resolve-Path $RecursePath
                    }
                }
            }
            Write-Output $AbsoluteOutputPaths
        }
    }
}

function Get-PathInfo {
    [CmdletBinding()]
    param (
        # Input Paths
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
        [AllowEmptyString()]
        [string[]] $Paths,
        # Specifies the type of output path when the path does not exist. By default, it will guess path type. If path exists, this parameter is ignored.
        [Parameter(Mandatory=$false, Position=2)]
        [ValidateSet("Directory", "File")]
        [string] $InputPathType,
        # Root directory to base relative paths. Default is current directory.
        [Parameter(Mandatory=$false, Position=3)]
        [string] $DefaultDirectory = (Get-Location).ProviderPath,
        # Filename to append to path if no filename is present.
        [Parameter(Mandatory=$false, Position=4)]
        [string] $DefaultFilename,
        #
        [Parameter(Mandatory=$false)]
        [switch] $SkipEmptyPaths
    )

    process {
        foreach ($Path in $Paths) {

            if (!$SkipEmptyPaths -and !$Path) { $Path = $DefaultDirectory }
            $OutputPath = $null

            if ($Path) {
                ## Look for existing path
                try {
                    $ResolvePath = Resolve-FullPath $Path -BaseDirectory $DefaultDirectory -ErrorAction SilentlyContinue
                    $OutputPath = Get-Item $ResolvePath -ErrorAction SilentlyContinue
                }
                catch {}
                ## If path could not be found and there are no wildcards, then create a FileSystemInfo object for the path.
                if (!$OutputPath -and $Path -notmatch '[*?]') {
                    ## Get Absolute Path
                    [string] $AbsolutePath = Get-FullPath $Path -BaseDirectory $DefaultDirectory
                    ## Guess if path is File or Directory
                    if ($InputPathType -eq "File" -or (!$InputPathType -and $AbsolutePath -match '[\\/](?!.*[\\/]).+\.(?!\.*$).*[^\\/]$')) {
                        $OutputPath = New-Object System.IO.FileInfo -ArgumentList $AbsolutePath
                    }
                    else {
                        $OutputPath = New-Object System.IO.DirectoryInfo -ArgumentList $AbsolutePath
                    }
                }
                ## If a DefaultFilename was provided and no filename was present in path, then add the default.
                if ($DefaultFilename -and $OutputPath -is [System.IO.DirectoryInfo]) {
                    [string] $AbsolutePath = (Join-Path $OutputPath.FullName $DefaultFileName)
                    $OutputPath = $null
                    try {
                        $ResolvePath = Resolve-FullPath $AbsolutePath -BaseDirectory $DefaultDirectory -ErrorAction SilentlyContinue
                        $OutputPath = Get-Item $ResolvePath -ErrorAction SilentlyContinue
                    }
                    catch {}
                    if (!$OutputPath -and $AbsolutePath -notmatch '[*?]') {
                        $OutputPath = New-Object System.IO.FileInfo -ArgumentList $AbsolutePath
                    }
                }

                if (!$OutputPath -or !$OutputPath.Exists) {
                    if ($OutputPath) { Write-Error -Exception (New-Object System.Management.Automation.ItemNotFoundException -ArgumentList ('Cannot find path ''{0}'' because it does not exist.' -f $OutputPath.FullName)) -TargetObject $OutputPath.FullName -ErrorId 'PathNotFound' -Category ObjectNotFound }
                    else { Write-Error -Exception (New-Object System.Management.Automation.ItemNotFoundException -ArgumentList ('Cannot find path ''{0}'' because it does not exist.' -f $AbsolutePath)) -TargetObject $AbsolutePath -ErrorId 'PathNotFound' -Category ObjectNotFound }
                }
            }

            ## Return Path Info
            Write-Output $OutputPath
        }
    }
}

function Assert-DirectoryExists {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        # Directories
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [object[]] $InputObjects,
        # Directory to base relative paths. Default is current directory.
        [Parameter(Mandatory=$false, Position=2)]
        [string] $BaseDirectory = (Get-Location).ProviderPath
    )
    process {
        foreach ($InputObject in $InputObjects) {
            ## InputObject Casting
            if($InputObject -is [System.IO.DirectoryInfo]) {
                [System.IO.DirectoryInfo] $DirectoryInfo = $InputObject
            }
            elseif($InputObject -is [System.IO.FileInfo]) {
                [System.IO.DirectoryInfo] $DirectoryInfo = $InputObject.Directory
            }
            elseif ($InputObject -is [string]) {
                [System.IO.DirectoryInfo] $DirectoryInfo = $InputObject
            }

            if (!$DirectoryInfo.Exists) {
                Write-Output (New-Item $DirectoryInfo.FullName -ItemType Container)
            }
        }
    }
}

function New-LogFilename ([string] $Path) { return ('{0}.{1}.log' -f $Path, (Get-Date -Format "yyyyMMddThhmmss")) }
function Get-ExtractionFolder ([System.IO.FileInfo] $Path) { return Join-Path $Path.DirectoryName $Path.BaseName }

function Use-StartBitsTransfer {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        # Specifies the source location and the names of the files that you want to transfer.
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Source,
        # Specifies the destination location and the names of the files that you want to transfer.
        [Parameter(Mandatory=$false, Position=1)]
        [string] $Destination,
        # Specifies the proxy usage settings
        [Parameter(Mandatory=$false, Position=3)]
        [ValidateSet('SystemDefault','NoProxy','AutoDetect','Override')]
        [string] $ProxyUsage,
        # Specifies a list of proxies to use
        [Parameter(Mandatory=$false, Position=4)]
        [uri[]] $ProxyList,
        # Specifies the authentication mechanism to use at the Web proxy
        [Parameter(Mandatory=$false, Position=5)]
        [ValidateSet('Basic','Digest','NTLM','Negotiate','Passport')]
        [string] $ProxyAuthentication,
        # Specifies the credentials to use to authenticate the user at the proxy
        [Parameter(Mandatory=$false, Position=6)]
        [pscredential] $ProxyCredential,
        # Returns an object representing transfered item.
        [Parameter(Mandatory=$false)]
        [switch] $PassThru
    )
    [hashtable] $paramStartBitsTransfer = $PSBoundParameters
    foreach ($Parameter in $PSBoundParameters.Keys) {
        if ($Parameter -notin 'ProxyUsage','ProxyList','ProxyAuthentication','ProxyCredential') {
            $paramStartBitsTransfer.Remove($Parameter)
        }
    }

    if (!$Destination) { $Destination = (Get-Location).ProviderPath }
    if (![System.IO.Path]::HasExtension($Destination)) { $Destination = Join-Path $Destination (Split-Path $Source -Leaf) }
    if (Test-Path $Destination) { Write-Verbose ('The Source [{0}] was not transfered to Destination [{0}] because it already exists.' -f $Source, $Destination) }
    else {
        Write-Verbose ('Downloading Source [{0}] to Destination [{1}]' -f $Source, $Destination);
        Start-BitsTransfer $Source $Destination @paramStartBitsTransfer
    }
    if ($PassThru) { return Get-Item $Destination }
}

function Use-StartProcess {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        # Specifies the path (optional) and file name of the program that runs in the process.
        [Parameter(Mandatory=$true, Position=0)]
        [string] $FilePath,
        # Specifies parameters or parameter values to use when starting the process.
        [Parameter(Mandatory=$false)]
        [string[]] $ArgumentList,
        # Specifies the working directory for the process.
        [Parameter(Mandatory=$false)]
        [string] $WorkingDirectory,
        # Specifies a user account that has permission to perform this action.
        [Parameter(Mandatory=$false)]
        [pscredential] $Credential,
        # Regex pattern in cmdline to replace with '**********'
        [Parameter(Mandatory=$false)]
        [string[]] $SensitiveDataFilters
    )
    [hashtable] $paramStartProcess = $PSBoundParameters
    foreach ($Parameter in $PSBoundParameters.Keys) {
        if ($Parameter -in 'SensitiveDataFilters') {
            $paramStartProcess.Remove($Parameter)
        }
    }
    [string] $cmd = '"{0}" {1}' -f $FilePath, ($ArgumentList -join ' ')
    foreach ($Filter in $SensitiveDataFilters) {
        $cmd = $cmd -replace $Filter,'**********'
    }
    if ($PSCmdlet.ShouldProcess([System.Environment]::MachineName, $cmd)) {
        [System.Diagnostics.Process] $process = Start-Process -PassThru -Wait -NoNewWindow @paramStartProcess
        if ($process.ExitCode -ne 0) { Write-Error -Category FromStdErr -CategoryTargetName (Split-Path $FilePath -Leaf) -CategoryTargetType "Process" -TargetObject $cmd -CategoryReason "Exit Code not equal to 0" -Message ('Process [{0}] with Id [{1}] terminated with Exit Code [{2}]' -f $FilePath, $process.Id, $process.ExitCode) }
    }
}

function Invoke-WindowsInstaller {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        # Path to msi or msp
        [Parameter(Mandatory=$true, Position=0)]
        [System.IO.FileInfo] $Path,
        # Sets user interface level
        [Parameter(Mandatory=$false)]
        [ValidateSet('None','Basic','Reduced','Full')]
        [string] $UserInterfaceMode,
        # Restart Options
        [Parameter(Mandatory=$false)]
        [ValidateSet('No','Prompt','Force')]
        [string] $RestartOptions,
        # Logging Options
        [Parameter(Mandatory=$false)]
        [ValidatePattern('^[iwearucmopvx\+!\*]{0,14}$')]
        [string] $LoggingOptions,
        # Path of log file
        [Parameter(Mandatory=$false)]
        [System.IO.FileInfo] $LogPath,
        # Public Properties
        [Parameter(Mandatory=$false)]
        [hashtable] $PublicProperties,
        # Specifies the working directory for the process.
        [Parameter(Mandatory=$false)]
        [string] $WorkingDirectory,
        # Regex pattern in cmdline to replace with '**********'
        [Parameter(Mandatory=$false)]
        [string[]] $SensitiveDataFilters
    )

    [System.IO.FileInfo] $itemLogPath = (Get-Location).ProviderPath
    if ($LogPath) { $itemLogPath = $LogPath }
    if (!$itemLogPath.Extension) { $itemLogPath = Join-Path $itemLogPath.FullName ('{0}.{1}.log' -f (Split-Path $Path -Leaf),(Get-Date -Format "yyyyMMddThhmmss")) }

    ## Windows Installer Arguments
    [System.Collections.Generic.List[string]] $argMsiexec = New-Object "System.Collections.Generic.List[string]"
    switch ($UserInterfaceMode)
    {
        'None' { $argMsiexec.Add('/qn'); break }
        'Basic' { $argMsiexec.Add('/qb'); break }
        'Reduced' { $argMsiexec.Add('/qr'); break }
        'Full' { $argMsiexec.Add('/qf'); break }
    }

    switch ($Restart)
    {
        'No' { $argMsiexec.Add('/norestart'); break }
        'Prompt' { $argMsiexec.Add('/promptrestart'); break }
        'Force' { $argMsiexec.Add('/forcerestart'); break }
    }

    if ($LoggingOptions -or $LogPath) { $argMsiexec.Add(('/l{0} "{1}"' -f $LoggingOptions, $itemLogPath.FullName)) }
    switch ($Path.Extension)
    {
        '.msi' { $argMsiexec.Add('/i "{0}"' -f $Path); break }
        '.msp' { $argMsiexec.Add('/update "{0}"' -f $Path); break }
        Default { $argMsiexec.Add('/i "{0}"' -f $Path); break }
    }

    foreach ($PropertyKey in $PublicProperties.Keys) {
        $argMsiexec.Add(('{0}="{1}"' -f $PropertyKey.ToUpper(), $PublicProperties[$PropertyKey]))
    }

    [hashtable] $paramStartProcess = @{}
    if ($argMsiexec) { $paramStartProcess["ArgumentList"] = $argMsiexec }
    if ($WorkingDirectory) { $paramStartProcess["WorkingDirectory"] = $WorkingDirectory }

    Use-StartProcess msiexec @paramStartProcess
}





function New-AzureADApplicationPublicClient ($MsalToken) {
    [hashtable] $Headers = @{
        Authorization = $MsalToken.CreateAuthorizationHeader()
    }

    $appPublicClient = Invoke-RestMethod -UseBasicParsing -Method Post -Uri "https://graph.microsoft.com/beta/applications" -Headers $Headers -ContentType 'application/json' -Body (ConvertTo-Json -Depth 4 @{
        displayName = "PublicClient"
        signInAudience = "AzureADMyOrg"
        isFallbackPublicClient = $true
        publicClient = @{
            redirectUris = @(
                "urn:ietf:wg:oauth:2.0:oob"
                "https://login.microsoftonline.com/common/oauth2/nativeclient"
            )
        }
        web = $null
        requiredResourceAccess = @(
            @{
                resourceAppId = "00000003-0000-0000-c000-000000000000"
                resourceAccess = @(
                    @{
                        id = "06da0dbc-49e2-44d2-8312-53f166ab848a"
                        type = "Scope"
                    }
                    @{
                        id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
                        type = "Scope"
                    }
                )
            }
        )
        tags = @(
            "Test"
        )
    })
    return $appPublicClient
}

function New-AzureADApplicationConfidentialClient ($MsalToken) {
    [hashtable] $Headers = @{
        Authorization = $MsalToken.CreateAuthorizationHeader()
    }

    $appConfidentialClient = Invoke-RestMethod -UseBasicParsing -Method Post -Uri "https://graph.microsoft.com/beta/applications" -Headers $Headers -ContentType 'application/json' -Body (ConvertTo-Json -Depth 4 @{
        displayName = "ConfidentialClient"
        signInAudience = "AzureADMyOrg"
        isFallbackPublicClient = $false
        publicClient = $null
        web = @{
            redirectUris = @(
                "urn:ietf:wg:oauth:2.0:oob"
                "https://login.microsoftonline.com/common/oauth2/nativeclient"
            )
        }
        requiredResourceAccess = @(
            @{
                resourceAppId = "00000003-0000-0000-c000-000000000000"
                resourceAccess = @(
                    @{
                        id = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
                        type = "Role"
                    }
                    @{
                        id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
                        type = "Scope"
                    }
                )
            }
        )
        api = @{
            oauth2PermissionScopes = @(
                @{
                    id = [guid]::NewGuid()
                    value = "user_impersonation"
                    type = "User"
                    adminConsentDescription = "Allow the application to access ConfidentialClient on behalf of the signed-in user."
                    adminConsentDisplayName = "Access ConfidentialClient"
                    userConsentDescription = "Allow the application to access ConfidentialClient on your behalf."
                    userConsentDisplayName = "Access ConfidentialClient"
                    isEnabled = $true
                }
            )
        }
        tags = @(
            "Test"
        )
    })
    return $appConfidentialClient
}

function Add-AzureADApplicationClientSecret ($MsalToken,$ClientId) {
    [hashtable] $Headers = @{
        Authorization = $MsalToken.CreateAuthorizationHeader()
    }

    $appConfidentialClient = Invoke-RestMethod -UseBasicParsing -Method Get -Uri "https://graph.microsoft.com/beta/applications?`$filter=appId eq '$ClientId'" -Headers $Headers
    if ($appConfidentialClient.value.Count) {
        [securestring] $ClientSecret = New-AzureADClientSecret
        Invoke-RestMethod -UseBasicParsing -Method Patch -Uri "https://graph.microsoft.com/beta/applications/$($appConfidentialClient.value[0].id)" -Headers $Headers -ContentType 'application/json' -Body (ConvertTo-Json @{
            passwordCredentials = @(
                $appConfidentialClient.value[0].passwordCredentials | Where-Object displayName -NE 'MSAL.PS'
                @{
                    endDateTime = (Get-Date).AddMonths(1).ToString('O')
                        secretText = $(if ($PSVersionTable.PSVersion -ge [version]'7.0') { ConvertFrom-SecureString $ClientSecret -AsPlainText } else { ConvertFrom-SecureStringAsPlainText $ClientSecret -Force })
                    displayName = "MSAL.PS"
                }
            )
        }) | Out-Null
    }
    return $ClientSecret
}

function Add-AzureADApplicationClientCertificate ($MsalToken,$ClientId) {
    [hashtable] $Headers = @{
        Authorization = $MsalToken.CreateAuthorizationHeader()
    }

    $appConfidentialClient = Invoke-RestMethod -UseBasicParsing -Method Get -Uri "https://graph.microsoft.com/beta/applications?`$filter=appId eq '$ClientId'" -Headers $Headers
    if ($appConfidentialClient.value.Count) {
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientCertificate = New-SelfSignedCertificate -Subject 'CN=ConfidentialClient' -KeyFriendlyName "Confidential Client" -HashAlgorithm sha256 -KeySpec Signature -KeyLength 2048 -Type Custom -NotBefore (Get-Date) -NotAfter (Get-Date).AddYears(1) -KeyExportPolicy ExportableEncrypted -CertStoreLocation Cert:\CurrentUser\My
        Invoke-RestMethod -UseBasicParsing -Method Patch -Uri "https://graph.microsoft.com/beta/applications/$($appConfidentialClient.value[0].id)" -Headers $Headers -ContentType 'application/json' -Body (ConvertTo-Json @{
            keyCredentials = @(
                $appConfidentialClient.value[0].keyCredentials | Where-Object displayName -NE 'MSAL.PS'
                @{
                    type = "AsymmetricX509Cert"
                    usage = "Verify"
                    key = ConvertTo-Base64String $ClientCertificate.GetRawCertData()
                    displayName = "MSAL.PS"
                }
            )
        }) | Out-Null
    }
    return $ClientCertificate
}


function Test-AddingDlls ([string[]]$LiteralPath) {
    try
    {
        Add-Type -LiteralPath $LiteralPath
    }
    catch [System.Reflection.ReflectionTypeLoadException]
    {
        Write-Host "Message: $($_.Exception.Message)"
        Write-Host "StackTrace: $($_.Exception.StackTrace)"
        Write-Host "LoaderExceptions: $($_.Exception.LoaderExceptions)"
    }

    [appdomain]::CurrentDomain.GetAssemblies()
}

function Validate-Certificate () {
    $X509SecurityToken=New-Object Microsoft.IdentityModel.Tokens.X509SecurityKey $ConfidentialClientCertificate
    $JwtSecurityToken=(New-Object System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler).ReadToken($MsalToken.AccessToken)
    $TokenValidationParameters=New-Object Microsoft.IdentityModel.Tokens.TokenValidationParameters -Property @{
        IssuerSigningKey = $X509SecurityToken;
        ValidAudience = $JwtSecurityToken.Audience;
        ValidIssuer = $JwtSecurityToken.Issuer
    }
    [Microsoft.IdentityModel.Tokens.SecurityToken] $validatedToken = $null
    $ValidateTokenResult=(New-Object System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler).ValidateToken($MsalToken.AccessToken,$TokenValidationParameters,[ref]$validatedToken)
    Write-Verbose -Verbose "The token validation result is: $($ValidateTokenResult.Identity.IsAuthenticated)"

}
