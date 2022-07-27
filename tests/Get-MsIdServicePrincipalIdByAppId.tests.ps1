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
Describe 'Get-MsIdServicePrincipalIdByAppId' {
    
    BeforeAll {
        Mock -ModuleName $PSModule.Name Test-MgCommand { $true } -Verifiable
        #Get Mock: ([xml][System.Management.Automation.PSSerializer]::Serialize($psobject)).OuterXml | Set-Clipboard
        Mock -ModuleName $PSModule.Name Get-MgServicePrincipal { [System.Management.Automation.PSSerializer]::Deserialize('<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj RefId="0"><TN RefId="0"><T>Microsoft.Graph.PowerShell.Models.MicrosoftGraphServicePrincipal</T><T>System.Object</T></TN><ToString>Microsoft.Graph.PowerShell.Models.MicrosoftGraphServicePrincipal</ToString><Props><Nil N="AccountEnabled" /><Nil N="AddIns" /><Nil N="AlternativeNames" /><Nil N="AppDescription" /><Nil N="AppDisplayName" /><Nil N="AppId" /><Nil N="AppOwnerOrganizationId" /><Nil N="AppRoleAssignedTo" /><Nil N="AppRoleAssignmentRequired" /><Nil N="AppRoleAssignments" /><Nil N="AppRoles" /><Nil N="ApplicationTemplateId" /><Nil N="ClaimsMappingPolicies" /><Nil N="CreatedObjects" /><Nil N="DelegatedPermissionClassifications" /><Nil N="DeletedDateTime" /><Nil N="Description" /><Nil N="DisabledByMicrosoftStatus" /><Nil N="DisplayName" /><Nil N="Endpoints" /><Nil N="HomeRealmDiscoveryPolicies" /><Nil N="Homepage" /><S N="Id">20000000-0000-0000-0000-000000000002</S><S N="Info">Microsoft.Graph.PowerShell.Models.MicrosoftGraphInformationalUrl</S><Nil N="KeyCredentials" /><Nil N="LoginUrl" /><Nil N="LogoutUrl" /><Nil N="MemberOf" /><Nil N="Notes" /><Nil N="NotificationEmailAddresses" /><Nil N="Oauth2PermissionGrants" /><Nil N="Oauth2PermissionScopes" /><Nil N="OwnedObjects" /><Nil N="Owners" /><Nil N="PasswordCredentials" /><Nil N="PreferredSingleSignOnMode" /><Nil N="PreferredTokenSigningKeyThumbprint" /><Nil N="ReplyUrls" /><Nil N="ResourceSpecificApplicationPermissions" /><S N="SamlSingleSignOnSettings">Microsoft.Graph.PowerShell.Models.MicrosoftGraphSamlSingleSignOnSettings</S><Nil N="ServicePrincipalNames" /><Nil N="ServicePrincipalType" /><Nil N="SignInAudience" /><Nil N="Tags" /><Nil N="TokenEncryptionKeyId" /><Nil N="TokenIssuancePolicies" /><Nil N="TokenLifetimePolicies" /><Nil N="TransitiveMemberOf" /><Obj N="AdditionalProperties" RefId="1"><TN RefId="1"><T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.Object, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T><T>System.Object</T></TN><DCT /></Obj></Props></Obj></Objs>') } -ParameterFilter { $Filter.Equals("appId eq '10000000-0000-0000-0000-000000000001'") } -Verifiable
        Mock -ModuleName $PSModule.Name Get-MgServicePrincipal { [System.Management.Automation.PSSerializer]::Deserialize('<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj RefId="0"><TN RefId="0"><T>Microsoft.Graph.PowerShell.Models.MicrosoftGraphServicePrincipal</T><T>System.Object</T></TN><ToString>Microsoft.Graph.PowerShell.Models.MicrosoftGraphServicePrincipal</ToString><Props><Nil N="AccountEnabled" /><Nil N="AddIns" /><Nil N="AlternativeNames" /><Nil N="AppDescription" /><Nil N="AppDisplayName" /><Nil N="AppId" /><Nil N="AppOwnerOrganizationId" /><Nil N="AppRoleAssignedTo" /><Nil N="AppRoleAssignmentRequired" /><Nil N="AppRoleAssignments" /><Nil N="AppRoles" /><Nil N="ApplicationTemplateId" /><Nil N="ClaimsMappingPolicies" /><Nil N="CreatedObjects" /><Nil N="DelegatedPermissionClassifications" /><Nil N="DeletedDateTime" /><Nil N="Description" /><Nil N="DisabledByMicrosoftStatus" /><Nil N="DisplayName" /><Nil N="Endpoints" /><Nil N="HomeRealmDiscoveryPolicies" /><Nil N="Homepage" /><S N="Id">40000000-0000-0000-0000-000000000004</S><S N="Info">Microsoft.Graph.PowerShell.Models.MicrosoftGraphInformationalUrl</S><Nil N="KeyCredentials" /><Nil N="LoginUrl" /><Nil N="LogoutUrl" /><Nil N="MemberOf" /><Nil N="Notes" /><Nil N="NotificationEmailAddresses" /><Nil N="Oauth2PermissionGrants" /><Nil N="Oauth2PermissionScopes" /><Nil N="OwnedObjects" /><Nil N="Owners" /><Nil N="PasswordCredentials" /><Nil N="PreferredSingleSignOnMode" /><Nil N="PreferredTokenSigningKeyThumbprint" /><Nil N="ReplyUrls" /><Nil N="ResourceSpecificApplicationPermissions" /><S N="SamlSingleSignOnSettings">Microsoft.Graph.PowerShell.Models.MicrosoftGraphSamlSingleSignOnSettings</S><Nil N="ServicePrincipalNames" /><Nil N="ServicePrincipalType" /><Nil N="SignInAudience" /><Nil N="Tags" /><Nil N="TokenEncryptionKeyId" /><Nil N="TokenIssuancePolicies" /><Nil N="TokenLifetimePolicies" /><Nil N="TransitiveMemberOf" /><Obj N="AdditionalProperties" RefId="1"><TN RefId="1"><T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.Object, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T><T>System.Object</T></TN><DCT /></Obj></Props></Obj></Objs>') } -ParameterFilter { $Filter.Equals("appId eq '30000000-0000-0000-0000-000000000003'") } -Verifiable

        $TestCases = @(
            @{ AppId = '10000000-0000-0000-0000-000000000001'; Expected = '20000000-0000-0000-0000-000000000002' }
            @{ AppId = '30000000-0000-0000-0000-000000000003'; Expected = '40000000-0000-0000-0000-000000000004' }
        )
    }

    Context 'AppId: <AppId>' -Foreach @(
        @{ AppId = '10000000-0000-0000-0000-000000000001'; Expected = '20000000-0000-0000-0000-000000000002' }
        @{ AppId = '30000000-0000-0000-0000-000000000003'; Expected = '40000000-0000-0000-0000-000000000004' }
    ) {
        It 'Positional Parameter' {
            $Output = Get-MsIdServicePrincipalIdByAppId $AppId
            $Output | Should -BeOfType [string]
            $Output | Should -BeExactly $Expected
            Should -Invoke Get-MgServicePrincipal -ModuleName $PSModule.Name -ParameterFilter {
                $Filter -eq "appId eq '$AppId'"
            }
        }

        It 'Pipeline Input' {
            $Output = $AppId | Get-MsIdServicePrincipalIdByAppId
            $Output | Should -BeOfType [string]
            $Output | Should -BeExactly $Expected
            Should -Invoke Get-MgServicePrincipal -ModuleName $PSModule.Name -ParameterFilter {
                $Filter -eq "appId eq '$AppId'"
            }
        }
    }

    Context 'Multiple Input' {
        It 'Positional Parameter' {
            $Output = Get-MsIdServicePrincipalIdByAppId $TestCases.AppId
            $Output | Should -BeOfType [string]
            $Output | Should -HaveCount $TestCases.Count
            for ($i = 0; $i -lt $TestCases.Count; $i++) {
                $Output[$i] | Should -BeExactly $TestCases[$i].Expected
                Should -Invoke Get-MgServicePrincipal -ModuleName $PSModule.Name -ParameterFilter {
                    $Filter -eq "appId eq '$($TestCases[$i].AppId)'"
                }
            }
        }

        It 'Pipeline Input' {
            $Output = $TestCases.AppId | Get-MsIdServicePrincipalIdByAppId
            $Output | Should -BeOfType [string]
            $Output | Should -HaveCount $TestCases.Count
            for ($i = 0; $i -lt $TestCases.Count; $i++) {
                $Output[$i] | Should -BeExactly $TestCases[$i].Expected
                Should -Invoke Get-MgServicePrincipal -ModuleName $PSModule.Name -ParameterFilter {
                    $Filter -eq "appId eq '$($TestCases[$i].AppId)'"
                }
            }
        }
    }
}
