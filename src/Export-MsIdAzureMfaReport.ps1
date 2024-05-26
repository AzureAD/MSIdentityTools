<#
.SYNOPSIS
    Exports the list of users that have signed into the Azure portal, Azure CLI, or Azure PowerShell over the last 30 days by querying the sign in logs. In [Microsoft Entra ID Free](https://learn.microsoft.com/entra/identity/monitoring-health/reference-reports-data-retention#activity-reports) tenants, sign-in log retention is limited to seven days.

    The report also includes each user's multi-factor authentication (MFA) registration status from Microsoft Entra.

    ```powershell
    Install-Module MsIdentityTools -Scope CurrentUser
    Connect-MgGraph -Scopes Directory.Read.All, AuditLog.Read.All, UserAuthenticationMethod.Read.All
    Export-MsIdAzureMfaReport .\report.xlsx
    ```

    ### Permissions and roles
    - Required Microsoft Entra role: **Global Reader**
    - Required permission scopes: **Directory.Read.All**, **AuditLog.Read.All**, **UserAuthenticationMethod.Read.All**


    *This report will assist you in assessing the impact of the [Microsoft will require MFA for all Azure users](https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/microsoft-will-require-mfa-for-all-azure-users/ba-p/4140391) rollout on your tenant.*

    ![Screenshot of a sample Azure MFA report](../assets/export-msidazuremfareport-sample.png)

.DESCRIPTION
    ### Consenting to permissions
        If this is the first time running `Connect-MgGraph` with the permission scopes listed above, the user consenting to the permissions will need to be in one of the following roles:
        - **Cloud Application Administrator**
        - **Application Administrator**
        - **Privileged Role Administrator**

        After the initial consent the `Export-MsIdAzureMfaReport` cmdlet can be run by any user with the Microsoft Entra **Global Reader** role.

    ### Third party multi-factor authentication
        The `MFA status` in this report is based on authentication methods registered by the user in Microsoft Entra. The `MFA status` is not applicable if your tenant uses a third party multi-factor authentication provider (including [Custom Controls](https://learn.microsoft.com/entra/identity/conditional-access/controls)).

    ### PowerShell 7.0
        This cmdlet requires [PowerShell 7.0](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) or later.

.EXAMPLE
    Install-Module MsIdentityTools -Scope CurrentUser
    Connect-MgGraph -Scopes Directory.Read.All, AuditLog.Read.All, UserAuthenticationMethod.Read.All
    Export-MsIdAzureMfaReport .\report.xlsx

    Queries last 30 days (7 days for Free tenants) sign in logs and outputs a report of users accessing Azure and their MFA status in Excel format.

.EXAMPLE
    Export-MsIdAzureMfaReport .\report.xlsx -Days 3

    Queries sign in logs for the past 3 days and outputs a report of Azure users and their MFA status in Excel format.

.EXAMPLE
    Export-MsIdAzureMfaReport -PassThru | Export-Csv -Path .\report.csv

    Returns the results and exports them to a CSV file.

#>
function Export-MsIdAzureMfaReport {
    param (
        # Output file location for Excel Workbook. e.g. .\report.xlsx
        [string]
        [Parameter(Position = 1)]
        [string]
        $ExcelWorkbookPath,

        # Switch to include the results in the output
        [switch]
        $PassThru,

        # Number of days to query sign in logs. Defaults to 30 days for premium tenants and 7 days for free tenants
        [ValidateScript({
                $_ -ge 0 -and $_ -le 30
            },
            ErrorMessage = "Logs are only available for the last 7 days for free tenants and 30 days for premium tenants. Please enter a number between 0 and 30.")]
        [int]
        $Days,

        # Optional. Hashtable with a pre-defined list of User objects (Use Get-MsIdAzureUsers).
        [array]
        $Users,

        # Optional. Hashtable with a pre-defined list of User objects with auth methods. Used for generating spreadhsheet.
        [array]
        $UsersMfa,

        # If enabled, the user auth method will be used (slower) instead of the reporting API. This is the default for free tenants as the reporting API requires a premium license.
        [switch]
        $UseAuthenticationMethodEndPoint
    )
    function Main() {

        if (-not (Test-MgModulePrerequisites @('AuditLog.Read.All', 'Directory.Read.All', 'UserAuthenticationMethod.Read.All'))) { return }

        $isExcel = ![string]::IsNullOrEmpty($ExcelWorkbookPath)
        if ($isExcel) {
            # Determine if the ImportExcel module is installed since the parameter was included
            if ($null -eq (Get-Module -Name ImportExcel -ListAvailable)) {
                Write-Error "The ImportExcel module is not installed. This is used to export the results to an Excel worksheet. Please install the ImportExcel Module before using this parameter or run without this parameter." -ErrorAction Stop
            }

            if ([IO.Path]::GetExtension($ExcelWorkbookPath) -notmatch ".xlsx") {
                Write-Error "The ExcelWorkbookPath '$ExcelWorkbookPath' is not a valid Excel file. Please provide a valid Excel file path. E.g. .\report.xlsx" -ErrorAction Stop
            }
        }

        if ($null -eq $Users -and $null -eq $UsersMfa) {
            $Users = Get-MsIdAzureUsers -Days $Days
        }

        if ($UsersMfa) { $azureUsersMfa = $UsersMfa }
        else { $azureUsersMfa = GetUserMfaInsight $Users }

        if ($isExcel) {
            GenerateExcelReport $azureUsersMfa $ExcelWorkbookPath
        }

        if (-not ($isExcel) -or ($isExcel -and $PassThru)) {
            return $azureUsersMfa
        }
    }

    function GenerateExcelReport ($UsersMfa, $Path) {

        $maxRows = $UsersMfa.Count + 1

        $UsersMfa = $UsersMfa | Sort-Object -Property IsMfaRegistered, UserDisplayName

        # Delete the existing output file if it already exists
        $OutputFileExists = Test-Path $Path
        if ($OutputFileExists -eq $true) {
            Get-ChildItem $Path | Remove-Item -Force
        }

        $headerBgColour = [System.Drawing.ColorTranslator]::FromHtml("#0077b6")
        $darkGrayColour = [System.Drawing.ColorTranslator]::FromHtml("#A9A9A9")
        $styles = @(
            New-ExcelStyle -Range "A1:J$maxRows" -Height 20 -FontSize 14
            New-ExcelStyle -Range "A1:J1" -FontColor White -BackgroundColor $headerBgColour -Bold -HorizontalAlignment Center
            New-ExcelStyle -Range "A2:A$maxRows" -FontColor Blue -Underline
            New-ExcelStyle -Range "D2:D$maxRows" -FontColor Blue -Underline
            New-ExcelStyle -Range "E2:G$maxRows" -FontColor Blue
            New-ExcelStyle -Range "C2:G$maxRows" -HorizontalAlignment Center
            New-ExcelStyle -Range "I2:I$maxRows" -FontColor $darkGrayColour -HorizontalAlignment Fill
        )

        $authMethodBlade = 'https://entra.microsoft.com/#view/Microsoft_AAD_UsersAndTenants/UserProfileMenuBlade/~/UserAuthMethods/userId/%id%/hidePreviewBanner~/true'
        $userBlade = 'https://entra.microsoft.com/#view/Microsoft_AAD_UsersAndTenants/UserProfileMenuBlade/~/overview/userId/%id%/hidePreviewBanner~/true'

        $report = $UsersMfa | Select-Object `
        @{name = 'Name'; expression = { GetLink $userBlade $_.UserId $_.UserDisplayName } }, UserPrincipalName, `
        @{name = ' '; expression = {
                if ($_.IsMfaRegistered) { $mfa = '✅' } else { $mfa = '❌' }
                $mfa
            }
        }, `
        @{name = 'MFA Status'; expression = {
                if ($_.IsMfaRegistered) { $mfa = 'MFA Registered' } else { $mfa = 'No MFA Registered' }
                GetLink $authMethodBlade $_.UserId $mfa
            }
        }, `
        @{name = 'Az Portal'; expression = { GetTickSymbol $_.AzureAppName "Azure Portal" } }, `
        @{name = 'Az CLI'; expression = { GetTickSymbol $_.AzureAppName "Azure CLI" } }, `
        @{name = 'Az PowerShell'; expression = { GetTickSymbol $_.AzureAppName "Azure PowerShell" } }, `
        @{name = 'Authentication Methods'; expression = { $_.AuthenticationMethods -join ', ' } }, UserId, `
        @{name = 'Notes'; expression = { if ([string]::IsNullOrEmpty($_.Notes)) { "' " } else { $_.Notes } } } `


        $excel = $report | Export-Excel -Path $Path -WorksheetName "MFA Report" `
            -FreezeTopRow `
            -Activate `
            -Style $styles `
            -HideSheet "None" `
            -PassThru `
            -IncludePivotChart -PivotTableName "MFA Readiness" -PivotRows "MFA Status" -PivotData @{'MFA Status' = 'count' } -PivotChartType PieExploded3D -ShowPercent

        $sheet = $excel.Workbook.Worksheets["MFA Report"]
        $sheet.Column(1).Width = 35 #DisplayName
        $sheet.Column(2).Width = 35 #UPN
        $sheet.Column(3).Width = 6 #MFA Icon
        $sheet.Column(4).Width = 22 #MFA Registered
        $sheet.Column(5).Width = 17 #Azure Portal
        $sheet.Column(6).Width = 17 #Azure CLI
        $sheet.Column(7).Width = 17 #Azure PowerShell
        $sheet.Column(8).Width = 40 #AuthenticationMethods
        $sheet.Column(9).Width = 15 #UserId
        $sheet.Column(10).Width = 30 #Notes

        Add-ConditionalFormatting -Worksheet $sheet -Range "C2:C$maxRows" -ConditionValue '=$C2="✅"' -RuleType Expression -ForegroundColor Green
        Add-ConditionalFormatting -Worksheet $sheet -Range "C2:C$maxRows" -ConditionValue '=$C2="❌"' -RuleType Expression -ForegroundColor Red

        Export-Excel -ExcelPackage $excel -WorksheetName "MFA Report" -Activate

        Write-Verbose ("Excel workbook {0}" -f $ExcelWorkbookPath)

    }

    function GetTickSymbol($source, $matchString) {
        if ($source -match $matchString) { return "🔵" }
        return ""
    }

    function GetLink($uriFormat, $id, $name) {
        $uri = $uriFormat -replace '%id%', $id
        $hyperlink = '=Hyperlink("%uri%", "%name%")'
        $hyperlink = $hyperlink -replace '%uri%', $uri
        $hyperlink = $hyperlink -replace '%name%', $name
        Write-Verbose $hyperlink
        return ( $hyperlink)
    }

    # Get the authentication method state for each user
    function GetUserMfaInsight($users) {

        if(!$users) {
            Write-Error "No users available to create MFA report." -ErrorAction Stop
        }

        if ($UseAuthenticationMethodEndPoint) { $isPremiumTenant = $false } # Force into free tenant mode
        else { $isPremiumTenant = GetIsPremiumTenant $users }

        #$users = $users | Select-Object -First 10 # For testing

        $totalCount = $users.Count
        $currentCount = 0
        foreach ($user in $users) {
            Write-Verbose $user.UserId
            Write-Verbose $user.UserPrincipalName

            $currentCount++
            AddMfaProperties $user
            UpdateProgress $currentCount $totalCount $user

            $graphUri = (GetGraphBaseUri) + "/v1.0/users/$($user.UserId)/authentication/methods"
            if ($isPremiumTenant) {
                $graphUri = (GetGraphBaseUri) + "/v1.0/reports/authenticationMethods/userRegistrationDetails/$($user.UserId)"
            }
            $resultsJson = Invoke-MgGraphRequest -Uri $graphUri -Method GET -SkipHttpErrorCheck
            $err = Get-ObjectPropertyValue $resultsJson -Property "error"

            if ($err) {
                if($err.code -eq "Authentication_RequestFromUnsupportedUserRole") {
                    $message += $err.message + " The signed-in user needs to be assigned the Microsoft Entra Global Reader role."
                    Write-Error $message -ErrorAction Stop
                }

                $user.Note = $err.message
                continue
            }

            if ($isPremiumTenant) {
                $methodsRegistered = Get-ObjectPropertyValue $resultsJson -Property 'methodsRegistered'
                $userAuthMethod = @()
                foreach ($method in $methodsRegistered) {
                    $methodInfo = $authMethods | Where-Object { $_.ReportType -eq $method }
                    if ($null -eq $methodInfo) { $userAuthMethod += $method }
                    else {
                        if($methodInfo.IsMfa) { $userAuthMethod += $methodInfo.DisplayName }
                    }
                }
                $user.AuthenticationMethods = $userAuthMethod -join ', '
                $user.IsMfaRegistered = Get-ObjectPropertyValue $resultsJson -Property 'isMfaRegistered'
            }
            else {
                $graphMethods = Get-ObjectPropertyValue $resultsJson -Property "value"
                $userAuthMethods = @()
                $isMfaRegistered = $false
                $types = $graphMethods | Select-Object '@odata.type' -Unique
                foreach ($method in $types) {
                    $type = $method.'@odata.type'
                    Write-Verbose "Type: $type"
                    $userAuthMethod = GetAuthMethodInfo $type
                    if ($userAuthMethod.IsMfa) {
                        $isMfaRegistered = $true
                        $userAuthMethods += $userAuthMethod.DisplayName
                    }
                }
                $user.AuthenticationMethods = $userAuthMethods
                $user.IsMfaRegistered = $isMfaRegistered
            }
        }

        return $users
    }

    # Check if the tenant has permissions to call the user registration API.
    function GetIsPremiumTenant($users) {
        $isPremiumTenant = $true
        if ($users -and $users.Count -gt 0) {
            $user = $users[0]
            $graphUri = (GetGraphBaseUri) + "/v1.0/reports/authenticationMethods/userRegistrationDetails/$($user.UserId)"
            $resultsJson = Invoke-MgGraphRequest -Uri $graphUri -Method GET -SkipHttpErrorCheck
            $err = Get-ObjectPropertyValue $resultsJson -Property "error"

            if ($err) {
                $isPremiumTenant = $err.code -ne "Authentication_RequestFromNonPremiumTenantOrB2CTenant"
            }
        }
        return $isPremiumTenant
    }
    function AddMfaProperties($user) {
        $user | Add-Member -MemberType NoteProperty -Name "Note" -Value $null -ErrorAction SilentlyContinue
        $user | Add-Member -MemberType NoteProperty -Name "AuthenticationMethods" -Value $null -ErrorAction SilentlyContinue
        $user | Add-Member -MemberType NoteProperty -Name "IsMfaRegistered" -Value $null -ErrorAction SilentlyContinue
    }

    function UpdateProgress($currentCount, $totalCount, $user) {
        $userStatusDisplay = $user.UserId

        if ([bool]$user.PSObject.Properties["UserPrincipalName"]) {
            $userStatusDisplay = $user.UserPrincipalName
        }

        $percent = [math]::Round(($currentCount / $totalCount) * 100)

        Write-Progress -Activity "Getting authentication method" -Status "[$currentCount of $totalCount] Checking $userStatusDisplay. $percent% complete" -PercentComplete $percent

    }
    function GetGraphBaseUri() {
        return $((Get-MgEnvironment -Name (Get-MgContext).Environment).GraphEndpoint)
    }

    function WriteExportProgress(
        # The current step of the overal generation
        [ValidateSet("ServicePrincipal", "AppPerm", "DownloadDelegatePerm", "ProcessDelegatePerm", "GenerateExcel", "Complete")]
        $MainStep,
        $Status = "Processing...",
        # The percentage of completion within the child step
        $ChildPercent,
        [switch]$ForceRefresh) {
        $percent = 0
        switch ($MainStep) {
            "ServicePrincipal" {
                $percent = GetNextPercent $ChildPercent 2 10
                $activity = "Downloading service principals"
            }
            "AppPerm" {
                $percent = GetNextPercent $ChildPercent 10 50
                $activity = "Downloading application permissions"
            }
            "DownloadDelegatePerm" {
                $percent = GetNextPercent $ChildPercent 50 75
                $activity = "Downloading delegate permissions"
            }
            "ProcessDelegatePerm" {
                $percent = GetNextPercent $ChildPercent 75 90
                $activity = "Processing delegate permissions"
            }
            "GenerateExcel" {
                $percent = GetNextPercent $ChildPercent 90 99
                $activity = "Processing risk information"
            }
            "Complete" {
                $percent = 100
                $activity = "Complete"
            }
        }

        if ($ForceRefresh.IsPresent) {
            Start-Sleep -Milliseconds 250
        }
        Write-Progress -Id 0 -Activity $activity -PercentComplete $percent -Status $Status
    }

    function GetAuthMethodInfo($type) {
        $methodInfo = $authMethods | Where-Object { $_.Type -eq $type}
        if ($null -eq $methodInfo) {
            # Default to the type and assume it is MFA
            $methodInfo = @{
                Type        = $type
                DisplayName = ($type -replace '#microsoft.graph.', '') -replace 'AuthenticationMethod', ''
                IsMfa       = $true
            }
        }
        return $methodInfo
    }

    $authMethods = @(
        @{
            ReportType  = 'passKeyDeviceBoundAuthenticator'
            Type        = $null
            DisplayName = 'Passkey (Microsoft Authenticator)'
            IsMfa       = $true
        },
        @{
            ReportType  = 'passKeyDeviceBound'
            Type        = '#microsoft.graph.fido2AuthenticationMethod'
            DisplayName = "Passkey (other device-bound)"
            IsMfa       = $true
        },
        @{
            ReportType  = 'email'
            Type        = '#microsoft.graph.emailAuthenticationMethod'
            DisplayName = 'Email'
            IsMfa       = $false
        },
        @{
            ReportType  = 'microsoftAuthenticatorPush'
            Type        = '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod'
            DisplayName = 'Microsoft Authenticator'
            IsMfa       = $true
        },
        @{
            ReportType  = 'mobilePhone'
            Type        = '#microsoft.graph.phoneAuthenticationMethod'
            DisplayName = 'Phone'
            IsMfa       = $true
        },
        @{
            ReportType  = 'softwareOneTimePasscode'
            Type        = '#microsoft.graph.softwareOathAuthenticationMethod'
            DisplayName = 'Authenticator app (TOTP)'
            IsMfa       = $true
        },
        @{
            ReportType  = $null
            Type        = '#microsoft.graph.temporaryAccessPassAuthenticationMethod'
            DisplayName = 'Temporary Access Pass'
            IsMfa       = $false
        },
        @{
            ReportType  = 'windowsHelloForBusiness'
            Type        = '#microsoft.graph.windowsHelloForBusinessAuthenticationMethod'
            DisplayName = 'Windows Hello for Business'
            IsMfa       = $true
        },
        @{
            ReportType  = $null
            Type        = '#microsoft.graph.passwordAuthenticationMethod'
            DisplayName = 'Password'
            IsMfa       = $false
        },
        @{
            ReportType  = $null
            Type        = '#microsoft.graph.platformCredentialAuthenticationMethod'
            DisplayName = 'Platform Credential for MacOS'
            IsMfa       = $true
        },
        @{
            ReportType  = 'microsoftAuthenticatorPasswordless'
            Type        = '#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod'
            DisplayName = 'Microsoft Authenticator'
            IsMfa       = $true
        }
    )

    # Call main function
    Main
}
