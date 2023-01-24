<#
.SYNOPSIS
    Remove Existing Consent to an Azure AD Service Principal.
    
.DESCRIPTION
    This command requires the MS Graph SDK PowerShell Module to have a minimum of the following consented scopes:
    Application.Read.All
    DelegatedPermissionGrant.ReadWrite.All or AppRoleAssignment.ReadWrite.All
    
.EXAMPLE
    PS > Clear-MsIdServicePrincipalConsent '10000000-0000-0000-0000-000000000001' -All

    Remove all consent for servicePrincipal '10000000-0000-0000-0000-000000000001'.

.EXAMPLE
    PS > Get-MgServicePrincipal -ServicePrincipalId '10000000-0000-0000-0000-000000000001' | Clear-MsIdServicePrincipalConsent -Scope User.Read.All -All

    Remove all consent of 'User.Read.All' scope for piped in servicePrincipal '10000000-0000-0000-0000-000000000001'.

.EXAMPLE
    PS > Clear-MsIdServicePrincipalConsent '10000000-0000-0000-0000-000000000001' -UserId '20000000-0000-0000-0000-000000000002'

    Remove existing consent for servicePrincipal '10000000-0000-0000-0000-000000000001' by user '20000000-0000-0000-0000-000000000002'.

.EXAMPLE
    PS > Clear-MsIdServicePrincipalConsent '10000000-0000-0000-0000-000000000001' -Scope User.Read.All -UserConsent -AdminConsentDelegated

    Remove 'User.Read.All' scope from all user consent and tenant-wide admin consent of delegated permissions for servicePrincipal '10000000-0000-0000-0000-000000000001'.

.EXAMPLE
    PS > Clear-MsIdServicePrincipalConsent '10000000-0000-0000-0000-000000000001' -Scope 'User.Read.All','User.ReadWrite.All' -AdminConsentApplication

    Remove 'User.Read.All' scope from tenant-wide admin consent of application permissions for servicePrincipal '10000000-0000-0000-0000-000000000001'.

.INPUTS
    System.String

