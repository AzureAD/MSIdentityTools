<#
.SYNOPSIS
        Imports a the 'MsId Block Off Corp and VPN'  sample AD FS access control policy. This policy is meant to be used as test policy.
.EXAMPLE
    PS C:\>Import-MsIdAdfsSamplePolicy
    Create the policy to the local AD FS server.
.EXAMPLE
    PS C:\>Import-MsIdAdfsSamplePolicy -ApplyTo App1,App2
    Create the policy to the local AD FS server and apply it to to the list of applications.
#>
function Import-MsIdAdfsSamplePolicy {
    [CmdletBinding()]
    param(
      # Application identifier
      [Parameter(Mandatory=$false)]
      [string[]]$ApplyTo

    )

    $name = "MsId Block Off Corp and VPN"
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