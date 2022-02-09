[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $ModulePath = "..\src\*.psd1"
)

BeforeAll {
    Import-Module $ModulePath -Force
}

## Perform Tests
Describe 'Get-MSIDAuthorityUri' {

    Context 'Common' {
        It 'Default Parameters' {
            $Output = Get-MSIDAuthorityUri
            $Output | Should -Be 'https://login.microsoftonline.com/common/v2.0'
        }

        It 'AppType Saml' {
            $Output = Get-MSIDAuthorityUri -AppType Saml
            $Output | Should -Be 'https://login.microsoftonline.com/common'
        }

        It 'TenantName' {
            $Output = Get-MSIDAuthorityUri -TenantName 'contoso'
            $Output | Should -Be 'https://login.microsoftonline.com/contoso.onmicrosoft.com/v2.0'
        }

        It 'TenantId Domain' {
            $Output = Get-MSIDAuthorityUri -TenantId 'contoso.onmicrosoft.com'
            $Output | Should -Be 'https://login.microsoftonline.com/contoso.onmicrosoft.com/v2.0'
        }

        It 'TenantId GUID' {
            $Output = Get-MSIDAuthorityUri -TenantId ([guid]'00000000-0000-0000-0000-000000000000')
            $Output | Should -Be 'https://login.microsoftonline.com/00000000-0000-0000-0000-000000000000/v2.0'
        }
    }

    Context 'Azure AD' {
        It 'TenantName' {
            $Output = Get-MSIDAuthorityUri -AzureAd -TenantName 'contoso'
            $Output | Should -Be 'https://login.microsoftonline.com/contoso.onmicrosoft.com/v2.0'
        }

        It 'TenantId Domain' {
            $Output = Get-MSIDAuthorityUri -AzureAd -TenantId 'contoso.onmicrosoft.com'
            $Output | Should -Be 'https://login.microsoftonline.com/contoso.onmicrosoft.com/v2.0'
        }
    }

    Context 'Azure AD B2C' {
        It 'TenantName' {
            $Output = Get-MSIDAuthorityUri -AzureAdB2c -TenantName 'contoso' -Policy 'B2C_1_SignUpSignIn'
            $Output | Should -Be 'https://contoso.b2clogin.com/contoso.onmicrosoft.com/B2C_1_SignUpSignIn/v2.0'
        }

        It 'TenantId Domain' {
            $Output = Get-MSIDAuthorityUri -AzureAdB2c -TenantName 'contoso' -TenantId 'contoso2.onmicrosoft.com' -Policy 'B2C_1_SignUpSignIn'
            $Output | Should -Be 'https://contoso.b2clogin.com/contoso2.onmicrosoft.com/B2C_1_SignUpSignIn/v2.0'
        }
    }

    Context 'MSA' {
        It 'Default Parameters' {
            $Output = Get-MSIDAuthorityUri -Msa
            $Output | Should -Be 'https://login.microsoftonline.com/consumers/v2.0'
        }
    }

}