#>
function Clear-MsIdServicePrincipalConsent {
    [CmdletBinding(DefaultParameterSetName = 'Granular')]
    [Alias('Clear-MsIdApplicationConsent')]
    [OutputType()]
    param (
        # AppId or ObjectId of service principal
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [Alias('Id')]
        [string[]] $ClientId,
        # Limit which scopes are cleared to specified list
        [Parameter(Mandatory = $false)]
        [string[]] $Scope,
        # Remove all existing consent for service principal
        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch] $All,
        # Remove user consent for service principal
        [Parameter(Mandatory = $false, ParameterSetName = 'Granular')]
        [switch] $UserConsent,
        # Remove user consent for service principal for specified users
        [Parameter(Mandatory = $false, ParameterSetName = 'Granular')]
        [Alias('PrincipalId')]
        [string[]] $UserId,
        # Remove tenant-wide admin consent of user delegated permissions for service principal
        [Parameter(Mandatory = $false, ParameterSetName = 'Granular')]
        [switch] $AdminConsentDelegated,
        # Remove tenant-wide admin consent of application permissions for service principal
        [Parameter(Mandatory = $false, ParameterSetName = 'Granular')]
        [switch] $AdminConsentApplication
    )

    begin {
        ## Parameter Set Check
        if (!$All -and !($UserConsent -or $UserId -or $AdminConsentDelegated -or $AdminConsentApplication)) {
            Write-Warning "Your current parameter set will not clear any consent. Add switch for types of consent to clear or add 'All' to clear all consent types."
        }

        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-MgCommandPrerequisites 'Get-MgServicePrincipal' -MinimumVersion 1.9.2 -ErrorVariable CriticalError) -and $CriticalError.CategoryInfo.Reason -Contains 'AuthenticationException') { return }
        
        if ($All -or $UserConsent -or $UserId -or $AdminConsentDelegated) {
            if (!(Test-MgCommandPrerequisites 'Get-MgServicePrincipalOauth2PermissionGrant', 'Update-MgOauth2PermissionGrant', 'Remove-MgOauth2PermissionGrant' -MinimumVersion 1.9.2 -ErrorVariable CriticalError)) { return }
        }
        elseif ($All -or $AdminConsentApplication) {
            if (!(Test-MgCommandPrerequisites 'Remove-MgServicePrincipalAppRoleAssignment' -MinimumVersion 1.9.2 -ErrorVariable CriticalError)) { return }
        }
    }

    process {
        if ($CriticalError) { return }

        foreach ($_ClientId in $ClientId) {

            ## Check for service principal by appId
            $servicePrincipalId = Get-MgServicePrincipal -Filter "appId eq '$_ClientId'" -Select id | Select-Object -ExpandProperty id
            ## If nothing is returned, use provided ClientId as servicePrincipalId
            if (!$servicePrincipalId) { $servicePrincipalId = $_ClientId }

            ## Get Service Principal details
            $servicePrincipal = Get-MgServicePrincipal -ServicePrincipalId $servicePrincipalId -Select id -Expand appRoleAssignments
            if ($servicePrincipal) {
                
                if ($All -or $AdminConsentApplication) {

                    ## Remove Application Permissions with Tenant-Wide Admin Consent
                    foreach ($appRoleAssignment in $servicePrincipal.AppRoleAssignments) {
                        $spResource = Get-MgServicePrincipal -ServicePrincipalId $appRoleAssignment.ResourceId -Select id, appRoles
                        $ScopeValue = $spResource.AppRoles | Where-Object Id -EQ $appRoleAssignment.AppRoleId | Select-Object -ExpandProperty Value
                        if (!$Scope -or $ScopeValue -in $Scope) {
                            Remove-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $appRoleAssignment.PrincipalId -AppRoleAssignmentId $appRoleAssignment.Id
                        }
                    }

                }

                if ($All -or $UserConsent -or $UserId -or $AdminConsentDelegated) {

                    ## Get all oauth2PermissionGrants and loop through each one
                    $oauth2PermissionGrants = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $servicePrincipalId
                    foreach ($oauth2PermissionGrant in $oauth2PermissionGrants) {

                        if ($Scope) {
                            [System.Collections.Generic.List[string]] $UpdatedScopes = $oauth2PermissionGrant.Scope -split ' '
                            foreach ($_Scope in $Scope) { [void]$UpdatedScopes.Remove($_Scope) }
                        }

                        if ($Scope -and $UpdatedScopes) {
                            ## Update scopes for requested entries
                            if ($oauth2PermissionGrant.ConsentType -eq 'Principal' -and ($All -or ($UserConsent -and !$UserId) -or ($oauth2PermissionGrant.PrincipalId -in $UserId))) {
                                Update-MgOauth2PermissionGrant -OAuth2PermissionGrantId $oauth2PermissionGrant.Id -Scope ($UpdatedScopes -join ' ')
                            }
                            elseif ($oauth2PermissionGrant.ConsentType -eq 'AllPrincipals' -and ($All -or $AdminConsentDelegated)) {
                                Update-MgOauth2PermissionGrant -OAuth2PermissionGrantId $oauth2PermissionGrant.Id -Scope ($UpdatedScopes -join ' ')
                            }
                        }
                        else {
                            ## Remove all scopes for requested entries
                            if ($oauth2PermissionGrant.ConsentType -eq 'Principal' -and ($All -or ($UserConsent -and !$UserId) -or ($oauth2PermissionGrant.PrincipalId -in $UserId))) {
                                Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $oauth2PermissionGrant.Id
                            }
                            elseif ($oauth2PermissionGrant.ConsentType -eq 'AllPrincipals' -and ($All -or $AdminConsentDelegated)) {
                                Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $oauth2PermissionGrant.Id
                            }
                        }
                    }

                }

            }
        }
    }
}
