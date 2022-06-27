<#
.SYNOPSIS
    Set TLS settings on Windows OS to use more secure TLS protocols.

.EXAMPLE
    PS > Set-MsIdWindowsTlsSettings -DotNetFwUseSystemDefault -DotNetFwUseStrongCrypto -IEDisableLegacySecurityProtocols

    Sets recommended TLS settings for .NET Framework applications and Internet Explorer (Internet Options) which should default to TLS 1.2+ on Windows 8/2012 and later.

.EXAMPLE
    PS > Set-MsIdWindowsTlsSettings -DisableClientLegacyTlsVersions

    Disables TLS 1.1 and earlier for the entire operating system.

#>
function Set-MsIdWindowsTlsSettings {
    [CmdletBinding()]
    param (
        # System-wide .NET Framework setting to allow the operating system to choose the protocol.
        [Parameter(Mandatory = $false)]
        [switch] $DotNetFwUseSystemDefault,
        # System-wide .NET Framework setting to use more secure network protocols (TLS 1.2, TLS 1.1, and TLS 1.0) and blocks protocols that are not secure.
        [Parameter(Mandatory = $false)]
        [switch] $DotNetFwUseStrongCrypto,
        # Internet Explorer (Internet Options) setting to disable use of TLS 1.1 and earlier.
        [Parameter(Mandatory = $false)]
        [switch] $IEDisableLegacySecurityProtocols,
        # System-wide Windows Secure Channel setting to disable all use of TLS 1.1 and earlier.
        [Parameter(Mandatory = $false)]
        [switch] $DisableClientLegacyTlsVersions
    )

    begin {
        ## Initialize Critical Dependencies
        $CriticalError = $null
        if (!(Test-PsElevation)) {
            Write-Error 'This command sets machine-level registery settings which requires an elevated PowerShell session using Run as Administrator.' -ErrorVariable CriticalError
            return
        }
    }

    process {
        ## Return Immediately On Critical Error
        if ($CriticalError) { return }

        ## System-wide .NET Framework Settings
        # https://docs.microsoft.com/en-us/dotnet/framework/network-programming/tls#configuring-security-via-the-windows-registry
        if ($PSBoundParameters.ContainsKey('DotNetFwUseSystemDefault')) {
            if ($DotNetFwUseSystemDefault) {
                Write-Host @"
Setting Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727\SystemDefaultTlsVersions = 1
Setting Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727\SystemDefaultTlsVersions = 1
Setting Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319\SystemDefaultTlsVersions = 1
Setting Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319\SystemDefaultTlsVersions = 1
"@
                ## .NET Framework 3.5
                New-Item 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727' -ErrorAction Ignore | Out-Null
                Set-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727' -Name 'SystemDefaultTlsVersions' -Type Dword -Value $DotNetFwUseSystemDefault.ToBool()

                New-Item 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727' -ErrorAction Ignore | Out-Null
                Set-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727' -Name 'SystemDefaultTlsVersions' -Type Dword -Value $DotNetFwUseSystemDefault.ToBool()

                ## .NET Framework 4 and above
                New-Item 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -ErrorAction Ignore | Out-Null
                Set-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SystemDefaultTlsVersions' -Type Dword -Value $DotNetFwUseSystemDefault.ToBool()

                New-Item 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -ErrorAction Ignore | Out-Null
                Set-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SystemDefaultTlsVersions' -Type Dword -Value $DotNetFwUseSystemDefault.ToBool()

            }
            else {
                Write-Host @"
Removing Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727\SystemDefaultTlsVersions
Removing Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727\SystemDefaultTlsVersions
Removing Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319\SystemDefaultTlsVersions
Removing Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319\SystemDefaultTlsVersions
"@
                ## .NET Framework 3.5
                Remove-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727' -Name 'SystemDefaultTlsVersions' -ErrorAction Ignore
                Remove-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727' -Name 'SystemDefaultTlsVersions' -ErrorAction Ignore

                ## .NET Framework 4 and above
                Remove-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SystemDefaultTlsVersions' -ErrorAction Ignore
                Remove-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SystemDefaultTlsVersions' -ErrorAction Ignore
            }
        }

        if ($PSBoundParameters.ContainsKey('DotNetFwUseStrongCrypto')) {
            if ($DotNetFwUseStrongCrypto) {
                Write-Host @"
Setting Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727\SchUseStrongCrypto = 1
Setting Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727\SchUseStrongCrypto = 1
Setting Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319\SchUseStrongCrypto = 1
Setting Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319\SchUseStrongCrypto = 1
"@
                ## .NET Framework 3.5
                New-Item 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727' -ErrorAction Ignore | Out-Null
                Set-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727' -Name 'SchUseStrongCrypto' -Type Dword -Value $DotNetFwUseStrongCrypto.ToBool()

                New-Item 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727' -ErrorAction Ignore | Out-Null
                Set-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727' -Name 'SchUseStrongCrypto' -Type Dword -Value $DotNetFwUseStrongCrypto.ToBool()

                ## .NET Framework 4 and above
                New-Item 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -ErrorAction Ignore | Out-Null
                Set-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type Dword -Value $DotNetFwUseStrongCrypto.ToBool()

                New-Item 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -ErrorAction Ignore | Out-Null
                Set-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type Dword -Value $DotNetFwUseStrongCrypto.ToBool()
            }
            else {
                Write-Host @"
Removing Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727\SchUseStrongCrypto
Removing Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727\SchUseStrongCrypto
Removing Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319\SchUseStrongCrypto
Removing Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319\SchUseStrongCrypto
"@
                ## .NET Framework 3.5
                Remove-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727' -Name 'SchUseStrongCrypto' -ErrorAction Ignore
                Remove-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727' -Name 'SchUseStrongCrypto' -ErrorAction Ignore

                ## .NET Framework 4 and above
                Remove-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -ErrorAction Ignore
                Remove-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -ErrorAction Ignore
            }
        }

        ## Internet Explorer (Internet Options) Settings
        if ($PSBoundParameters.ContainsKey('IEDisableLegacySecurityProtocols')) {
            Write-Host @"
Setting Registery Value: HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\SecurityProtocols
Setting Registery Value: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\SecurityProtocols
The latter is only relevant when loopback processing of group policy is enabled.
"@
            New-Item 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Ignore | Out-Null
            if ($IEDisableLegacySecurityProtocols) {
                ## Current User Internet Options
                $SecurityProtocols = Get-ItemPropertyValue 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name 'SecureProtocols' -ErrorAction Ignore
                $SecurityProtocols = $SecurityProtocols -band -bnot 32 -band -bnot 128 -band -bnot 512  # Disable SSL 3.0, TLS 1.0, and TLS 1.1
                $SecurityProtocols = $SecurityProtocols -bor 2048 -bor 8192  # Enable TLS 1.2 and TLS 1.3
                Set-ItemProperty 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name 'SecureProtocols' -Type Dword -Value $SecurityProtocols

                ## System-wide Internet Options (Only relevant when loopback processing of group policy is enabled)
                # https://docs.microsoft.com/en-us/troubleshoot/windows-server/group-policy/loopback-processing-of-group-policy
                try { $SecurityProtocols = Get-ItemPropertyValue 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings' -Name 'SecureProtocols' -ErrorAction Ignore } catch {}
                $SecurityProtocols = $SecurityProtocols -band -bnot 32 -band -bnot 128 -band -bnot 512  # Disable SSL 3.0, TLS 1.0, and TLS 1.1
                $SecurityProtocols = $SecurityProtocols -bor 2048 -bor 8192  # Enable TLS 1.2 and TLS 1.3
                Set-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings' -Name 'SecureProtocols' -Type Dword -Value $SecurityProtocols
            }
            else {
                ## Current User Internet Options
                $SecurityProtocols = Get-ItemPropertyValue 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name 'SecureProtocols' -ErrorAction Ignore
                $SecurityProtocols = $SecurityProtocols -bor 128 -bor 512  # Re-Enable TLS 1.0 and TLS 1.1
                Set-ItemProperty 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name 'SecureProtocols' -Type Dword -Value $SecurityProtocols

                ## System-wide Internet Options (Only relevant when loopback processing of group policy is enabled)
                # https://docs.microsoft.com/en-us/troubleshoot/windows-server/group-policy/loopback-processing-of-group-policy
                try { $SecurityProtocols = Get-ItemPropertyValue 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings' -Name 'SecureProtocols' -ErrorAction Ignore } catch {}
                $SecurityProtocols = $SecurityProtocols -bor 128 -bor 512  # Re-Enable TLS 1.0 and TLS 1.1
                Set-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings' -Name 'SecureProtocols' -Type Dword -Value $SecurityProtocols
            }
        }

        ## System-wide Windows Settings
        # https://docs.microsoft.com/en-US/troubleshoot/windows-server/windows-security/restrict-cryptographic-algorithms-protocols-schannel
        if ($PSBoundParameters.ContainsKey('DisableClientLegacyTlsVersions')) {
            [string[]] $LegacyTls = 'SSL 2.0', 'SSL 3.0', 'TLS 1.0', 'TLS 1.1'
            if ($DisableClientLegacyTlsVersions) {
                New-Item "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols" -ErrorAction Ignore | Out-Null
                foreach ($Protocol in $LegacyTls) {
                    Write-Host @"
Setting Registery Value: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Client\Enabled = 0
"@
                    New-Item "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol" -ErrorAction Ignore | Out-Null
                    New-Item "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Client" -ErrorAction Ignore | Out-Null
                    Set-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Client" -Name 'Enabled' -Type Dword -Value (!$DisableClientLegacyTlsVersions.ToBool())
                }
            }
            else {
                foreach ($Protocol in $LegacyTls) {
                    Write-Host @"
Removing Registery Value: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Client\Enabled
"@
                    Remove-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Client" -Name 'Enabled' -ErrorAction Ignore
                }
            }
        }
    }

    end {
        ## Return Immediately On Critical Error
        if ($CriticalError) { return }

        Write-Warning "These setting updates only effect new process so you will need to restart your apps for these settings to take effect."
    }
}
