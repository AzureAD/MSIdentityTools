<#
.SYNOPSIS
    Lookup Azure IP address for Azure Cloud, Region, and Service Tag.
    
.EXAMPLE
    PS > $IpAddress = Resolve-DnsName login.microsoftonline.com | Where-Object QueryType -eq A | Select-Object -First 1 -ExpandProperty IPAddress
    PS > Resolve-MsIdAzureIpAddress $IpAddress

    Lookup Azure IP address for Azure Cloud, Region, and Service Tag.

.EXAMPLE
    PS > Resolve-MsIdAzureIpAddress graph.microsoft.com

    Lookup Azure IP address for Azure Cloud, Region, and Service Tag.

.INPUTS
    System.String
    System.Net.IPAddress

#>
function Resolve-MsIdAzureIpAddress {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        # DNS Name or IP Address
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObject', ValueFromPipeline = $true, Position = 0)]
        [object[]] $InputObjects,
        # IP Address of Azure Service
        [Parameter(Mandatory = $true, ParameterSetName = 'IpAddress', Position = 1)]
        [ipaddress[]] $IpAddresses,
        # Name of Azure Cloud. Valid values are: Public, Government, Germany, China
        [Parameter(Mandatory = $false)]
        [ValidateSet('Public', 'Government', 'Germany', 'China')]
        [string[]] $Clouds = @('Public', 'Government', 'Germany', 'China'),
        # Bypass cache and download data again.
        [Parameter(Mandatory = $false)]
        [switch] $ForceRefresh
    )

    begin {
        #[string[]] $Clouds = 'Public', 'Government', 'Germany', 'China'
        [hashtable] $ServiceTagAndRegions = @{}
        $PreviousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        Write-Verbose 'Getting Azure IP Ranges and Service Tag Data...'
        foreach ($Cloud in $Clouds) {
            $ServiceTagAndRegions.Add($Cloud, (Get-MsIdAzureIpRange -Cloud $Cloud -AllServiceTagsAndRegions -ForceRefresh:$ForceRefresh -Verbose:$false))
        }
        $ProgressPreference = $PreviousProgressPreference
        Write-Verbose 'Resolving IP Address to Azure Service Tags...'
    }

    process {
        ## Parse InputObject
        if ($PSCmdlet.ParameterSetName -eq 'InputObject') {
            $listIpAddresses = New-Object System.Collections.Generic.List[ipaddress]
            foreach ($InputObject in $InputObjects) {
                if ($InputObject -is [ipaddress] -or $InputObject -is [int] -or $InputObject -is [UInt32]) {
                    $listIpAddresses.Add($InputObject)
                }
                elseif ($InputObject -is [string]) {
                    if ($InputObject -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' -or $InputObject -match '^(?:(?::{1,2})?[0-9a-fA-F]{1,4}(?::{1,2})?){1,8}$') {
                        try {
                            [ipaddress] $IpAddress = $InputObject
                            $listIpAddresses.Add($IpAddress)
                        }
                        catch { throw }
                    }
                    else {
                        $DnsNames = Resolve-DnsName $InputObject -Type A -ErrorAction Stop | Where-Object QueryType -EQ A
                        foreach ($DnsName in $DnsNames) {
                            $listIpAddresses.Add($DnsName.IPaddress)
                        }
                    }
                }
                else {
                    $Exception = New-Object ArgumentException -ArgumentList ('Cannot parse input of type {0} to IP address or DNS name.' -f $InputObject.GetType())
                    Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::ParserError) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'ResolveAzureIpAddressFailureTypeNotSupported' -TargetObject $InputObject
                }
            }
            [ipaddress[]] $IpAddresses = $listIpAddresses.ToArray()
        }

        ## Lookup IP Address
        foreach ($IpAddress in $IpAddresses) {
            $listResults = New-Object System.Collections.Generic.List[pscustomobject]
            foreach ($Cloud in $ServiceTagAndRegions.Keys) {
                foreach ($ServiceTagAndRegion in $ServiceTagAndRegions[$Cloud].values) {
                    if (Test-IpAddressInSubnet $IpAddress -Subnets $ServiceTagAndRegion.properties.addressPrefixes) {
                        $ServiceTagAndRegion | Add-Member -Name cloud -MemberType NoteProperty -Value $Cloud -Force
                        $ServiceTagAndRegion | Add-Member -Name ipAddress -MemberType NoteProperty -Value $IpAddress -Force
                        $listResults.Add(($ServiceTagAndRegion | Select-Object ipAddress, cloud, id, properties))
                    }
                }
            }
            if ($listResults.Count -gt 1) { Write-Output $listResults.ToArray() -NoEnumerate }
            elseif ($listResults.Count -eq 1) { Write-Output $listResults.ToArray() }
        }
    }
}
