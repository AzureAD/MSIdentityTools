<#
.SYNOPSIS
    Return the base URI for Graph API based on the current Graph Context's environment.
.DESCRIPTION

#>

function Get-GraphBaseUri {
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    begin {
        $baseUri = 'https://graph.microsoft.com'
        try {
            $context = Get-MgContext
            $environment =  Get-ObjectPropertyValue $context -Name 'Environment'
            if($null -eq $environment){
                $environment = 'Global'
            }
            $baseUri = (Get-MgEnvironment -Name $environment).GraphEndpoint
        }
        catch {

        }
        Write-Output $baseUri
    }
}
