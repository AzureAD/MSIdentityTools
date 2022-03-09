[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $ModulePath = "..\src\*.psd1"
)

BeforeDiscovery {
    $PSModule = Import-Module $ModulePath -Force -PassThru
}

BeforeAll {
    $PSModule = Import-Module $ModulePath -Force -PassThru
}

## Perform Tests
Describe 'MSIdentityTools' -Tag 'Common' {

    It 'Author is Microsoft Identity' {
        $PSModule.Author | Should -BeExactly 'Microsoft Identity'
    }

    It 'Company Name is Microsoft Corporation' {
        $PSModule.CompanyName | Should -BeExactly 'Microsoft Corporation'
    }

    It 'Copyright is Microsoft and Current' {
        $PSModule.Copyright | Should -BeExactly "(c) $(Get-Date -Format 'yyyy') Microsoft Corporation. All rights reserved."
    }

    It 'Contains GUID' {
        $PSModule.Guid | Should -Not -BeNullOrEmpty
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
        $Help = Get-Help $_.Name
        $Help.examples.example | ForEach-Object { $_.title = $_.title.Replace('-','').Trim() }
    }

    Context 'Help Content' {
        
        BeforeAll {
            $PSFunction = $_
            $Help = Get-Help $_.Name
        }

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

        It 'Contains Parameter Description: <_.name>' -TestCases $Help.parameters.parameter {
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
