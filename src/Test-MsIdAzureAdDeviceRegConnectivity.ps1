<#
.SYNOPSIS
    Test connectivity on Windows OS for Azure AD Device Registration
    
.EXAMPLE
    PS > Test-MsIdAzureAdDeviceRegConnectivity

    Test required hostnames

.EXAMPLE
    PS > Test-MsIdAzureAdDeviceRegConnectivity -AdfsHostname 'adfs.contoso.com'

    Test required hostnames and ADFS server

.INPUTS
    System.String

.LINK
    https://docs.microsoft.com/en-us/samples/azure-samples/testdeviceregconnectivity/testdeviceregconnectivity/

#>
function Test-MsIdAzureAdDeviceRegConnectivity {
    [CmdletBinding()]
    param (
        # ADFS Server
        [Parameter(Mandatory = $false)]
        [string] $AdfsHostname
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        if ($PSEdition -ne 'Desktop' -or !(Test-PsElevation)) {
            Write-Error 'This command uses a Scheduled Job to run under the system context of a Windows OS which requires Windows PowerShell 5.1 and an elevated session using Run as Administrator.' -ErrorVariable CriticalError
            return
        }
    }

    process {
        ## Return Immediately On Critical Error
        if ($CriticalError) { return }

        Invoke-CommandAsSystem {
            param ([string]$AdfsHostname)
            [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

            [System.Collections.Generic.List[string]] $listHostname = @(
                'login.microsoftonline.com'
                'device.login.microsoftonline.com'
                'enterpriseregistration.windows.net'
                'autologon.microsoftazuread-sso.com'
            )
            if ($AdfsHostname) { $listHostname.Add($AdfsHostname) }

            $listHostname | Test-NetConnection -Port 443 | Format-Table ComputerName, RemotePort, RemoteAddress, TcpTestSucceeded
        } -ArgumentList $AdfsHostname -ErrorAction Stop
    }
}
