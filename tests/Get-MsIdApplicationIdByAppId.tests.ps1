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
Describe 'Get-MsIdApplicationIdByAppId' {
    
    BeforeAll {
        Mock -ModuleName $PSModule.Name Test-MgCommand { $true } -Verifiable
        Mock -ModuleName $PSModule.Name Get-MgApplication { [System.Management.Automation.PSSerializer]::Deserialize('<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj RefId="0"><TN RefId="0"><T>Microsoft.Graph.PowerShell.Models.MicrosoftGraphApplication1</T><T>System.Object</T></TN><ToString>Microsoft.Graph.PowerShell.Models.MicrosoftGraphApplication1</ToString><Props><Nil N="AddIns" /><S N="Api">Microsoft.Graph.PowerShell.Models.MicrosoftGraphApiApplication</S><Nil N="AppId" /><Nil N="AppRoles" /><Nil N="ApplicationTemplateId" /><S N="Certification">Microsoft.Graph.PowerShell.Models.MicrosoftGraphCertification</S><Nil N="CreatedDateTime" /><S N="CreatedOnBehalfOf">Microsoft.Graph.PowerShell.Models.MicrosoftGraphDirectoryObject</S><Nil N="DeletedDateTime" /><Nil N="Description" /><Nil N="DisabledByMicrosoftStatus" /><Nil N="DisplayName" /><Nil N="ExtensionProperties" /><Nil N="GroupMembershipClaims" /><Nil N="HomeRealmDiscoveryPolicies" /><S N="Id">20000000-0000-0000-0000-000000000002</S><Nil N="IdentifierUris" /><S N="Info">Microsoft.Graph.PowerShell.Models.MicrosoftGraphInformationalUrl</S><Nil N="IsDeviceOnlyAuthSupported" /><Nil N="IsFallbackPublicClient" /><Nil N="KeyCredentials" /><Nil N="Logo" /><Nil N="Notes" /><Nil N="Oauth2RequirePostResponse" /><S N="OptionalClaims">Microsoft.Graph.PowerShell.Models.MicrosoftGraphOptionalClaims</S><Nil N="Owners" /><S N="ParentalControlSettings">Microsoft.Graph.PowerShell.Models.MicrosoftGraphParentalControlSettings</S><Nil N="PasswordCredentials" /><S N="PublicClient">Microsoft.Graph.PowerShell.Models.MicrosoftGraphPublicClientApplication</S><Nil N="PublisherDomain" /><Nil N="RequiredResourceAccess" /><Nil N="ServiceManagementReference" /><Nil N="SignInAudience" /><S N="Spa">Microsoft.Graph.PowerShell.Models.MicrosoftGraphSpaApplication</S><Nil N="Tags" /><Nil N="TokenEncryptionKeyId" /><Nil N="TokenIssuancePolicies" /><Nil N="TokenLifetimePolicies" /><S N="VerifiedPublisher">Microsoft.Graph.PowerShell.Models.MicrosoftGraphVerifiedPublisher</S><S N="Web">Microsoft.Graph.PowerShell.Models.MicrosoftGraphWebApplication</S><Obj N="AdditionalProperties" RefId="1"><TN RefId="1"><T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.Object, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T><T>System.Object</T></TN><DCT /></Obj></Props></Obj></Objs>') } -ParameterFilter { $Filter.Equals("appId eq '10000000-0000-0000-0000-000000000001'") } -Verifiable
        Mock -ModuleName $PSModule.Name Get-MgApplication { [System.Management.Automation.PSSerializer]::Deserialize('<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj RefId="0"><TN RefId="0"><T>Microsoft.Graph.PowerShell.Models.MicrosoftGraphApplication1</T><T>System.Object</T></TN><ToString>Microsoft.Graph.PowerShell.Models.MicrosoftGraphApplication1</ToString><Props><Nil N="AddIns" /><S N="Api">Microsoft.Graph.PowerShell.Models.MicrosoftGraphApiApplication</S><Nil N="AppId" /><Nil N="AppRoles" /><Nil N="ApplicationTemplateId" /><S N="Certification">Microsoft.Graph.PowerShell.Models.MicrosoftGraphCertification</S><Nil N="CreatedDateTime" /><S N="CreatedOnBehalfOf">Microsoft.Graph.PowerShell.Models.MicrosoftGraphDirectoryObject</S><Nil N="DeletedDateTime" /><Nil N="Description" /><Nil N="DisabledByMicrosoftStatus" /><Nil N="DisplayName" /><Nil N="ExtensionProperties" /><Nil N="GroupMembershipClaims" /><Nil N="HomeRealmDiscoveryPolicies" /><S N="Id">40000000-0000-0000-0000-000000000004</S><Nil N="IdentifierUris" /><S N="Info">Microsoft.Graph.PowerShell.Models.MicrosoftGraphInformationalUrl</S><Nil N="IsDeviceOnlyAuthSupported" /><Nil N="IsFallbackPublicClient" /><Nil N="KeyCredentials" /><Nil N="Logo" /><Nil N="Notes" /><Nil N="Oauth2RequirePostResponse" /><S N="OptionalClaims">Microsoft.Graph.PowerShell.Models.MicrosoftGraphOptionalClaims</S><Nil N="Owners" /><S N="ParentalControlSettings">Microsoft.Graph.PowerShell.Models.MicrosoftGraphParentalControlSettings</S><Nil N="PasswordCredentials" /><S N="PublicClient">Microsoft.Graph.PowerShell.Models.MicrosoftGraphPublicClientApplication</S><Nil N="PublisherDomain" /><Nil N="RequiredResourceAccess" /><Nil N="ServiceManagementReference" /><Nil N="SignInAudience" /><S N="Spa">Microsoft.Graph.PowerShell.Models.MicrosoftGraphSpaApplication</S><Nil N="Tags" /><Nil N="TokenEncryptionKeyId" /><Nil N="TokenIssuancePolicies" /><Nil N="TokenLifetimePolicies" /><S N="VerifiedPublisher">Microsoft.Graph.PowerShell.Models.MicrosoftGraphVerifiedPublisher</S><S N="Web">Microsoft.Graph.PowerShell.Models.MicrosoftGraphWebApplication</S><Obj N="AdditionalProperties" RefId="1"><TN RefId="1"><T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.Object, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T><T>System.Object</T></TN><DCT /></Obj></Props></Obj></Objs>') } -ParameterFilter { $Filter.Equals("appId eq '30000000-0000-0000-0000-000000000003'") } -Verifiable

        $TestCases = @(
            @{ AppId = '10000000-0000-0000-0000-000000000001'; Expected = '20000000-0000-0000-0000-000000000002' }
            @{ AppId = '30000000-0000-0000-0000-000000000003'; Expected = '40000000-0000-0000-0000-000000000004' }
        )
    }

    Context 'Issuer: <Issuer>' -Foreach @(
        @{ AppId = '10000000-0000-0000-0000-000000000001'; Expected = '20000000-0000-0000-0000-000000000002' }
        @{ AppId = '30000000-0000-0000-0000-000000000003'; Expected = '40000000-0000-0000-0000-000000000004' }
    ) {
        It 'Positional Parameter' {
            $Output = Get-MsIdApplicationIdByAppId $AppId
            $Output | Should -BeOfType [string]
            $Output | Should -BeExactly $Expected
            Should -Invoke Get-MgApplication -ModuleName $PSModule.Name -ParameterFilter {
                $Filter -eq "appId eq '$AppId'"
            }
        }

        It 'Pipeline Input' {
            $Output = $AppId | Get-MsIdApplicationIdByAppId
            $Output | Should -BeOfType [string]
            $Output | Should -BeExactly $Expected
            Should -Invoke Get-MgApplication -ModuleName $PSModule.Name -ParameterFilter {
                $Filter -eq "appId eq '$AppId'"
            }
        }
    }

    Context 'Multiple Input' {
        It 'Positional Parameter' {
            $Output = Get-MsIdApplicationIdByAppId $TestCases.AppId
            $Output | Should -BeOfType [string]
            $Output | Should -HaveCount $TestCases.Count
            for ($i = 0; $i -lt $TestCases.Count; $i++) {
                $Output[$i] | Should -BeExactly $TestCases[$i].Expected
                Should -Invoke Get-MgApplication -ModuleName $PSModule.Name -ParameterFilter {
                    $Filter -eq "appId eq '$($TestCases[$i].AppId)'"
                }
            }
        }

        It 'Pipeline Input' {
            $Output = $TestCases.AppId | Get-MsIdApplicationIdByAppId
            $Output | Should -BeOfType [string]
            $Output | Should -HaveCount $TestCases.Count
            for ($i = 0; $i -lt $TestCases.Count; $i++) {
                $Output[$i] | Should -BeExactly $TestCases[$i].Expected
                Should -Invoke Get-MgApplication -ModuleName $PSModule.Name -ParameterFilter {
                    $Filter -eq "appId eq '$($TestCases[$i].AppId)'"
                }
            }
        }
    }
}
