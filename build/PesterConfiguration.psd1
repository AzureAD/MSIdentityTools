@{
    Run          = @{
        PassThru = $true
    }
    CodeCoverage = @{
        Enabled      = $true
        OutputFormat = 'JaCoCo'
        OutputPath   = '.\build\TestResult\CodeCoverage.xml'
        RecursePaths = $false
    }
    TestResult   = @{
        Enabled      = $true
        OutputFormat = 'NUnitXML'
        OutputPath   = '.\build\TestResult\TestResult.xml'
    }
    Output       = @{
        Verbosity = 'Detailed'
    }
}