<#
.SYNOPSIS
    Determine if an IP address exists in the specified subnet.
.EXAMPLE
    PS C:\>Test-IpAddressInSubnet 192.168.1.10 -Subnet '192.168.1.1/32','192.168.1.0/24'
    Determine if the IP address exists in the specified subnet.
.INPUTS
    System.Net.IPAddress
.LINK
    https://github.com/jasoth/Utility.PS
#>
function Test-IpAddressInSubnet {
    [CmdletBinding()]
    [OutputType([bool], [string[]])]
    param (
        # IP Address to test against provided subnets.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [ipaddress[]] $IpAddresses,
        # List of subnets.
        [Parameter(Mandatory = $true)]
        [string[]] $Subnets,
        # Return list of matching subnets rather than a boolean result.
        [Parameter(Mandatory = $false)]
        [switch] $ReturnMatchingSubnets
    )

    process {
        foreach ($IpAddress in $IpAddresses) {
            [System.Collections.Generic.List[string]] $listSubnets = New-Object System.Collections.Generic.List[string]
            [bool] $Result = $false
            foreach ($Subnet in $Subnets) {
                [string[]] $SubnetComponents = $Subnet.Split('/')

                [int] $bitIpAddress = [BitConverter]::ToInt32($IpAddress.GetAddressBytes(), 0)
                [int] $bitSubnetAddress = [BitConverter]::ToInt32(([ipaddress]$SubnetComponents[0]).GetAddressBytes(), 0)
                [int] $bitSubnetMaskHostOrder = 0
                if ($SubnetComponents[1] -gt 0) {
                    $bitSubnetMaskHostOrder = -1 -shl (32 - [int]$SubnetComponents[1])
                }
                [int] $bitSubnetMask = [ipaddress]::HostToNetworkOrder($bitSubnetMaskHostOrder)

                if (($bitIpAddress -band $bitSubnetMask) -eq ($bitSubnetAddress -band $bitSubnetMask)) {
                    if ($ReturnMatchingSubnets) {
                        $listSubnets.Add($Subnet)
                    }
                    else {
                        $Result = $true
                        continue
                    }
                }
            }

            ## Return list of matches or boolean result
            if ($ReturnMatchingSubnets) {
                if ($listSubnets.Count -gt 1) { Write-Output $listSubnets.ToArray() -NoEnumerate }
                elseif ($listSubnets.Count -eq 1) { Write-Output $listSubnets.ToArray() }
                else {
                    $Exception = New-Object ArgumentException -ArgumentList ('The IP address {0} does not belong to any of the provided subnets.' -f $IpAddress)
                    Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::ObjectNotFound) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'TestIpAddressInSubnetNoMatch' -TargetObject $IpAddress
                }
            }
            else {
                Write-Output $Result
            }
        }
    }
}
