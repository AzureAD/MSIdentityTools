[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $ModulePath = ".\src\*.psd1"
)

BeforeAll {
    $CriticalError = $null
    $PSModule = Import-Module $ModulePath -Force -PassThru -ErrorVariable CriticalError
    if ($CriticalError) { throw $CriticalError }
}

## Perform Tests
Describe 'Revoke-MsIdServicePrincipalConsent' {
    
    BeforeAll {
        ## Stub functions required when actual command is not available. Parameter names used in Mock filters must be present.
        InModuleScope $PSModule.Name {
            if (!(Get-Command Get-MgServicePrincipal -ErrorAction SilentlyContinue)) {
                function script:Get-MgServicePrincipal ($ServicePrincipalId, $Filter) { throw "The term '$($MyInvocation.MyCommand)' is not recognized as the name of a cmdlet, function, or operable program and there is no mock defined." }
            }
            if (!(Get-Command Remove-MgServicePrincipalAppRoleAssignment -ErrorAction SilentlyContinue)) {
                function script:Remove-MgServicePrincipalAppRoleAssignment () { throw "The term '$($MyInvocation.MyCommand)' is not recognized as the name of a cmdlet, function, or operable program and there is no mock defined." }
            }
            if (!(Get-Command Get-MgServicePrincipalOauth2PermissionGrant -ErrorAction SilentlyContinue)) {
                function script:Get-MgServicePrincipalOauth2PermissionGrant () { throw "The term '$($MyInvocation.MyCommand)' is not recognized as the name of a cmdlet, function, or operable program and there is no mock defined." }
            }
            if (!(Get-Command Update-MgOauth2PermissionGrant -ErrorAction SilentlyContinue)) {
                function script:Update-MgOauth2PermissionGrant () { throw "The term '$($MyInvocation.MyCommand)' is not recognized as the name of a cmdlet, function, or operable program and there is no mock defined." }
            }
            if (!(Get-Command Remove-MgOauth2PermissionGrant -ErrorAction SilentlyContinue)) {
                function script:Remove-MgOauth2PermissionGrant () { throw "The term '$($MyInvocation.MyCommand)' is not recognized as the name of a cmdlet, function, or operable program and there is no mock defined." }
            }
        }

        ## Mock commands with external dependancies or unavailable commands
        # Get Mock Sample When Type Does Not Exist: "[System.Management.Automation.PSSerializer]::Deserialize('{0}')" -f ([xml][System.Management.Automation.PSSerializer]::Serialize($psobject, 2)).OuterXml.Replace("'","''") | Set-Clipboard
        Mock -ModuleName $PSModule.Name Test-MgCommandPrerequisites { $true } -Verifiable
        Mock -ModuleName $PSModule.Name Get-MgServicePrincipal { [System.Management.Automation.PSSerializer]::Deserialize('<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj RefId="0"><TN RefId="0"><T>Microsoft.Graph.PowerShell.Models.MicrosoftGraphServicePrincipal</T><T>System.Object</T></TN><ToString>Microsoft.Graph.PowerShell.Models.MicrosoftGraphServicePrincipal</ToString><Props><Nil N="AccountEnabled" /><Nil N="AddIns" /><Nil N="AlternativeNames" /><Nil N="AppDescription" /><Nil N="AppDisplayName" /><Nil N="AppId" /><Nil N="AppOwnerOrganizationId" /><Nil N="AppRoleAssignedTo" /><Nil N="AppRoleAssignmentRequired" /><Nil N="AppRoleAssignments" /><Nil N="AppRoles" /><Nil N="ApplicationTemplateId" /><Nil N="ClaimsMappingPolicies" /><Nil N="CreatedObjects" /><Nil N="DelegatedPermissionClassifications" /><Nil N="DeletedDateTime" /><Nil N="Description" /><Nil N="DisabledByMicrosoftStatus" /><Nil N="DisplayName" /><Nil N="Endpoints" /><Nil N="HomeRealmDiscoveryPolicies" /><Nil N="Homepage" /><S N="Id">20000000-0000-0000-0000-000000000002</S><S N="Info">Microsoft.Graph.PowerShell.Models.MicrosoftGraphInformationalUrl</S><Nil N="KeyCredentials" /><Nil N="LoginUrl" /><Nil N="LogoutUrl" /><Nil N="MemberOf" /><Nil N="Notes" /><Nil N="NotificationEmailAddresses" /><Nil N="Oauth2PermissionGrants" /><Nil N="Oauth2PermissionScopes" /><Nil N="OwnedObjects" /><Nil N="Owners" /><Nil N="PasswordCredentials" /><Nil N="PreferredSingleSignOnMode" /><Nil N="PreferredTokenSigningKeyThumbprint" /><Nil N="ReplyUrls" /><Nil N="ResourceSpecificApplicationPermissions" /><S N="SamlSingleSignOnSettings">Microsoft.Graph.PowerShell.Models.MicrosoftGraphSamlSingleSignOnSettings</S><Nil N="ServicePrincipalNames" /><Nil N="ServicePrincipalType" /><Nil N="SignInAudience" /><Nil N="Tags" /><Nil N="TokenEncryptionKeyId" /><Nil N="TokenIssuancePolicies" /><Nil N="TokenLifetimePolicies" /><Nil N="TransitiveMemberOf" /><Obj N="AdditionalProperties" RefId="1"><TN RefId="1"><T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.Object, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T><T>System.Object</T></TN><DCT /></Obj></Props></Obj></Objs>') } -ParameterFilter { $Filter -eq "appId eq '10000000-0000-0000-0000-000000000001'" -or $ServicePrincipalId -eq '20000000-0000-0000-0000-000000000002' } -Verifiable
        Mock -ModuleName $PSModule.Name Get-MgServicePrincipal {  } -Verifiable
        Mock -ModuleName $PSModule.Name Get-MgServicePrincipalOauth2PermissionGrant { [System.Management.Automation.PSSerializer]::Deserialize('<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj RefId="0"><TN RefId="0"><T>System.Object[]</T><T>System.Array</T><T>System.Object</T></TN><LST><Obj RefId="1"><TN RefId="1"><T>Microsoft.Graph.PowerShell.Models.MicrosoftGraphOAuth2PermissionGrant</T><T>System.Object</T></TN><ToString>Microsoft.Graph.PowerShell.Models.MicrosoftGraphOAuth2PermissionGrant</ToString><Props><S N="ClientId">20000000-0000-0000-0000-000000000002</S><S N="ConsentType">AllPrincipals</S><S N="Id">2_1D6n4jzkWFZnZNXFFSqbLLSLAyJXJPv1vJSwSQvso</S><Nil N="PrincipalId" /><S N="ResourceId">b048cbb2-2532-4f72-bf5b-c94b0490beca</S><S N="Scope"> openid offline_access</S><Obj N="AdditionalProperties" RefId="2"><TN RefId="2"><T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.Object, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T><T>System.Object</T></TN><DCT /></Obj></Props></Obj><Obj RefId="3"><TNRef RefId="1" /><ToString>Microsoft.Graph.PowerShell.Models.MicrosoftGraphOAuth2PermissionGrant</ToString><Props><S N="ClientId">20000000-0000-0000-0000-000000000002</S><S N="ConsentType">Principal</S><S N="Id">2_1D6n4jzkWFZnZNXFFSqbLLSLAyJXJPv1vJSwSQvsr2vtBrR3RLTohZ5rhtJn7n</S><S N="PrincipalId">50000000-0000-0000-0000-000000000005</S><S N="ResourceId">b048cbb2-2532-4f72-bf5b-c94b0490beca</S><S N="Scope"> openid profile offline_access User.Read</S><Obj N="AdditionalProperties" RefId="4"><TNRef RefId="2" /><DCT /></Obj></Props></Obj></LST></Obj></Objs>') } -Verifiable
        Mock -ModuleName $PSModule.Name Update-MgOauth2PermissionGrant {  } -Verifiable
        Mock -ModuleName $PSModule.Name Remove-MgOauth2PermissionGrant {  } -Verifiable

        ## Test Cases
        $TestCases = @(
            @{ ClientId = '10000000-0000-0000-0000-000000000001'; PrincipalId = '50000000-0000-0000-0000-000000000005' }
            @{ ClientId = '20000000-0000-0000-0000-000000000002'; AdminConsentDelegated = $true }
            @{ ClientId = '20000000-0000-0000-0000-000000000002'; PrincipalId = '50000000-0000-0000-0000-000000000005'; AdminConsentDelegated = $true }
            @{ ClientId = '20000000-0000-0000-0000-000000000002'; All = $true }
            @{ ClientId = '20000000-0000-0000-0000-000000000002'; Scope = 'User.Read.All'; All = $true }
        )
    }

    Context 'ClientId: <ClientId>' -ForEach @(
        @{ ClientId = '10000000-0000-0000-0000-000000000001'; PrincipalId = '50000000-0000-0000-0000-000000000005' }
        @{ ClientId = '20000000-0000-0000-0000-000000000002'; AdminConsentDelegated = $true }
        @{ ClientId = '20000000-0000-0000-0000-000000000002'; PrincipalId = '50000000-0000-0000-0000-000000000005'; AdminConsentDelegated = $true }
        @{ ClientId = '20000000-0000-0000-0000-000000000002'; All = $true }
        @{ ClientId = '20000000-0000-0000-0000-000000000002'; Scope = 'User.Read.All'; All = $true }
    ) {
        BeforeAll {
            $script:params = $_.Clone()
            $script:params.Remove('ClientId')
        }

        It 'Positional Parameter' {
            $Output = Revoke-MsIdServicePrincipalConsent $ClientId @params -ErrorVariable actualErrors
            $Output | Should -BeNullOrEmpty
            Should -Invoke Test-MgCommandPrerequisites -ModuleName $PSModule.Name
            Should -Invoke Get-MgServicePrincipal -ModuleName $PSModule.Name -ParameterFilter {
                $Filter -eq "appId eq '$ClientId'"
            }
            $actualErrors | Should -HaveCount 0
        }

        It 'Pipeline Input' {
            $Output = $ClientId | Revoke-MsIdServicePrincipalConsent @params -ErrorVariable actualErrors
            $Output | Should -BeNullOrEmpty
            Should -Invoke Test-MgCommandPrerequisites -ModuleName $PSModule.Name
            Should -Invoke Get-MgServicePrincipal -ModuleName $PSModule.Name -ParameterFilter {
                $Filter -eq "appId eq '$ClientId'"
            }
            $actualErrors | Should -HaveCount 0
        }
    }

    Context 'Multiple Input' {
        It 'Positional Parameter' {
            $Output = Revoke-MsIdServicePrincipalConsent $TestCases.ClientId -All -ErrorVariable actualErrors
            $Output | Should -BeNullOrEmpty
            Should -Invoke Test-MgCommandPrerequisites -ModuleName $PSModule.Name
            for ($i = 0; $i -lt $TestCases.Count; $i++) {
                Should -Invoke Get-MgServicePrincipal -ModuleName $PSModule.Name -ParameterFilter {
                    $Filter -eq "appId eq '$($TestCases[$i].ClientId)'"
                }
            }
            $actualErrors | Should -HaveCount 0
        }

        It 'Pipeline Input' {
            $Output = $TestCases.ClientId | Revoke-MsIdServicePrincipalConsent -All -ErrorVariable actualErrors
            $Output | Should -BeNullOrEmpty
            Should -Invoke Test-MgCommandPrerequisites -ModuleName $PSModule.Name
            for ($i = 0; $i -lt $TestCases.Count; $i++) {
                Should -Invoke Get-MgServicePrincipal -ModuleName $PSModule.Name -ParameterFilter {
                    $Filter -eq "appId eq '$($TestCases[$i].ClientId)'"
                }
            }
            $actualErrors | Should -HaveCount 0
        }
    }
    
}
