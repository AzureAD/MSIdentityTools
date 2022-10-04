<#
.SYNOPSIS
        Imports a list availabe sample AD FS relyng party trust applications available in this module, the list is created by the Get-MsIdAdfsSampleApps cmdlet. These applications do NOT use real endpoints and are meant to be used as test applications.
.EXAMPLE
    PS >Get-MsIdAdfsSampleApp | Import-MsIdAdfsSampleApp

    Import the full list of sample AD FS apps to the local AD FS server.

.EXAMPLE
    PS >Get-MsIdAdfsSampleApp | Import-MsIdAdfsSampleApp -NamePreffix 'MsId '

    Import the full list of sample AD FS apps to the local AD FS server, adding the MsId prefix to the app name.

.EXAMPLE
    PS >Get-MsIdAdfsSampleApp SampleAppName | Import-MsIdAdfsSampleApp

    Import only the SampleAppName sample AD FS app to the local AD FS server (replace SampleAppName by one of the available apps).
#>
function Import-MsIdAdfsSampleApp {
    [CmdletBinding()]
    param(
      # Application identifier
      [Parameter(Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
      [object[]]$Application,
      # Name prefix for the AD FS relying party
      [Parameter(Mandatory=$false)]
      [string]$NamePreffix = "",
      # Apply sample app default parameters to existing apps
      [Parameter(Mandatory=$false)]
      [switch]$Force = $false
    )

    $samplePolicy = "MsId Block Off Corp and VPN"

    if (Import-AdfsModule) {
        Try {
            foreach($RelyingParty in $Application) {
                Write-Verbose "Processing app '$($RelyingParty.Name)' with the supplied prefix '$($NamePreffix)'"

                $rpName = $NamePreffix + $RelyingParty.Name
                $targetIdentifier = $RelyingParty.Identifier
            
                $adfsApp = Get-ADFSRelyingPartyTrust -Name $rpName
                if ($null -eq $adfsApp) {
                    Write-Verbose "Creating application '$($rpName)'"
                    $null = Add-ADFSRelyingPartyTrust -Identifier $targetIdentifier -Name $rpName
                }            
                else {
                    if (-not $Force) {
                        throw "The application '" + $rpName + "' already exists, use -Force to ovewrite it."
                    }
                    Write-Verbose "Updating application '$($rpName)'"
                }

                Set-ADFSRelyingPartyTrust -TargetName $rpName -AutoUpdateEnabled $RelyingParty.AutoUpdateEnabled
                Set-ADFSRelyingPartyTrust -TargetName $rpName -DelegationAuthorizationRules $RelyingParty.DelegationAuthorizationRules
                Set-ADFSRelyingPartyTrust -TargetName $rpName -IssuanceAuthorizationRules $RelyingParty.IssuanceAuthorizationRules
                Set-ADFSRelyingPartyTrust -TargetName $rpName -WSFedEndpoint $RelyingParty.WSFedEndpoint
                Set-ADFSRelyingPartyTrust -TargetName $rpName -IssuanceTransformRules $RelyingParty.IssuanceTransformRules
                Set-ADFSRelyingPartyTrust -TargetName $rpName -ClaimAccepted $RelyingParty.ClaimsAccepted
                Set-ADFSRelyingPartyTrust -TargetName $rpName -EncryptClaims $RelyingParty.EncryptClaims
                Set-ADFSRelyingPartyTrust -TargetName $rpName -EncryptionCertificate $RelyingParty.EncryptionCertificate
                Set-ADFSRelyingPartyTrust -TargetName $rpName -MetadataUrl $RelyingParty.MetadataUrl
                Set-ADFSRelyingPartyTrust -TargetName $rpName -MonitoringEnabled $RelyingParty.MonitoringEnabled
                Set-ADFSRelyingPartyTrust -TargetName $rpName -NotBeforeSkew $RelyingParty.NotBeforeSkew
                Set-ADFSRelyingPartyTrust -TargetName $rpName -ImpersonationAuthorizationRules $RelyingParty.ImpersonationAuthorizationRules
                Set-ADFSRelyingPartyTrust -TargetName $rpName -ProtocolProfile $RelyingParty.ProtocolProfile
                Set-ADFSRelyingPartyTrust -TargetName $rpName -RequestSigningCertificate $RelyingParty.RequestSigningCertificate
                Set-ADFSRelyingPartyTrust -TargetName $rpName -EncryptedNameIdRequired $RelyingParty.EncryptedNameIdRequired
                Set-ADFSRelyingPartyTrust -TargetName $rpName -SignedSamlRequestsRequired $RelyingParty.SignedSamlRequestsRequired  
            
                $newSamlEndPoints = @()
                foreach ($SamlEndpoint in $RelyingParty.SamlEndpoints)
                {
                    # Is ResponseLocation defined?
                    if ($SamlEndpoint.ResponseLocation)
                    {
                    # ResponseLocation is not null or empty
                    $newSamlEndPoint = New-ADFSSamlEndpoint -Binding $SamlEndpoint.Binding `
                        -Protocol $SamlEndpoint.Protocol `
                        -Uri $SamlEndpoint.Location -Index $SamlEndpoint.Index `
                        -IsDefault $SamlEndpoint.IsDefault
                    }
                    else
                    {
                    $newSamlEndPoint = New-ADFSSamlEndpoint -Binding $SamlEndpoint.Binding `
                        -Protocol $SamlEndpoint.Protocol `
                        -Uri $SamlEndpoint.Location -Index $SamlEndpoint.Index `
                        -IsDefault $SamlEndpoint.IsDefault `
                        -ResponseUri $SamlEndpoint.ResponseLocation
                    }
                    $newSamlEndPoints += $newSamlEndPoint
                }
                Set-ADFSRelyingPartyTrust -TargetName $rpName -SamlEndpoint $newSamlEndPoints
                Set-ADFSRelyingPartyTrust -TargetName $rpName -SamlResponseSignature $RelyingParty.SamlResponseSignature
                Set-ADFSRelyingPartyTrust -TargetName $rpName -SignatureAlgorithm $RelyingParty.SignatureAlgorithm
                Set-ADFSRelyingPartyTrust -TargetName $rpName -TokenLifetime $RelyingParty.TokenLifetime

                # check if using custom plocy and test if exists
                if ($RelyingParty.AccessControlPolicyName -eq $samplePolicy) {
                    if (Get-AdfsAccessControlPolicy -Name $samplePolicy) {
                        Set-AdfsRelyingPartyTrust -TargetName $rpName -AccessControlPolicyName $RelyingParty.AccessControlPolicyName
                    }
                    else {
                        Write-Warning "The Access Control Policy '$($samplePolicy)' is missing, run 'Import-MsIdAdfsSamplePolicies' to create."
                    }
                }
                else {
                    Set-AdfsRelyingPartyTrust -TargetName $rpName -AccessControlPolicyName $RelyingParty.AccessControlPolicyName
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