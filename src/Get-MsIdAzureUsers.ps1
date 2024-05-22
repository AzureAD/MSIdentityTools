<#
.SYNOPSIS
    Returns a list of all the users that have signed into the Azure portal, CLI, PowerShell.

.DESCRIPTION
    - Entra ID free tenants have access to sign in logs for the last 7 days.
    - Entra ID premium tenants have access to sign in logs for the last 30 days.
    - The cmdlet will query the sign in log from the most recent day and work backwards.

.EXAMPLE
    PS > Connect-MgGragh -Scopes AuditLog.Read.All
    PS > Get-MsIdAzureUsers

    Queries all available logs and returns all the users that have signed into Azure.

.EXAMPLE
    PS > Get-MsIdAzureUsers -Days 3

    Queries the logs for the last three days and returns all the users that have signed into Azure during this period.
#>

function Get-MsIdAzureUsers {
    [CmdletBinding()]
    param (
        # Number of days to query sign in logs. Defaults to 30 days for premium tenants and 7 days for free tenants
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

        $users = GetAzureUsers $Days
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
        $select = "userId,userPrincipalName,userDisplayName,appId,createdDateTime"

        Write-Progress -Activity "Querying sign in logs..."

        $earliestDate = GetEarliestDate $filter
        if ($null -eq $earliestDate) {
            Write-Warning "No Azure sign ins found."
            return
        }

        $graphUri = (GetGraphBaseUri) + "/v1.0/auditLogs/signIns?`$select=$select&`$filter=$filter"

        Write-Verbose "Getting sign in logs $graphUri"
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
                if ($null -eq $user) {
                    $user = [pscustomobject]@{
                        UserId            = $item.userId
                        UserPrincipalName = $item.userPrincipalName
                        UserDisplayName   = $item.userDisplayName
                        AzureAppName      = ""
                        AzureAppId        = @($item.appId)
                    }
                    $azureUsers[$userId] = $user
                }
                else {
                    # Add the app if it doesn't already exist
                    if ($user.AzureAppId -notcontains $item.appId) {
                        $user.AzureAppId += $item.appId
                    }
                }
            }

            if ($null -ne $nextLink) {
                $latestProcessedDate = $resultsJson.value[$resultsJson.value.Count - 1].createdDateTime
                $percent = GetProgressPercent $earliestDate $latestDate $latestProcessedDate
                Write-Verbose $percent
                $formattedDate = GetDateDisplayFormat $latestProcessedDate
                $status = "Found $($azureUsers.Count) Azure users. Now processing $formattedDate ($([int]$percent)% completed)"
                Write-Progress -Activity "Checking sign in logs" -Status $status -PercentComplete $percent
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

    function GetEarliestDate($filter) {

        $graphUri = (GetGraphBaseUri) + "/v1.0/auditLogs/signIns?`$select=createdDateTime&`$filter=$filter&`$top=1&`$orderby=createdDateTime asc"

        Write-Verbose "Getting earliest date in logs $graphUri"
        $resultsJson = Invoke-GraphRequest -Uri $graphUri -Method GET

        $minDate = $null
        if ($resultsJson.value.Count -ne 0) {
            $minDate = $resultsJson.value[0].createdDateTime
        }

        return $minDate
    }

    function GetDateFilter($pastDays) {
        # Get the date range to query by subtracting the number of days from today set to midnight
        $dateFilter = $null
        if ($pastDays -or $pastDays -gt 0) {
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

    function GetGraphBaseUri() {
        return $((Get-MgEnvironment -Name (Get-MgContext).Environment).GraphEndpoint)
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
                $activity = "Checking sign in logs"
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

    # Call main function
    Main
}
