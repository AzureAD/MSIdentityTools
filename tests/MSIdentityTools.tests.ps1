[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $ModulePath = ".\src\*.psd1"
)

BeforeDiscovery {
    $PSModule = Import-Module $ModulePath -Force -PassThru -ErrorAction SilentlyContinue
}

BeforeAll {
    $PSModule = Import-Module $ModulePath -Force -PassThru -ErrorAction Stop
    $ModulePrefix = "MsId"
}

## Perform Tests
Describe 'MSIdentityTools' -Tag 'Common' {

    It 'Author is Microsoft Identity' {
        $PSModule.Author | Should -BeExactly 'Microsoft Identity'
    }

    It 'Company Name is Microsoft Corporation' {
        $PSModule.CompanyName | Should -BeExactly 'Microsoft Corporation'
    }

    It 'Copyright is Microsoft Corporation with Proper Formatting' {
        $PSModule.Copyright | Should -BeLikeExactly "(c) * Microsoft Corporation. All rights reserved."
    }

    It 'Copyright is Current' -Tag 'Deferrable' {
        $PSModule.Copyright | Should -BeLikeExactly "(c) $(Get-Date -Format 'yyyy') *" -Because 'the copyright year should match the current year'
    }

    It 'Contains GUID' {
        $PSModule.Guid | Should -Not -BeNullOrEmpty
    }

    It 'Does Not Contain Default Prefix' {
        $PSModule.Prefix | Should -BeNullOrEmpty
    }

    It 'Contains Description' {
        $PSModule.Description | Should -Not -BeNullOrEmpty
    }

    It 'Contains LicenseUri' {
        $PSModule.LicenseUri | Should -Not -BeNullOrEmpty
    }

    It 'Contains ProjectUri' {
        $PSModule.ProjectUri | Should -Not -BeNullOrEmpty
    }

}

Describe '<_.Name>' -ForEach $PSModule.ExportedFunctions.Values -Tag 'Common' {

    BeforeDiscovery {
        try {
            $Help = Get-Help $_.Name
            $Help.examples.example | ForEach-Object { $_.title = $_.title.Replace('-', '').Trim() }
            #$Help.parameters.parameter = $Help.parameters.parameter | Where-Object name -NotIn ('WhatIf', 'Confirm')
        }
        catch {}
    }

    It 'Approved Command Verb' {
        $Verbs = Get-Verb
        $_.Verb | Should -BeIn $Verbs.Verb -Because 'it should be an approved PowerShell verb (See Get-Verb)'
    }

    It "Proper Command Prefix" {
        $_.Noun | Should -BeLikeExactly "$ModulePrefix*"
    }

    Context 'Help Content' {
        
        BeforeAll {
            $PSFunction = $_
            $Help = Get-Help $_.Name
        }

        # It 'Use Get-Help' {
        #     $Help = Get-Help $_.Name
        #     $Help | Should -Not -BeNullOrEmpty
        # }

        It 'Contains Synopsis' {
            $Help.Synopsis | Should -Not -BeNullOrEmpty
        }

        # It 'Contains Description' {
        #     $Help.description | Should -Not -BeNullOrEmpty
        # }
        
        # It 'Contains Parameter Descriptions' {
        #     foreach ($parameter in $Help.parameters.parameter) {
        #         $parameter.description | Should -Not -BeNullOrEmpty
        #     }
        # }

        It 'Contains Parameter Description: <_.name>' -TestCases ($Help.parameters.parameter | Where-Object name -NotIn ('WhatIf', 'Confirm')) {
            $_.description | Should -Not -BeNullOrEmpty
        }

        It 'Contains Example' {
            $Help.examples | Should -Not -BeNullOrEmpty
        }

        # It 'Proper Example Format and Descriptions' {
        #     foreach ($example in $Help.examples.example) {
        #         $example.introduction[0].Text | Should -BeExactly 'PS > '
        #         $example.code | Should -BeLikeExactly "$($PSFunction.Name)*"
        #         $example.remarks[0].Text | Should -Not -BeNullOrEmpty
        #     }
        # }

        It 'Proper Example Format and Description: <_.title>' -TestCases $Help.examples.example {
            $_.introduction[0].Text | Should -BeIn 'PS > ', 'PS >', 'PS C:\>'
            if ($PSVersionTable.PSVersion -ge [version]'7.0') {
                $_.code | Should -BeLikeExactly "*$($PSFunction.Name)*"
            }
            $_.remarks[0].Text | Should -Not -BeNullOrEmpty
        }

    }

}
