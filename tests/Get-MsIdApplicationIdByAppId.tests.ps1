[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $ModulePath = ".\src\*.psd1"
)

BeforeDiscovery {
    # Loads and registers my custom assertion. Ignores usage of unapproved verb with -DisableNameChecking
    Import-Module ".\build\PesterCustomAssertions.psm1" -DisableNameChecking
}

BeforeAll {
    $CriticalError = $null
    $PSModule = Import-Module $ModulePath -Force -PassThru -ErrorVariable CriticalError
    if ($CriticalError) { throw $CriticalError }
}

## Perform Tests
Describe 'Get-MsIdApplicationIdByAppId' {
    
    BeforeAll {
        ## Stub functions required when actual command is not available
        InModuleScope $PSModule.Name {
            if (!(Get-Command Get-MgApplication -ErrorAction SilentlyContinue)) {
                function script:Get-MgApplication ($Filter) { throw "The term '$($MyInvocation.MyCommand)' is not recognized as the name of a cmdlet, function, or operable program and there is no mock defined." }
            }
        }

        ## Mock commands with external dependancies or unavailable commands
        # Get Mock Sample When Type Does Not Exist: "[System.Management.Automation.PSSerializer]::Deserialize('{0}')" -f ([xml][System.Management.Automation.PSSerializer]::Serialize($psobject, 2)).OuterXml.Replace("'","''") | Set-Clipboard
        Mock -ModuleName $PSModule.Name Get-MgApplication { [System.Management.Automation.PSSerializer]::Deserialize('<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj RefId="0"><TN RefId="0"><T>Microsoft.Graph.PowerShell.Models.MicrosoftGraphApplication1</T><T>System.Object</T></TN><ToString>Microsoft.Graph.PowerShell.Models.MicrosoftGraphApplication1</ToString><Props><Nil N="AddIns" /><S N="Api">Microsoft.Graph.PowerShell.Models.MicrosoftGraphApiApplication</S><Nil N="AppId" /><Nil N="AppRoles" /><Nil N="ApplicationTemplateId" /><S N="Certification">Microsoft.Graph.PowerShell.Models.MicrosoftGraphCertification</S><Nil N="CreatedDateTime" /><S N="CreatedOnBehalfOf">Microsoft.Graph.PowerShell.Models.MicrosoftGraphDirectoryObject</S><Nil N="DeletedDateTime" /><Nil N="Description" /><Nil N="DisabledByMicrosoftStatus" /><Nil N="DisplayName" /><Nil N="ExtensionProperties" /><Nil N="GroupMembershipClaims" /><Nil N="HomeRealmDiscoveryPolicies" /><S N="Id">20000000-0000-0000-0000-000000000002</S><Nil N="IdentifierUris" /><S N="Info">Microsoft.Graph.PowerShell.Models.MicrosoftGraphInformationalUrl</S><Nil N="IsDeviceOnlyAuthSupported" /><Nil N="IsFallbackPublicClient" /><Nil N="KeyCredentials" /><Nil N="Logo" /><Nil N="Notes" /><Nil N="Oauth2RequirePostResponse" /><S N="OptionalClaims">Microsoft.Graph.PowerShell.Models.MicrosoftGraphOptionalClaims</S><Nil N="Owners" /><S N="ParentalControlSettings">Microsoft.Graph.PowerShell.Models.MicrosoftGraphParentalControlSettings</S><Nil N="PasswordCredentials" /><S N="PublicClient">Microsoft.Graph.PowerShell.Models.MicrosoftGraphPublicClientApplication</S><Nil N="PublisherDomain" /><Nil N="RequiredResourceAccess" /><Nil N="ServiceManagementReference" /><Nil N="SignInAudience" /><S N="Spa">Microsoft.Graph.PowerShell.Models.MicrosoftGraphSpaApplication</S><Nil N="Tags" /><Nil N="TokenEncryptionKeyId" /><Nil N="TokenIssuancePolicies" /><Nil N="TokenLifetimePolicies" /><S N="VerifiedPublisher">Microsoft.Graph.PowerShell.Models.MicrosoftGraphVerifiedPublisher</S><S N="Web">Microsoft.Graph.PowerShell.Models.MicrosoftGraphWebApplication</S><Obj N="AdditionalProperties" RefId="1"><TN RefId="1"><T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.Object, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T><T>System.Object</T></TN><DCT /></Obj></Props></Obj></Objs>') } -ParameterFilter { $Filter.Equals("appId eq '10000000-0000-0000-0000-000000000001'") } -Verifiable
        Mock -ModuleName $PSModule.Name Get-MgApplication { [System.Management.Automation.PSSerializer]::Deserialize('<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj RefId="0"><TN RefId="0"><T>Microsoft.Graph.PowerShell.Models.MicrosoftGraphApplication1</T><T>System.Object</T></TN><ToString>Microsoft.Graph.PowerShell.Models.MicrosoftGraphApplication1</ToString><Props><Nil N="AddIns" /><S N="Api">Microsoft.Graph.PowerShell.Models.MicrosoftGraphApiApplication</S><Nil N="AppId" /><Nil N="AppRoles" /><Nil N="ApplicationTemplateId" /><S N="Certification">Microsoft.Graph.PowerShell.Models.MicrosoftGraphCertification</S><Nil N="CreatedDateTime" /><S N="CreatedOnBehalfOf">Microsoft.Graph.PowerShell.Models.MicrosoftGraphDirectoryObject</S><Nil N="DeletedDateTime" /><Nil N="Description" /><Nil N="DisabledByMicrosoftStatus" /><Nil N="DisplayName" /><Nil N="ExtensionProperties" /><Nil N="GroupMembershipClaims" /><Nil N="HomeRealmDiscoveryPolicies" /><S N="Id">40000000-0000-0000-0000-000000000004</S><Nil N="IdentifierUris" /><S N="Info">Microsoft.Graph.PowerShell.Models.MicrosoftGraphInformationalUrl</S><Nil N="IsDeviceOnlyAuthSupported" /><Nil N="IsFallbackPublicClient" /><Nil N="KeyCredentials" /><Nil N="Logo" /><Nil N="Notes" /><Nil N="Oauth2RequirePostResponse" /><S N="OptionalClaims">Microsoft.Graph.PowerShell.Models.MicrosoftGraphOptionalClaims</S><Nil N="Owners" /><S N="ParentalControlSettings">Microsoft.Graph.PowerShell.Models.MicrosoftGraphParentalControlSettings</S><Nil N="PasswordCredentials" /><S N="PublicClient">Microsoft.Graph.PowerShell.Models.MicrosoftGraphPublicClientApplication</S><Nil N="PublisherDomain" /><Nil N="RequiredResourceAccess" /><Nil N="ServiceManagementReference" /><Nil N="SignInAudience" /><S N="Spa">Microsoft.Graph.PowerShell.Models.MicrosoftGraphSpaApplication</S><Nil N="Tags" /><Nil N="TokenEncryptionKeyId" /><Nil N="TokenIssuancePolicies" /><Nil N="TokenLifetimePolicies" /><S N="VerifiedPublisher">Microsoft.Graph.PowerShell.Models.MicrosoftGraphVerifiedPublisher</S><S N="Web">Microsoft.Graph.PowerShell.Models.MicrosoftGraphWebApplication</S><Obj N="AdditionalProperties" RefId="1"><TN RefId="1"><T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.Object, System.Private.CoreLib, Version=6.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T><T>System.Object</T></TN><DCT /></Obj></Props></Obj></Objs>') } -ParameterFilter { $Filter.Equals("appId eq '30000000-0000-0000-0000-000000000003'") } -Verifiable

        ## Test Cases
        $TestCases = @(
            @{ AppId = '10000000-0000-0000-0000-000000000001'; Expected = '20000000-0000-0000-0000-000000000002' }
            @{ AppId = '30000000-0000-0000-0000-000000000003'; Expected = '40000000-0000-0000-0000-000000000004' }
        )
    }

    Context 'AppId: <AppId>' -Foreach @(
        @{ AppId = '10000000-0000-0000-0000-000000000001'; Expected = '20000000-0000-0000-0000-000000000002' }
        @{ AppId = '30000000-0000-0000-0000-000000000003'; Expected = '40000000-0000-0000-0000-000000000004' }
    ) {
        BeforeAll {
            Mock -ModuleName $PSModule.Name Test-MgCommand { $true } -Verifiable
        }

        It 'Positional Parameter' {
            $Output = Get-MsIdApplicationIdByAppId $AppId -ErrorVariable actualErrors
            $Output | Should -BeOfType [string]
            $Output | Should -BeExactly $Expected
            Should -Invoke Get-MgApplication -ModuleName $PSModule.Name -ParameterFilter {
                $Filter -eq "appId eq '$AppId'"
            }
            $actualErrors | Should -HaveCount 0
        }

        It 'Pipeline Input' {
            $Output = $AppId | Get-MsIdApplicationIdByAppId -ErrorVariable actualErrors
            $Output | Should -BeOfType [string]
            $Output | Should -BeExactly $Expected
            Should -Invoke Get-MgApplication -ModuleName $PSModule.Name -ParameterFilter {
                $Filter -eq "appId eq '$AppId'"
            }
            $actualErrors | Should -HaveCount 0
        }
    }

    Context 'Multiple Input' {
        BeforeAll {
            Mock -ModuleName $PSModule.Name Test-MgCommand { $true } -Verifiable
        }
        
        It 'Positional Parameter' {
            $Output = Get-MsIdApplicationIdByAppId $TestCases.AppId -ErrorVariable actualErrors
            $Output | Should -BeOfType [string]
            $Output | Should -HaveCount $TestCases.Count
            for ($i = 0; $i -lt $TestCases.Count; $i++) {
                $Output[$i] | Should -BeExactly $TestCases[$i].Expected
                Should -Invoke Get-MgApplication -ModuleName $PSModule.Name -ParameterFilter {
                    $Filter -eq "appId eq '$($TestCases[$i].AppId)'"
                }
            }
            $actualErrors | Should -HaveCount 0
        }

        It 'Pipeline Input' {
            $Output = $TestCases.AppId | Get-MsIdApplicationIdByAppId -ErrorVariable actualErrors
            $Output | Should -BeOfType [string]
            $Output | Should -HaveCount $TestCases.Count
            for ($i = 0; $i -lt $TestCases.Count; $i++) {
                $Output[$i] | Should -BeExactly $TestCases[$i].Expected
                Should -Invoke Get-MgApplication -ModuleName $PSModule.Name -ParameterFilter {
                    $Filter -eq "appId eq '$($TestCases[$i].AppId)'"
                }
            }
            $actualErrors | Should -HaveCount 0
        }
    }

    Context 'Error Conditions' {
        BeforeAll {
            Mock -ModuleName $PSModule.Name Import-Module { Import-Module 'Microsoft.Graph.ModuleNotFound' -ErrorAction SilentlyContinue } -Verifiable
            Mock -ModuleName $PSModule.Name Get-MgContext { } -Verifiable
        }

        It 'Missing module' {
            $Command = { Get-MsIdServicePrincipalIdByAppId (New-Guid) -ErrorAction SilentlyContinue }
            $Command | Should -WriteError -ErrorId "Modules_Module*NotFound*" -ExceptionType ([System.IO.FileNotFoundException])
        }

        It 'No authentication' {
            $Command = { Get-MsIdServicePrincipalIdByAppId (New-Guid) -ErrorAction SilentlyContinue }
            $Command | Should -WriteError -ErrorId "MgAuthenticationRequired*" -ExceptionType ([System.Security.Authentication.AuthenticationException])
        }

        It 'Missing scopes' {
            Mock -ModuleName $PSModule.Name Get-MgContext { New-Object Microsoft.Graph.PowerShell.Authentication.AuthContext -Property @{ Scopes = @('openid', 'profile', 'User.Read', 'email'); AppName = 'Microsoft Graph PowerShell'; PSHostVersion = $PSVersionTable['PSVersion'] } } -Verifiable
            $Command = { Get-MsIdServicePrincipalIdByAppId (New-Guid) -ErrorAction SilentlyContinue }
            $Command | Should -WriteError -ErrorId "MgScopePermissionRequired*" -ExceptionType ([System.Security.SecurityException])
        }
    }
}
