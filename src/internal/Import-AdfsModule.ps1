<#
.SYNOPSIS
    Gets the form fields to login to AD FS server for the login URL and credentials.
.DESCRIPTION
.EXAMPLE
    PS C:\>Import-AdfsModule -Url $url -Credential $credential
    Gets the form fields for the variables.
#>
function Import-AdfsModule {
    $module = 'ADFS'
    
    if(-not(Get-Module -Name $module)) {
        if(Get-Module -ListAvailable | Where-Object { $_.name -eq $module }) {
            Import-Module -Name $module
            $true
        }
        else { $false }
    }
    else { $true } #module already loaded
}
