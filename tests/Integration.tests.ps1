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
Describe 'MgCommand' -Tag 'IntegrationTest' {
    
    BeforeAll {
        ## Stub functions required when actual command is not available
        # InModuleScope $PSModule.Name {
        #     if (!(Get-Command Get-MgServicePrincipal -ErrorAction SilentlyContinue)) {
        #         function script:Get-MgServicePrincipal ($Filter) { throw "The term '$($MyInvocation.MyCommand)' is not recognized as the name of a cmdlet, function, or operable program and there is no mock defined." }
        #     }
        # }

        ## Mock commands with external dependancies or unavailable commands
        # ToDo: Integration test should perform real authentication and module import
        Mock -ModuleName $PSModule.Name Get-MgContext { New-Object Microsoft.Graph.PowerShell.Authentication.AuthContext -Property @{ Scopes = @('email', 'openid', 'profile', 'User.Read', 'User.Read.All'); AppName = 'Microsoft Graph PowerShell'; PSHostVersion = $PSVersionTable['PSVersion'] } } -Verifiable
        Mock -ModuleName $PSModule.Name Import-Module { } -Verifiable

        ## Test Cases
        $TestCases = @(
            @{ Name = 'Get-MgUser'; Expected = $true }
            @{ Name = 'Get-MgUser'; ApiVersion = 'Beta'; Expected = $true }
            @{ Name = 'Get-MgUser'; ApiVersion = 'Beta'; MinimumVersion = '1.0'; Expected = $true }
        )
    }

    Context 'Name: <Name>' -ForEach @(
            @{ Name = 'Get-MgUser'; Expected = $true }
            @{ Name = 'Get-MgUser'; ApiVersion = 'Beta'; Expected = $true }
            @{ Name = 'Get-MgUser'; ApiVersion = 'Beta'; MinimumVersion = '1.0'; Expected = $true }
        ) {
        BeforeAll {
            InModuleScope $PSModule.Name -ArgumentList $_ {
                $script:params = $args[0].Clone()
                $script:params.Remove('Name')
                $script:params.Remove('Expected')
            }
        }

        It 'Positional Parameter' {
            InModuleScope $PSModule.Name -Parameters $_ {
                $Output = Test-MgCommandPrerequisites $Name @params -ErrorVariable actualErrors
                $Output | Should -BeOfType [bool]
                $Output | Should -BeExactly $Expected
                $actualErrors | Should -HaveCount 0
            }
        }

        It 'Pipeline Input' {
            InModuleScope $PSModule.Name -Parameters $_ {
                $Output = $Name | Test-MgCommandPrerequisites @params -ErrorVariable actualErrors
                $Output | Should -BeOfType [bool]
                $Output | Should -BeExactly $Expected
                $actualErrors | Should -HaveCount 0
            }
        }
    }

    Context 'Multiple Input' {

        It 'Positional Parameter' {
            InModuleScope $PSModule.Name -Parameters @{ TestCases = $TestCases } {
                $Output = Test-MgCommandPrerequisites $TestCases.Name -ErrorVariable actualErrors
                $Output | Should -BeOfType [bool]
                $Output | Should -HaveCount 1  # Only pipeline will return multiple outputs
                $actualErrors | Should -HaveCount 0
            }
        }

        It 'Pipeline Input' {
            InModuleScope $PSModule.Name -Parameters @{ TestCases = $TestCases } {
                $Output = $TestCases.Name | Test-MgCommandPrerequisites -ErrorVariable actualErrors
                $Output | Should -BeOfType [bool]
                $Output | Should -HaveCount $TestCases.Count
                for ($i = 0; $i -lt $TestCases.Count; $i++) {
                    $Output[$i] | Should -BeExactly $TestCases[$i].Expected
                }
                $actualErrors | Should -HaveCount 0
            }
        }

        It 'Pipeline Input By Name' {
            InModuleScope $PSModule.Name -Parameters @{ TestCases = $TestCases } {
                $InputByName = New-Object pscustomobject[] -ArgumentList $TestCases.Count
                for ($i = 0; $i -lt $TestCases.Count; $i++) {
                    $TestCase = $TestCases[$i].Clone()
                    $TestCase.Remove('Expected')
                    $InputByName[$i] = [pscustomobject]$TestCase
                }

                $Output = $InputByName | Test-MgCommandPrerequisites -ErrorVariable actualErrors
                $Output | Should -BeOfType [bool]
                $Output | Should -HaveCount $TestCases.Count
                for ($i = 0; $i -lt $TestCases.Count; $i++) {
                    $Output[$i] | Should -BeExactly $TestCases[$i].Expected
                }
                $actualErrors | Should -HaveCount 0
            }
        }
    }

    Context 'Error Conditions' {
        BeforeAll {
            Mock -ModuleName $PSModule.Name Import-Module { Import-Module 'Microsoft.Graph.ModuleNotFound' -ErrorAction SilentlyContinue } -Verifiable
            Mock -ModuleName $PSModule.Name Get-MgContext { } -Verifiable
        }

        It 'Missing module' {
            InModuleScope $PSModule.Name -Parameters $_ {
                $Command = { Test-MgCommandPrerequisites 'Get-MgUser' -ErrorAction SilentlyContinue }
                $Command | Should -WriteError -ErrorId "Modules_Module*NotFound*" -ExceptionType ([System.IO.FileNotFoundException])
            }
        }

        It 'No authentication' {
            InModuleScope $PSModule.Name -Parameters $_ {
                $Command = { Test-MgCommandPrerequisites 'Get-MgUser' -ErrorAction SilentlyContinue }
                $Command | Should -WriteError -ErrorId "MgAuthenticationRequired*" -ExceptionType ([System.Security.Authentication.AuthenticationException])
            }
        }

        It 'Missing scopes' {
            InModuleScope $PSModule.Name -Parameters $_ {
                Mock Get-MgContext { New-Object Microsoft.Graph.PowerShell.Authentication.AuthContext -Property @{ Scopes = @('email', 'openid', 'profile'); AppName = 'Microsoft Graph PowerShell'; PSHostVersion = $PSVersionTable['PSVersion'] } } -Verifiable
                $Command = { Test-MgCommandPrerequisites 'Get-MgUser' -ErrorAction SilentlyContinue }
                $Command | Should -WriteError -ErrorId "MgScopePermissionRequired*" -ExceptionType ([System.Security.SecurityException])
            }
        }
    }
}
