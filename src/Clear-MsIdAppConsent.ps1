<#
.SYNOPSIS
    Remove Existing Consent to an Azure AD Service Principal.
    
.DESCRIPTION
    This command requires the MS Graph SDK PowerShell Module to have a minimum of the following consented scopes:
    Application.Read.All
    DelegatedPermissionGrant.ReadWrite.All
    
.EXAMPLE
    PS > Clear-MsIdAppConsent '10000000-0000-0000-0000-000000000001' -PrincipalId '20000000-0000-0000-0000-000000000002' -IncludeTenantWideAdminConsent

    Remove existing consent to servicePrincipal '10000000-0000-0000-0000-000000000001' by user '20000000-0000-0000-0000-000000000002'.

.EXAMPLE
    PS > Clear-MsIdAppConsent '10000000-0000-0000-0000-000000000001' -TenantWideAdminConsent

    Remove tenant-wide admin consent to servicePrincipal '10000000-0000-0000-0000-000000000001'.

.EXAMPLE
    PS > Clear-MsIdAppConsent '10000000-0000-0000-0000-000000000001' -All

    Remove all consent to servicePrincipal '10000000-0000-0000-0000-000000000001'.

.INPUTS
    System.String

#>
function Clear-MsIdAppConsent {
    [CmdletBinding()]
    [OutputType()]
    param (
        # AppId or ObjectId of the service principal
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [string[]] $ClientId,
        # Remove all existing consent to the service principal
        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch] $All,
        # Remove consent to the service principal for the specified users. Does not include Tenant-Wide Admin Consent.
        [Parameter(Mandatory = $false, ParameterSetName = 'Filtered')]
        [string[]] $PrincipalId,
        # Remove tenant-wide admin consent to the service principal
        [Parameter(Mandatory = $false, ParameterSetName = 'Filtered')]
        [switch] $TenantWideAdminConsent
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'Get-MgServicePrincipal', 'Get-MgServicePrincipalOauth2PermissionGrant', 'Remove-MgOauth2PermissionGrant' -MinimumVersion 1.9.2 -ErrorVariable CriticalError)) { return }
    }

    process {
        if ($CriticalError) { return }

        foreach ($_ClientId in $ClientId) {
            ## Check for service principal by appId
            $servicePrincipalId = Get-MgServicePrincipal -Filter "appId eq '$_ClientId'" -Select id | Select-Object -ExpandProperty id
            ## If nothing is returned, use provided ClientId as servicePrincipalId
            if (!$servicePrincipalId) { $servicePrincipalId = $_ClientId }

            ## Get all Oauth2PermissionGrants and remove the requested entries
            $oauth2PermissionGrants = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $servicePrincipalId
            foreach ($oauth2PermissionGrant in $oauth2PermissionGrants) {
                switch ($PSCmdlet.ParameterSetName) {
                    'All' {
                        Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $oauth2PermissionGrant.Id
                    }
                    'Filtered' {
                        if ($oauth2PermissionGrant.ConsentType -eq 'Principal' -and $oauth2PermissionGrant.PrincipalId -in $PrincipalId) {
                            Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $oauth2PermissionGrant.Id
                        }
                        elseif ($oauth2PermissionGrant.ConsentType -eq 'AllPrincipals' -and $TenantWideAdminConsent) {
                            Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $oauth2PermissionGrant.Id
                        }
                    }
                }
            }
        }
    }
}
