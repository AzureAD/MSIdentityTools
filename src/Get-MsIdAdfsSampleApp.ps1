<#
.SYNOPSIS
    Returns the list of availabe sample AD FS relyng party trust applications available in this module. These applications do NOT use real endpoints and are meant to be used as test applications.
.EXAMPLE
    PS C:\>Get-MsIdAdfsSampleApps
    Get the full list of sample AD FS apps.
.EXAMPLE
    PS C:\>Get-MsIdAdfsSampleApps SampleAppName
    Get only SampleAppName sample AD FS app (replace SampleAppName by one of the available apps).
#>
function Get-MsIdAdfsSampleApp {
    [CmdletBinding()]
    [OutputType([object[]])]
    param (
        # Sample applications name
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