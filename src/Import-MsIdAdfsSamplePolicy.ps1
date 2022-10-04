<#
.SYNOPSIS
    Imports the 'MsId Block Off Corp and VPN' sample AD FS access control policy. This policy is meant to be used as test policy.
.DESCRIPTION
    Imports the 'MsId Block Off Corp and VPN' sample AD FS access control policy. Pass locations in the format of range (205.143.204.1-205.143.205.250) or CIDR (12.159.168.1/24).

    This policy is meant to be used as test policy!
.EXAMPLE
    PS >Import-MsIdAdfsSamplePolicy -Locations 205.143.204.1-205.143.205.250,12.159.168.1/24,12.35.175.1/26

    Create the policy to the local AD FS server.

.EXAMPLE
    PS >Import-MsIdAdfsSamplePolicy -Locations 205.143.204.1-205.143.205.250 -ApplyTo App1,App2
    
    Create the policy to the local AD FS server and apply it to to the list of applications.
    
#>
function Import-MsIdAdfsSamplePolicy {
    [CmdletBinding()]
    param(
      # Network locations 
      [Parameter(Mandatory=$true)]
      [string[]]$Locations,
      # Relying party names to apply the policy
      [Parameter(Mandatory=$false)]
      [string[]]$ApplyTo
    )

    $name = "MsId Block Off Corp and VPN"

    if (Import-AdfsModule) {
        Try {

            # build <Value> for each location
            $values = ""
            foreach ($location in $Locations) {
                $values += "<Value>$($location)</Value>"
            }

            # load and update metadata file
            $metadataBase = Get-Content "$($PSScriptRoot)\internal\AdfsSamples\AdfsAccessControlPolicy.xml" -Raw
            $metadataStr = $metadataBase -replace '<Values>.*</Values>',"<Values>$values</Values>"
            $metadata = New-Object -TypeName Microsoft.IdentityServer.PolicyModel.Configuration.PolicyTemplate.PolicyMetadata -ArgumentList $metadataStr

            $policy = Get-AdfsAccessControlPolicy -Name $name
            if ($null -eq $policy) {
                Write-Verbose "Creating Access Control Policy $($name)"
                $null = New-AdfsAccessControlPolicy -Name $name -Identifier "DenyNonCorporateandNonVPN" -PolicyMetadata $metadata
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