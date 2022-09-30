<#
.SYNOPSIS
    Create a WS-Trust request.
.EXAMPLE
    PS C:\>Get-MsIdAdfsSampleApps
    Create a Ws-Trust request for the application urn:federation:MicrosoftOnline.
#>
function Get-MsIdAdfsSampleApp {
    [CmdletBinding()]
    [OutputType([object[]])]
    param (
        # Exclude applications identifier
        [Parameter(Mandatory = $false)]
        [string] $Name
    )

    $result = [System.Collections.ArrayList]@()

    if (Import-AdfsModule) {
        $apps = Get-ChildItem -Path "$($PSScriptRoot)\internal\AdfsSamples\"

        if ($Name -ne '') {
            $apps = $apps | Where-Object { $_.Name -eq $Name + '.json' } 
        }
    
        ForEach ($app in $apps) {
            Try {
                Write-Verbose "Loading app: $($app.Name)"
                if ($app.Name -notlike '*.xml') {
                    $rp = Get-Content $app.FullName | ConvertFrom-json
                    $null = $result.Add($rp)
                }
            }
            catch {
                Write-Warning "Error while loading app '$($app.Name)': ($_)"
            }
        }

        return ,$result
    }
}