param
(
    # Module to Launch
    [Parameter(Mandatory = $false)]
    [string] $ModuleManifestPath = ".\src\*.psd1",
    # Paths to PowerShell Executables
    [Parameter(Mandatory = $false)]
    [string[]] $PowerShellPaths = @(
        #'pwsh'
        'powershell'
        #'D:\Software\PowerShell-6.2.4-win-x64\pwsh.exe'
    ),
    # Import Module into the same session
    [Parameter(Mandatory = $false)]
    [switch] $NoNewWindow #= $true
)

#.\build\Restore-NugetPackages.ps1 -BaseDirectory ".\" -Verbose:$false

if ($NoNewWindow) {
    Import-Module $ModuleManifestPath -PassThru -Force
}
else {
    [scriptblock] $ScriptBlock = {
        param ([string]$ModulePath)
        ## Force WindowsPowerShell to load correct version of built-in modules when launched from PowerShell 6+
        if ($PSVersionTable.PSEdition -eq 'Desktop') { Import-Module 'Microsoft.PowerShell.Management', 'Microsoft.PowerShell.Utility', 'CimCmdlets' -MaximumVersion 5.9.9.9 }
        Import-Module $ModulePath -PassThru
    }
    $strScriptBlock = 'Invoke-Command -ScriptBlock {{ {0} }} -ArgumentList {1}' -f $ScriptBlock, $ModuleManifestPath
    #$strScriptBlock = 'Import-Module {0} -PassThru' -f $ModuleManifestPath

    foreach ($Path in $PowerShellPaths) {
        Start-Process $Path -ArgumentList ('-NoExit', '-NoProfile', '-EncodedCommand', [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($strScriptBlock)))
    }
}
