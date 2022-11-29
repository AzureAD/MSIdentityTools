<#
.SYNOPSIS
   Get User Realm Information for a Microsoft user account.
.EXAMPLE
   Get-MsftUserRealm user@domain.com
.EXAMPLE
   'user1@domainA.com','user2@domainA.com','user@domainB.com' | Get-MsftUserRealm
#>
function Get-MsftUserRealm {
    [CmdletBinding()]
    [OutputType([PsCustomObject[]])]
    param
    (
        #
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [string[]] $User,
        # API Version
        [Parameter(Mandatory = $false)]
        [string] $ApiVersion = '2.1'
    )

    process {
        foreach ($_User in $User) {
            $uriUserRealm = New-Object System.UriBuilder 'https://login.microsoftonline.com/common/userrealm'
            $uriUserRealm.Query = ConvertTo-QueryString @{
                'api-version' = $ApiVersion
                'checkForMicrosoftAccount' = $true
                'user'        = $_User
            }

            $Result = Invoke-RestMethod -UseBasicParsing -Method Get -Uri $uriUserRealm.Uri.AbsoluteUri
            Write-Output $Result
        }
    }
}
