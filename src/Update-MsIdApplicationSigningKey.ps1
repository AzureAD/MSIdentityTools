<#
.SYNOPSIS
    Update a Service Princpal's preferredTokenSigningKeyThumbprint to the specified certificate thumbprint
    For more information on Microsoft Identity platorm signing key rollover https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-signing-key-rollover
.EXAMPLE
    PS C:\>Update-MsIdApplicationSigningKey -ApplicationId <ApplicationId> -KeyThumbprint <Thumbprint>
    Update Application's preferred signing key to the specified thumbprint
.EXAMPLE
    PS C:\>Update-MsIdApplicationSigningKey -ApplicationId <ApplicationId> -Default
    Update Application's preferred signing key to default value null
#>

function Update-MsIdApplicationSigningKey{
    [CmdletBinding()]
    Param(
        # Tenant ID
        $Tenant = "common",

        # Application ID
        [parameter(mandatory = $true)]
        [string]$ApplicationId,

        # Thumbprint of certificate
        [parameter(parametersetname = "Thumbprint", ValueFromPipeline = $false)]
        [parameter(parametersetname = "SpecificCert", ValueFromPipeline = $true)]
        [string]$KeyThumbprint,

        # Return preferredTokenSigningKeyThumbprint to default value
        [parameter(parametersetname = "Default")]
        [switch]$Default
    )

    process{
        if ($Default) { 
            Write-Verbose "Default flag set. preferredTokenSigningKeyThumbprint will be set to null "
            $KeyThumbprint = $null 
        }

        switch ($PSCmdlet.ParameterSetName) {
            "Thumbprint" {
                 
                break
            }
            "SpecificCert" {
                # "$KeyThumbprint is"
                String[]$KeyThumbprint
                $KeyThumbprint = $KeyThumbprint[0].Thumbprint
                break
            }
        }
        

        if ($null -ne $KeyThumbprint) {
            $KeyThumbprint = $KeyThumbprint.Replace(" ", "").ToLower()
        }

        $body = @{preferredTokenSigningKeyThumbprint = $KeyThumbprint } | ConvertTo-Json 
        $body = $body.replace('""','null')

        Write-Verbose "Retrieving Service Principal"
        $sp = Get-MgServicePrincipal -Filter "appId eq '$ApplicationId'"

        if ($null -ne $sp) {
            Write-Verbose "Service Principal found: $($sp.DisplayName)"
            Write-Verbose "Updating Service Principal preferredTokenSigningKeyThumbprint"
            Invoke-MgGraphRequest -Method "PATCH" -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)" -Body $body
        }
        else {
            Write-Error "Service principal was not found - Please check the Client (Application) ID"
        }
    }
}