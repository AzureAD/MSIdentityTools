@{
    Run          = @{
        PassThru = $true
    }
    Filter       = @{
        Tag        = ''
        #ExcludeTag = 'Slow','IntegrationTest'
    }
    CodeCoverage = @{
        Enabled      = $true
        OutputFormat = 'JaCoCo'
        OutputPath   = '.\build\TestResults\CodeCoverage.xml'
        RecursePaths = $false
    }
    TestResult   = @{
        Enabled      = $false
        OutputFormat = 'NUnitXML'
        OutputPath   = '.\build\TestResults\TestResult.xml'
    }
    Output       = @{
        Verbosity = 'Detailed'
    }
}