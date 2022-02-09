@{
    Run          = @{
        PassThru = $true
    }
    CodeCoverage = @{
        Enabled      = $true
        OutputFormat = 'JaCoCo'
        OutputPath   = '.\build\TestResults\CodeCoverage.xml'
        RecursePaths = $false
    }
    TestResult   = @{
        Enabled      = $true
        OutputFormat = 'NUnitXML'
        OutputPath   = '.\build\TestResults\TestResults.xml'
    }
    Output       = @{
        Verbosity = 'Detailed'
    }
}