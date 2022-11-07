<#
.SYNOPSIS
    Determine if an IP address exists in the specified subnet.
.EXAMPLE
    PS C:\>Test-IpAddressInSubnet 192.168.1.10 -Subnet '192.168.1.1/32','192.168.1.0/24'
    Determine if the IPv4 address exists in the specified subnet.
.EXAMPLE
    PS C:\>Test-IpAddressInSubnet 2001:db8:1234::1 -Subnet '2001:db8:a::123/64','2001:db8:1234::/48'
    Determine if the IPv6 address exists in the specified subnet.
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
        # List of subnets in CIDR notation. For example, "192.168.1.0/24" or "2001:db8:1234::/48".
        [Parameter(Mandatory = $true)]
        [string[]] $Subnets,
        # Return list of matching subnets rather than a boolean result.
        [Parameter(Mandatory = $false)]
        [switch] $ReturnMatchingSubnets
    )

    begin {
        function ConvertBitArrayToByteArray([System.Collections.BitArray] $BitArray) {
            [byte[]] $ByteArray = New-Object byte[] ([System.Math]::Ceiling($BitArray.Length / 8))
            $BitArray.CopyTo($ByteArray, 0)
            return $ByteArray
        }

        function ConvertBitArrayToBigInt([System.Collections.BitArray] $BitArray) {
            return [bigint][byte[]](ConvertBitArrayToByteArray $BitArray)
        }
    }

    process {
        foreach ($IpAddress in $IpAddresses) {
            if ($IpAddress.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
                [int32] $bitIpAddress = [BitConverter]::ToInt32($IpAddress.GetAddressBytes(), 0)
            }
            else {
                [System.Collections.BitArray] $bitIpAddress = $IpAddress.GetAddressBytes()
            }

            [System.Collections.Generic.List[string]] $listSubnets = New-Object System.Collections.Generic.List[string]
            [bool] $Result = $false
            foreach ($Subnet in $Subnets) {
                [string[]] $SubnetComponents = $Subnet.Split('/')
                [ipaddress] $SubnetAddress = $SubnetComponents[0]
                [int] $SubnetMaskLength = $SubnetComponents[1]

                if ($IpAddress.AddressFamily -eq $SubnetAddress.AddressFamily) {
                    if ($IpAddress.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
                        ## Supports IPv4 (32 bit) only but more performant than BitArray?
                        #[int32] $bitIpAddress = [BitConverter]::ToInt32($IpAddress.GetAddressBytes(), 0)
                        [int32] $bitSubnetAddress = [BitConverter]::ToInt32($SubnetAddress.GetAddressBytes(), 0)
                        [int32] $bitSubnetMaskHostOrder = 0
                        if ($SubnetMaskLength -gt 0) {
                            $bitSubnetMaskHostOrder = -1 -shl (32 - $SubnetMaskLength)
                        }
                        [int32] $bitSubnetMask = [ipaddress]::HostToNetworkOrder($bitSubnetMaskHostOrder)

                        ## Check IP
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
                    else {
                        ## BitArray supports IPv4 (32 bits) and IPv6 (128 bits). Would Int128 type in .NET 7 improve performance?
                        #[System.Collections.BitArray] $bitIpAddress = $IpAddress.GetAddressBytes()
                        [System.Collections.BitArray] $bitSubnetAddress = $SubnetAddress.GetAddressBytes()
                        [System.Collections.BitArray] $bitSubnetMask = New-Object System.Collections.BitArray -ArgumentList ($bitSubnetAddress.Length - $SubnetMaskLength), $true
                        $bitSubnetMask.Length = $bitSubnetAddress.Length
                        [void]$bitSubnetMask.Not()
                        [byte[]] $ByteArray = ConvertBitArrayToByteArray $bitSubnetMask
                        [array]::Reverse($ByteArray)  # Convert to Network byte order
                        [System.Collections.BitArray] $bitSubnetMask = $ByteArray
                
                        ## Check IP
                        if ((ConvertBitArrayToBigInt $bitIpAddress.And($bitSubnetMask)) -eq (ConvertBitArrayToBigInt $bitSubnetAddress.And($bitSubnetMask))) {
                            if ($ReturnMatchingSubnets) {
                                $listSubnets.Add($Subnet)
                            }
                            else {
                                $Result = $true
                                continue
                            }
                        }
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
