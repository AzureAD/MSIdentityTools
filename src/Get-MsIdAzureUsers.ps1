<#
.SYNOPSIS
    Returns a list of users that have signed into the Azure portal, Azure CLI, or Azure PowerShell over the last 30 days by querying the sign-in logs.

    If your tenant is a [Microsoft Entra ID Free](https://learn.microsoft.com/entra/identity/monitoring-health/reference-reports-data-retention#activity-reports), the sign-in logs need to be downloaded from

    - Required permission scopes: **Directory.Read.All**, **AuditLog.Read.All**
    - Required Microsoft Entra role: **Global Reader**

.DESCRIPTION
    - Entra ID free tenants have access to sign-in logs for the last 7 days.
    - Entra ID premium tenants have access to sign-in logs for the last 30 days.

.EXAMPLE
    PS > Connect-MgGraph -Scopes Directory.Read.All, AuditLog.Read.All
    PS > Get-MsIdAzureUsers

    Queries all available logs and returns all the users that have signed into Azure.

.EXAMPLE
    PS > Get-MsIdAzureUsers -Days 3

    Queries the logs for the last three days and returns all the users that have signed into Azure during this period.

.EXAMPLE
    PS > Get-MsIdAzureUsers -SignInsJsonPath ./signIns.json

    Uses the sign-ins json file downloaded from the Microsoft Portal and returns all the users that have signed into Azure during this period.

#>

function Get-MsIdAzureUsers {
    [CmdletBinding(HelpUri = 'https://azuread.github.io/MSIdentityTools/commands/Get-MsIdAzureUsers')]
    param (
        # Optional. Path to the sign-ins JSON file. If provided, the report will be generated from this file instead of querying the sign-ins.
        [string]
        $SignInsJsonPath,

        # Number of days to query sign-in logs. Defaults to 30 days for premium tenants and 7 days for free tenants
        [ValidateScript({
                $_ -ge 0 -and $_ -le 30
            },
            ErrorMessage = "Logs are only available for the last 7 days for free tenants and 30 days for premium tenants. Please enter a number between 0 and 30."
        )]
        [int]
        $Days
    )

    $mfaEnforcedApps = @(
        @{
            AppId       = "c44b4083-3bb0-49c1-b47d-974e53cbdf3c"
            DisplayName = "Azure Portal"
        },
        @{
            AppId       = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
            DisplayName = "Microsoft Azure CLI"
        },
        @{
            AppId       = "1950a258-227b-4e31-a9cf-717495945fc2"
            DisplayName = "Microsoft Azure PowerShell"
        }
    )

    function Main() {

        if (!(Test-MgModulePrerequisites @('AuditLog.Read.All', 'Directory.Read.All'))) { return }

        if ($SignInsJsonPath) {
            $users = Get-JsonFileContent -SignInsJsonPath $SignInsJsonPath
        }
        else {
            $users = GetAzureUsers $Days
        }

        if ($users) {
            $users.Values
        }
        else {
            return $null
        }
    }

    function GetAzureUsers($pastDays) {

        # Get the date range to query by subtracting the number of days from today set to midnight
        $appFilter = GetAppFilter
        $statusFilter = "and status/errorcode eq 0"
        $dateFilter = GetDateFilter $pastDays

        # Create an array of filter and join with 'and'
        $filter = "$appFilter $statusFilter $dateFilter"
        Write-Verbose "Graph filter: $filter"
        $select = "userId,userPrincipalName,userDisplayName,appId,createdDateTime,authenticationRequirement,status"

        Write-Progress -Activity "Querying sign-in logs..."

        $earliestDate = GetEarliestDate $filter
        if ($null -eq $earliestDate) {
            Write-Host "No Azure sign-ins found." -ForegroundColor Green
            return
        }

        if ($Days) { $dayDiff = $Days }
        else { $dayDiff = (Get-Date).Subtract($earliestDate).Days }
        Write-Host "Getting sign-in logs for the last $dayDiff days (from $earliestDate to now)..." -ForegroundColor Green
        $graphUri = "$graphBaseUri/beta/auditLogs/signIns?`$filter=$filter"

        Write-Verbose "Getting sign-in logs $graphUri"
        $resultsJson = Invoke-GraphRequest -Uri $graphUri -Method GET
        $nextLink = Get-ObjectPropertyValue $resultsJson -Property '@odata.nextLink'

        $latestDate = $resultsJson.value[0].createdDateTime
        # Create a key/value dictionary to store users by userId
        $azureUsers = @{}

        $count = 0
        do {
            foreach ($item in $resultsJson.value) {
                $count++
                # Check if user exists in the dictionary and create a new object if not
                [string]$userId = $item.userId
                $user = $azureUsers[$userId]

                $hasSignedInWithMfa = GetHasSignedInWithMfa $item

                if ($null -eq $user) {
                    $user = [pscustomobject]@{
                        UserId                    = $item.userId
                        UserPrincipalName         = $item.userPrincipalName
                        UserDisplayName           = $item.userDisplayName
                        AzureAppName              = ""
                        AzureAppId                = @($item.appId)
                        AuthenticationRequirement = $item.authenticationRequirement
                        HasSignedInWithMfa        = $hasSignedInWithMfa
                    }
                    $azureUsers[$userId] = $user
                }
                else {
                    # Add the app if it doesn't already exist
                    if ($user.AzureAppId -notcontains $item.appId) {
                        $user.AzureAppId += $item.appId
                    }
                    # Flag as MFA if user signed in at least once
                    if(!$user.HasSignedInWithMfa -and $hasSignedInWithMfa){
                        $user.HasSignedInWithMfa = $hasSignedInWithMfa
                    }

                    # Set user auth requirement to MFA if MFA was enforced at least once
                    if ($user.AuthenticationRequirement -ne "multiFactorAuthentication" `
                            -and $item.authenticationRequirement -eq "multiFactorAuthentication") {
                        $user.AuthenticationRequirement = $item.authenticationRequirement
                    }
                }
            }

            if ($null -ne $nextLink) {
                $latestProcessedDate = $resultsJson.value[$resultsJson.value.Count - 1].createdDateTime
                $percent = GetProgressPercent $earliestDate $latestDate $latestProcessedDate
                Write-Verbose $percent
                $formattedDate = GetDateDisplayFormat $latestProcessedDate
                $status = "Found $($azureUsers.Count) Azure users. Now processing $formattedDate ($([int]$percent)% completed)"
                Write-Progress -Activity "Checking sign-in logs" -Status $status -PercentComplete $percent
                $resultsJson = Invoke-GraphRequest -Uri $nextLink
            }
            $nextLink = Get-ObjectPropertyValue $resultsJson -Property '@odata.nextLink'
        } while ($null -ne $nextLink)

        # Update the Azure App name for each user
        foreach ($user in $azureUsers.Values) {
            $appNames = @()
            foreach ($appId in $user.AzureAppId) {
                $app = $mfaEnforcedApps | Where-Object { $_.AppId -eq $appId }
                if ($app) {
                    $appNames += $app.DisplayName
                }
            }
            $user.AzureAppName = $appNames -join ", "
        }
        return $azureUsers
    }

    function GetProgressPercent($earliestDate, $latestDate, $processedDate) {
        Write-Verbose "Earliest date: $earliestDate"
        Write-Verbose "Processed date: $processedDate"
        $totalSeconds = ($latestDate - $earliestDate).TotalSeconds
        $processedSeconds = ($latestDate - $processedDate).TotalSeconds
        $percent = ($processedSeconds / $totalSeconds) * 100
        return $percent
    }

    function GetHasSignedInWithMfa($signInItem) {
        $hasSignedInWithMfa = $false
        # Check if MFA was enforced for this succesful sign in
        if($signInItem.authenticationRequirement -eq 'multiFactorAuthentication'){
            $hasSignedInWithMfa = $true
        }
        else { # authenticationRequirement was singleFactorAuthentication
            # Could be a federated sign in where MFA claim was sent even though Entra didn't enforce MFA
            $additionalDetails = Get-ObjectPropertyValue $signInItem.status -Property 'additionalDetails'
            if($additionalDetails -eq 'MFA requirement satisfied by claim in the token'){
                $hasSignedInWithMfa = $true
            }
        }
        return $hasSignedInWithMfa
    }

    function GetEarliestDate($filter) {

        $graphUri = "$graphBaseUri/beta/auditLogs/signIns?`$select=createdDateTime&`$filter=$filter&`$top=1&`$orderby=createdDateTime asc"

        Write-Verbose "Getting earliest date in logs $graphUri"
        $resultsJson = Invoke-GraphRequest -Uri $graphUri -Method GET -SkipHttpErrorCheck

        $err = Get-ObjectPropertyValue $resultsJson -Property "error"
        if ($err) {
            if ($err.code -eq "Authentication_RequestFromUnsupportedUserRole") {
                Write-Host "The signed-in user needs to be assigned the Microsoft Entra Global Reader role." -ForegroundColor Green
            }
            elseif ($err.code -eq "Authentication_RequestFromNonPremiumTenantOrB2CTenant") {
                Write-Host "You are using an Entra ID Free tenant which requires additional steps to download the sign-in logs." -ForegroundColor Green
                Write-Host
                Write-Host "Follow these steps to download the sign-in logs." -ForegroundColor Green
                Write-Host "- Sign-in to https://entra.microsoft.com" -ForegroundColor Green
                Write-Host "- From the left navigation select: Identity → Monitoring & health → Sign-in logs." -ForegroundColor Green
                Write-Host "- Select the 'Date' filter and set to 'Last 7 days'" -ForegroundColor Green
                Write-Host "- Select 'Add filters' → 'Application' and click 'Apply'" -ForegroundColor Green
                Write-Host "- Type in 'Azure' and click 'Apply'" -ForegroundColor Green
                Write-Host "- Select 'Download' → 'Download JSON'" -ForegroundColor Green
                Write-Host "- Set the 'File Name' of the first textbox to 'signins' and click 'Download'." -ForegroundColor Green
                Write-Host "- Once the file is downloaded, copy it to the folder where the export command will be run." -ForegroundColor Green
                Write-Host
                Write-Host "Re-run this command with the -SignInsJsonPath parameter." -ForegroundColor Green
                Write-Host "E.g.> Export-MsIdAzureMfaReport ./report.xlsx -SignInsJsonPath ./signins.json" -ForegroundColor Yellow
            }
            Write-Error $err.message -ErrorAction Stop
        }

        $minDate = $null
        if ($resultsJson.value.Count -ne 0) {
            $minDate = $resultsJson.value[0].createdDateTime
        }

        return $minDate
    }

    function GetDateFilter($pastDays) {
        # Get the date range to query by subtracting the number of days from today set to midnight
        $dateFilter = $null
        if ($pastDays -and $pastDays -gt 0) {
            $dateStart = (Get-Date -Hour 0 -Minute 0 -Second 0).AddDays(-$pastDays)

            # convert the date to the correct format
            $tmzFormat = "yyyy-MM-ddTHH:mm:ssZ"
            $dateStartString = $dateStart.ToString($tmzFormat)

            $dateFilter = "and createdDateTime ge $dateStartString"
        }
        return $dateFilter
    }

    function GetAppFilter() {
        $allAppFilter = $mfaEnforcedApps.AppId -join "' or appid eq '"
        $allAppFilter = "(appid eq '$allAppFilter')"
        return $allAppFilter
    }

    function Get-JsonFileContent ($signInsJsonPath) {
        Write-Verbose "Reading sign-ins from $signInsJsonPath"
        $signIns = Get-Content $signInsJsonPath -Raw | ConvertFrom-Json

        $azureUsers = @{}
        $count = 0

        foreach ($item in $signIns) {
            $count++
            # Check if user exists in the dictionary and create a new object if not
            [string]$userId = $item.userId
            $user = $azureUsers[$userId]
            if ($null -eq $user) {
                $user = [pscustomobject]@{
                    UserId                    = $item.userId
                    UserPrincipalName         = $item.userPrincipalName
                    UserDisplayName           = $item.userDisplayName
                    AzureAppName              = ""
                    AzureAppId                = @($item.appId)
                    AuthenticationRequirement = $item.authenticationRequirement
                }
                $azureUsers[$userId] = $user
            }
            else {
                # Add the app if it doesn't already exist
                if ($user.AzureAppId -notcontains $item.appId) {
                    $user.AzureAppId += $item.appId
                }
                # Flag as MFA if user signed in at least once
                if ($user.AuthenticationRequirement -ne "multiFactorAuthentication" `
                        -and $item.authenticationRequirement -eq "multiFactorAuthentication") {
                    $user.AuthenticationRequirement = $item.authenticationRequirement
                }
            }
        }

        # Update the Azure App name for each user
        foreach ($user in $azureUsers.Values) {
            $appNames = @()
            foreach ($appId in $user.AzureAppId) {
                $app = $mfaEnforcedApps | Where-Object { $_.AppId -eq $appId }
                if ($app) {
                    $appNames += $app.DisplayName
                }
            }
            $user.AzureAppName = $appNames -join ", "
        }
        return $azureUsers
    }

    function WriteExportProgress(
        # The current step of the overal generation
        [ValidateSet("Logs")]
        $MainStep,
        $Status = "Processing...",
        # The percentage of completion within the child step
        $ChildPercent,
        [switch]$ForceRefresh) {
        $percent = 0
        switch ($MainStep) {
            "Logs" {
                $percent = GetNextPercent $ChildPercent 0 100
                $activity = "Checking sign-in logs"
            }
        }

        if ($ForceRefresh.IsPresent) {
            Start-Sleep -Milliseconds 250
        }
        Write-Progress -Id 0 -Activity $activity -PercentComplete $percent -Status $Status
    }
    function GetNextPercent($childPercent, $parentPercent, $nextPercent) {
        if ($childPercent -eq 0) { return $parentPercent }

        $gap = $nextPercent - $parentPercent
        return (($childPercent / 100) * $gap) + $parentPercent
    }

    function GetDateDisplayFormat($date) {
        return $date.ToString("dd MMM yyyy h:00 tt")
    }

    $graphBaseUri = Get-GraphBaseUri
    # Call main function
    Main
}
