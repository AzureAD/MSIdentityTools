<#
.SYNOPSIS
    Create a WS-Trust request.
.EXAMPLE
    PS C:\>Import-MsIdAdfsSamplePolicy urn:federation:MicrosoftOnline
    Create a Ws-Trust request for the application urn:federation:MicrosoftOnline.
#>
function Import-MsIdAdfsSamplePolicy {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory=$false)]
      # Application identifier
      [string[]]$ApplyTo

    )

    $name = "Sample Block Off Corp and VPN"
    $metadataPath = "$($PSScriptRoot)\internal\AdfsSamples\AdfsAccessControlPolicy.xml"

    if (Import-AdfsModule) {
        Try {
            $policy = Get-AdfsAccessControlPolicy -Name $name
            if ($null -eq $policy) {
                Write-Verbose "Creating Access Control Policy $($name)"
                $null = New-AdfsAccessControlPolicy -Name $name -Identifier "DenyNonCorporateandNonVPN" -PolicyMetadataFile $metadataPath
            }
            else {
                throw "The policy '" + $name + "' already exists."
            }

            if ($null -ne $ApplyTo) {
                foreach ($app in $ApplyTo) {
                    Set-AdfsRelyingPartyTrust -TargetName $app -AccessControlPolicyName $name
                }
            }
        }            
        Catch {
            Write-Error $_
        }
    }
    else {
        Write-Error "The Import-MsIdAdfsSampleApps cmdlet requires the ADFS module installed to work."
    }
}