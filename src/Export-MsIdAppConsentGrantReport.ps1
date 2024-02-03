<#
.SYNOPSIS
    Lists and categorizes privilege for delegated permissions (OAuth2PermissionGrants) and application permissions (AppRoleAssignments).
    NOTE: This cmdlet can take many hours to run on large tenants.

.DESCRIPTION
    This cmdlet requires the `ImportExcel` module to be installed if you use the `-ReportOutputType ExcelWorkbook` parameter.

.EXAMPLE
    PS > Install-Module ImportExcel
    PS > Connect-MgGragh -Scopes Application.Read.All
    PS > Export-MsIdAppConsentGrantReport -ReportOutputType ExcelWorkbook -ExcelWorkbookPath .\report.xlsx

    Output a report in Excel format

.EXAMPLE
    PS > Export-MsIdAppConsentGrantReport -ReportOutputType ExcelWorkbook -ExcelWorkbookPath .\report.xlsx -PermissionsTableCsvPath .\table.csv

    Output a report in Excel format and specify a local path for a customized CSV containing consent privilege categorizations

#>
function Export-MsIdAppConsentGrantReport {
    param (
        # Output type for the report.
        [ValidateSet("ExcelWorkbook", "PowerShellObjects")]
        [string]
        $ReportOutputType = "ExcelWorkbook",

        # Output file location for Excel Workbook
        [Parameter(ParameterSetName = 'Excel Workbook Output')]
        [Parameter(Mandatory = $false)]
        [string]
        $ExcelWorkbookPath,

        # Path to CSV file for Permissions Table
        # If not provided the default table will be downloaded from GitHub https://raw.githubusercontent.com/AzureAD/MSIdentityTools/main/assets/aadconsentgrantpermissiontable.csv
        [string]
        $PermissionsTableCsvPath
    )

    $script:ObjectByObjectId = @{} # Cache for all directory objects
    $script:KnownMSTenantIds = @("f8cdef31-a31e-4b4a-93e4-5f571e91255a", "72f988bf-86f1-41af-91ab-2d7cd011db47")

    function Main() {
        if ("ExcelWorkbook" -eq $ReportOutputType) {
            # Determine if the ImportExcel module is installed since the parameter was included
            if ($null -eq (Get-Module -Name ImportExcel -ListAvailable)) {
                throw "The ImportExcel module is not installed. This is used to export the results to an Excel worksheet. Please install the ImportExcel Module before using this parameter or run without this parameter."
            }
        }

        if ($null -eq (Get-MgContext)) {
            Connect-MgGraph -Scopes Directory.Read.All
        }
        if ($null -eq (Get-MgContext)) {
            throw "You must connect to the Microsoft Graph before running this command."
        }

        $appConsents = GetAppConsentGrants

        if ($null -ne $appConsents) {
            $appConsentsWithRank = AddPrivilegeRanking $appConsents

            if ("ExcelWorkbook" -eq $ReportOutputType) {
                Write-Verbose "Generating Excel workbook at $ExcelWorkbookPath"
                SetMainProgress GenerateExcel
                GenerateExcelReport -AppConsentsWithRank $appConsentsWithRank -Path $ExcelWorkbookPath
            }
            else {
                Write-Output $appConsentsWithRank
            }
            SetMainProgress Complete
        }
        else {
            throw "An error occurred while retrieving app consent grants. Please try again."
        }
    }

    function GenerateExcelReport ($AppConsentsWithRank, $Path) {

        $maxRows = $AppConsentsWithRank.Count + 1

        # Delete the existing output file if it already exists
        $OutputFileExists = Test-Path $Path
        if ($OutputFileExists -eq $true) {
            Get-ChildItem $Path | Remove-Item -Force
        }

        $count = 0
        $highprivilegeobjects = $AppConsentsWithRank | Where-Object { $_.Privilege -eq "High" }
        $highprivilegeobjects | ForEach-Object {
            $userAssignmentRequired = @()
            $userAssignmentsCount = @()
            $clientId = $_.ClientObjectId
            $userAssignmentRequired = $script:ServicePrincipals | Where-Object { $_.Id -eq $clientId }

            if ($userAssignmentRequired.AppRoleAssignmentRequired -eq $true) {
                $userAssignmentsCount = $userAssignmentRequired.UsersAssignedCount
                Add-Member -InputObject $_ -MemberType NoteProperty -Name UsersAssignedCount -Value $userAssignmentsCount
            }
            elseif ($userAssignmentRequired.AppRoleAssignmentRequired -eq $false) {
                $userAssignmentsCount = "AllUsers"
                Add-Member -InputObject $_ -MemberType NoteProperty -Name UsersAssignedCount -Value $userAssignmentsCount
            }

            $count++
            $genPercent = (($count / $highprivilegeobjects.Count) * 100)
            SetMainProgress GenerateExcel -childPercent $genPercent
            Write-Progress -ParentId 0 -Id 1 -Activity "{$_.Id}" -Status "Apps Counted: $count of $($highprivilegeobjects.Count)" -PercentComplete $genPercent
        }
        $highprivilegeusers = $highprivilegeobjects | Where-Object { $null -ne $_.PrincipalObjectId } | Select-Object PrincipalDisplayName, Privilege | Sort-Object PrincipalDisplayName -Unique
        $highprivilegeapps = $highprivilegeobjects | Select-Object ClientDisplayName, Privilege, UsersAssignedCount, MicrosoftApp | Sort-Object ClientDisplayName -Unique | Sort-Object UsersAssignedCount -Descending

        # Pivot table by user
        $pt = New-PivotTableDefinition -SourceWorksheet ConsentGrantData `
            -PivotTableName "PermissionsByUser" `
            -PivotFilter PrivilegeFilter, PermissionFilter, ResourceDisplayNameFilter, ConsentTypeFilter, ClientDisplayName, MicrosoftApp `
            -PivotRows PrincipalDisplayName `
            -PivotColumns Privilege, PermissionType `
            -PivotData @{Permission = 'Count' } `
            -IncludePivotChart `
            -ChartType ColumnStacked `
            -ChartHeight 800 `
            -ChartWidth 1200 `
            -ChartRow 4 `
            -ChartColumn 14 `
            -WarningAction SilentlyContinue

        # Pivot table by resource
        $pt += New-PivotTableDefinition -SourceWorksheet ConsentGrantData `
            -PivotTableName "PermissionsByResource" `
            -PivotFilter PrivilegeFilter, ResourceDisplayNameFilter, ConsentTypeFilter, PrincipalDisplayName, MicrosoftApp `
            -PivotRows ResourceDisplayName, PermissionFilter `
            -PivotColumns Privilege, PermissionType `
            -PivotData @{Permission = 'Count' } `
            -IncludePivotChart `
            -ChartType ColumnStacked `
            -ChartHeight 800 `
            -ChartWidth 1200 `
            -ChartRow 4 `
            -ChartColumn 14 `
            -WarningAction SilentlyContinue

        # Pivot table by privilege rating
        $pt += New-PivotTableDefinition -SourceWorksheet ConsentGrantData `
            -PivotTableName "PermissionsByPrivilegeRating" `
            -PivotFilter PrivilegeFilter, PermissionFilter, ResourceDisplayNameFilter, ConsentTypeFilter, PrincipalDisplayName, MicrosoftApp `
            -PivotRows Privilege, ResourceDisplayName `
            -PivotColumns PermissionType `
            -PivotData @{Permission = 'Count' } `
            -IncludePivotChart `
            -ChartType ColumnStacked `
            -ChartHeight 800 `
            -ChartWidth 1200 `
            -ChartRow 4 `
            -ChartColumn 5 `
            -WarningAction SilentlyContinue


        $styles = @(
            New-ExcelStyle -FontColor White -BackgroundColor DarkBlue -Bold -Range "A1:P1" -Height 20 -FontSize 12 -VerticalAlignment Center
            New-ExcelStyle -FontColor Blue -Underline -Range "E2:E$maxRows"
            New-ExcelStyle -FontColor Blue -Underline -Range "M2:M$maxRows"
        )

        $excel = $AppConsentsWithRank | Export-Excel -Path $Path -WorksheetName ConsentGrantData `
            -PivotTableDefinition $pt `
            -FreezeTopRow `
            -AutoFilter `
            -Activate `
            -Style $styles `
            -HideSheet "None" `
            -PassThru

        $style = New-ExcelStyle -FontColor White -BackgroundColor DarkBlue -Bold -Range "A1:B1" -Height 20 -FontSize 12 -VerticalAlignment Center
        $highprivilegeusers | Export-Excel -ExcelPackage $excel -WorksheetName HighPrivilegeUsers -Style $style -PassThru -FreezeTopRow -AutoFilter | Out-Null
        $style = New-ExcelStyle -FontColor White -BackgroundColor DarkBlue -Bold -Range "A1:D1" -Height 20 -FontSize 12 -VerticalAlignment Center
        $highprivilegeapps | Export-Excel -ExcelPackage $excel -WorksheetName HighPrivilegeApps -Style $style -PassThru -FreezeTopRow -AutoFilter | Out-Null

        $consentSheet = $excel.Workbook.Worksheets["ConsentGrantData"]
        $consentSheet.Column(1).Width = 20 #PermissionType
        $consentSheet.Column(2).Hidden = $true #ConsentTypeFilter
        $consentSheet.Column(3).Hidden = $true #ClientObjectId
        $consentSheet.Column(4).Hidden = $true #AppId
        $consentSheet.Column(5).Width = 40 #ClientDisplayName
        $consentSheet.Column(6).Hidden = $true #ResourceObjectId
        $consentSheet.Column(7).Hidden = $true #ResourceObjectIdFilter
        $consentSheet.Column(8).Width = 40 #ResourceDisplayName
        $consentSheet.Column(9).Hidden = $true #ResourceDisplayNameFilter
        $consentSheet.Column(10).Width = 40 #Permission
        $consentSheet.Column(11).Hidden = $true #PermissionFilter
        $consentSheet.Column(12).Hidden = $true #PrincipalObjectId
        $consentSheet.Column(13).Width = 23 #PrincipalDisplayName
        $consentSheet.Column(14).Width = 17 #MicrosoftApp
        $consentSheet.Column(15).Hidden = $true #AppOwnerOrganizationId
        $consentSheet.Column(16).Width = 15 #Privilege
        $consentSheet.Column(17).Hidden = $true #PrivilegeFilter

        $consentSheet.Column(14).Style.HorizontalAlignment = "Center" #MicrosoftApp
        $consentSheet.Column(16).Style.HorizontalAlignment = "Center" #Privilege

        Add-ConditionalFormatting -Worksheet $consentSheet -Range "A1:Z$maxRows" -RuleType Equal -ConditionValue "High" -ForegroundColor White -BackgroundColor Red
        Add-ConditionalFormatting -Worksheet $consentSheet -Range "A1:Z$maxRows" -RuleType Equal -ConditionValue "Medium" -ForegroundColor Black -BackgroundColor Orange
        Add-ConditionalFormatting -Worksheet $consentSheet -Range "A1:Z$maxRows" -RuleType Equal -ConditionValue "Low" -ForegroundColor Black -BackgroundColor LightGreen
        Add-ConditionalFormatting -Worksheet $consentSheet -Range "A1:Z$maxRows" -RuleType Equal -ConditionValue "Unranked" -ForegroundColor Black -BackgroundColor LightGray

        $userSheet = $excel.Workbook.Worksheets["HighPrivilegeUsers"]
        Add-ConditionalFormatting -Worksheet $userSheet -Range "B1:B$maxRows" -RuleType Equal -ConditionValue "High" -ForegroundColor White -BackgroundColor Red
        Set-ExcelRange -Worksheet $userSheet -Range "A1:C$maxRows"
        $userSheet.Column(1).Width = 45 #PrincipalDisplayName
        $userSheet.Column(2).Width = 20 #Privilege
        $userSheet.Column(2).Style.HorizontalAlignment = "Center" #Privilege


        $appSheet = $excel.Workbook.Worksheets["HighPrivilegeApps"]
        Add-ConditionalFormatting -Worksheet $appSheet -Range "B1:B$maxRows" -RuleType Equal -ConditionValue "High" -ForegroundColor White -BackgroundColor Red
        Set-ExcelRange -Worksheet $appSheet -Range "A1:C$maxRows"
        $appSheet.Column(1).Width = 45 #ClientDisplayName
        $appSheet.Column(2).Width = 20 #Privilege
        $appSheet.Column(3).Width = 20 #UsersAssignedCount
        $appSheet.Column(4).Width = 17 #MicrosoftApp

        $appSheet.Column(2).Style.HorizontalAlignment = "Center" #Privilege
        $appSheet.Column(4).Style.HorizontalAlignment = "Center" #MicrosoftApp

        Export-Excel -ExcelPackage $excel
        Remove-Worksheet -Path $Path -WorksheetName "Sheet1" | Out-Null
        Write-Verbose ("Excel workbook {0}" -f $ExcelWorkbookPath)
    }

    function GetAppConsentGrants {
        # Get all ServicePrincipal objects and add to the cache
        Write-Verbose "Retrieving ServicePrincipal objects..."

        SetMainProgress ServicePrincipal
        Write-Progress -ParentId 0 -Id 1 -Activity "Retrieving service principal count..."
        $count = Get-MgServicePrincipalCount -ConsistencyLevel eventual
        SetMainProgress ServicePrincipal -childPercent 5
        Write-Progress -ParentId 0 -Id 1 -Activity "Retrieving $count service principals." -Status "This can take some time please wait..."
        $servicePrincipalProps = "id,appId,appOwnerOrganizationId,displayName,appRoles"
        $script:ServicePrincipals = Get-MgServicePrincipal -ExpandProperty "appRoleAssignments" -Select $servicePrincipalProps -All -PageSize 999

        $allPermissions = @()
        $allPermissions += GetApplicationPermissions
        $allPermissions += GetDelegatePermissions

        return $allPermissions
    }

    function CacheObject($Object) {
        if ($Object) {
            $script:ObjectByObjectId[$Object.Id] = $Object
        }
    }

    # Function to retrieve an object from the cache (if it's there), or from Entra ID (if not).
    function GetObjectByObjectId($ObjectId) {
        if (-not $script:ObjectByObjectId.ContainsKey($ObjectId)) {
            Write-Verbose ("Querying Entra ID for object '{0}'" -f $ObjectId)
            try {
                $object = (Get-MgDirectoryObjectById -Ids $ObjectId)
                CacheObject -Object $object
            }
            catch {
                Write-Verbose "Object not found."
            }
        }
        return $script:ObjectByObjectId[$ObjectId]
    }

    function IsMicrosoftApp($AppOwnerOrganizationId) {
        if ($AppOwnerOrganizationId -in $script:KnownMSTenantIds) {
            return "Yes"
        }
        else {
            return "No"
        }
    }

    function GetServicePrincipalLink($spId, $appId, $name) {
        if ("ExcelWorkbook" -ne $ReportOutputType) { return $name }

        if ($null -eq $spId -or $null -eq $appId -or $null -eq $name) {
            return $null
        }
        else {
            return "=HYPERLINK(`"https://entra.microsoft.com/#view/Microsoft_AAD_IAM/ManagedAppMenuBlade/~/Overview/objectId/$($spId)/appId/$($appId)/preferredSingleSignOnMode~/null/servicePrincipalType/Application/fromNav/`",`"$($name)`")"
        }
    }

    function GetUserLink($userId, $name) {
        if ("ExcelWorkbook" -ne $ReportOutputType) { return $name }
        if ($null -eq $userId -or $null -eq $name) {
            return $null
        }
        else {
            return "=HYPERLINK(`"https://entra.microsoft.com/#view/Microsoft_AAD_UsersAndTenants/UserProfileMenuBlade/~/overview/userId/$($userId)/hidePreviewBanner~/true`",`"$($name)`")"
        }
    }

    function GetDelegatePermissions {
        $count = 0
        $permissions = @()
        foreach ($client in $script:servicePrincipals) {
            $count++
            $delPercent = (($count / $servicePrincipals.Count) * 100)
            SetMainProgress DelegatePerm -childPercent $delPercent
            Write-Progress -ParentId 0 -Id 1 -Activity $client.DisplayName -Status "$count of $($servicePrincipals.Count)" -PercentComplete $delPercent

            $isMicrosoftApp = IsMicrosoftApp -AppOwnerOrganizationId $client.AppOwnerOrganizationId
            $spLink = GetServicePrincipalLink -spId $client.Id -appId $client.AppId -name $client.DisplayName
            $oAuth2PermGrants = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $client.Id -All -PageSize 999

            foreach ($grant in $oAuth2PermGrants) {
                if ($grant.Scope) {
                    $grant.Scope.Split(" ") | Where-Object { $_ } | ForEach-Object {
                        $scope = $_
                        $resource = GetObjectByObjectId -ObjectId $grant.ResourceId
                        $principalDisplayName = ""

                        if ($grant.PrincipalId) {
                            $principal = GetObjectByObjectId -ObjectId $grant.PrincipalId
                            $principalDisplayName = $principal.AdditionalProperties.displayName
                        }

                        $simplifiedgranttype = ""
                        if ($grant.ConsentType -eq "AllPrincipals") {
                            $simplifiedgranttype = "Delegated-AllPrincipals"
                        }
                        elseif ($grant.ConsentType -eq "Principal") {
                            $simplifiedgranttype = "Delegated-Principal"
                        }

                        $permissions += New-Object PSObject -Property ([ordered]@{
                                "PermissionType"            = $simplifiedgranttype
                                "ConsentTypeFilter"         = $simplifiedgranttype
                                "ClientObjectId"            = $client.Id
                                "AppId"                     = $client.AppId
                                "ClientDisplayName"         = $spLink
                                "ResourceObjectId"          = $grant.ResourceId
                                "ResourceObjectIdFilter"    = $grant.ResourceId
                                "ResourceDisplayName"       = $resource.AdditionalProperties.displayName
                                "ResourceDisplayNameFilter" = $resource.AdditionalProperties.displayName
                                "Permission"                = $scope
                                "PermissionFilter"          = $scope
                                "PrincipalObjectId"         = $grant.PrincipalId
                                "PrincipalDisplayName"      = GetUserLink -userId $grant.PrincipalId -name $principalDisplayName
                                "MicrosoftApp"              = $isMicrosoftApp
                                "AppOwnerOrganizationId"    = $client.AppOwnerOrganizationId
                            })
                    }
                }
            }
        }
        return $permissions
    }

    function GetApplicationPermissions() {
        $count = 0
        $permissions = @()

        # We need to call Get-MgServicePrincipal again so we can expand appRoleAssignments

        #$servicePrincipalsWithAppRoleAssignments = Get-MgServicePrincipal -ExpandProperty "appRoleAssignments" -Select $servicePrincipalProps -All -PageSize 999
        foreach ($client in $script:ServicePrincipals) {
            $count++
            $appPercent = (($count / $servicePrincipals.Count) * 100)
            SetMainProgress AppPerm -childPercent $appPercent
            Write-Progress -ParentId 0 -Id 1 -Activity $client.DisplayName -Status "$count of $($servicePrincipals.Count)" -PercentComplete $appPercent

            $isMicrosoftApp = IsMicrosoftApp -AppOwnerOrganizationId $client.AppOwnerOrganizationId
            $spLink = GetServicePrincipalLink -spId $client.Id -appId $client.AppId -name $client.DisplayName
            Write-Verbose $client.Id

            $grantCount = 0
            foreach ($grant in $client.AppRoleAssignments) {
                $grantCount++
                # Look up the related SP to get the name of the permission from the AppRoleId GUID
                $appRole = $servicePrincipals.AppRoles | Where-Object { $_.id -eq $grant.AppRoleId } | Select-Object -First 1
                $appRoleValue = $grant.AppRoleId
                if ($null -ne $appRole.value -and $appRole.Value -ne "") {
                    $appRoleValue = $appRole.Value
                }

                $permissions += New-Object PSObject -Property ([ordered]@{
                        "PermissionType"            = "Application"
                        "ConsentTypeFilter"         = "Application"
                        "ClientObjectId"            = $client.Id
                        "AppId"                     = $client.AppId
                        "ClientDisplayName"         = $spLink
                        "ResourceObjectId"          = $grant.ResourceId
                        "ResourceObjectIdFilter"    = $grant.ResourceId
                        "ResourceDisplayName"       = $grant.ResourceDisplayName
                        "ResourceDisplayNameFilter" = $grant.ResourceDisplayName
                        "Permission"                = $appRoleValue
                        "PermissionFilter"          = $appRoleValue
                        "PrincipalObjectId"         = ""
                        "PrincipalDisplayName"      = ""
                        "MicrosoftApp"              = $isMicrosoftApp
                        "AppOwnerOrganizationId"    = $client.AppOwnerOrganizationId
                    })
            }
            Add-Member -InputObject $client -MemberType NoteProperty -Name UsersAssignedCount -Value $grantCount
        }
        return $permissions
    }

    function AddPrivilegeRanking ($AppConsents) {

        $permstable = GetPermissionsTable -PermissionsTableCsvPath $PermissionsTableCsvPath

        # Process Privilege for gathered data
        $count = 0
        $AppConsents | ForEach-Object {
            try {
                $count++
                Write-Progress -ParentId 0 -Id 1 -Activity "Processing privilege for each permission . . ." -Status "Processed: $count of $($AppConsents.Count)" -PercentComplete (($count / $AppConsents.Count) * 100)

                $scope = $_.Permission
                if ($_.PermissionType -eq "Delegated-AllPrincipals" -or "Delegated-Principal") {
                    $type = "Delegated"
                }
                elseif ($_.PermissionType -eq "Application") {
                    $type = "Application"
                }

                # Check permission table for an exact match
                $privilege = $null
                $scoperoot = @()
                Write-Debug ("Permission Scope: $Scope")

                if ($scope -match '.') {
                    $scoperoot = $scope.Split(".")[0]
                }
                else {
                    $scoperoot = $scope
                }

                $test = Get-ObjectPropertyValue ($permstable | Where-Object { $_.Permission -eq "$scoperoot" -and $_.Type -eq $type }) 'Privilege' # checking if there is a matching root in the CSV
                $privilege = Get-ObjectPropertyValue ($permstable | Where-Object { $_.Permission -eq "$scope" -and $_.Type -eq $type }) 'Privilege' # Checking for an exact match

                # Search for matching root level permission if there was no exact match
                if (!$privilege -and $test) {
                    # No exact match, but there is a root match
                    $privilege = ($permstable | Where-Object { $_.Permission -eq "$scoperoot" -and $_.Type -eq $type }).Privilege
                }
                elseif (!$privilege -and !$test -and $type -eq "Application" -and $scope -like "*Write*") {
                    # Application permissions without exact or root matches with write scope
                    $privilege = "High"
                }
                elseif (!$privilege -and !$test -and $type -eq "Application" -and $scope -notlike "*Write*") {
                    # Application permissions without exact or root matches without write scope
                    $privilege = "Medium"
                }
                elseif ($privilege) {

                }
                else {
                    # Any permissions without a match, should be primarily Delegated permissions
                    $privilege = "Unranked"
                }

                # Add the privilege to the current object
                Add-Member -InputObject $_ -MemberType NoteProperty -Name Privilege -Value $privilege
                Add-Member -InputObject $_ -MemberType NoteProperty -Name PrivilegeFilter -Value $privilege
            }
            catch {
                Write-Error "Error processing permission for $_"
            }
            finally {
                Write-Output $_
            }
        }
    }

    function GetPermissionsTable {
        param ($PermissionsTableCsvPath)

        if ($null -like $PermissionsTableCsvPath) {
            # Create hash table of permissions and permissions privilege
            $permstable = Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/AzureAD/MSIdentityTools/main/assets/aadconsentgrantpermissiontable.csv' | ConvertFrom-Csv -Delimiter ','
        }
        else {

            $permstable = Import-Csv $PermissionsTableCsvPath -Delimiter ','
        }

        return $permstable
    }

    function SetMainProgress(
        # The current step of the overal generation
        [ValidateSet("ServicePrincipal", "AppPerm", "DelegatePerm", "GenerateExcel", "Complete")]
        $mainStep,
        # The percentage of completion within the child step
        $childPercent) {
        $percent = 0
        switch ($mainStep) {
            "ServicePrincipal" {
                $percent = GetNextPercent $childPercent 2 10
                $status = "Retrieving service principals"
            }
            "AppPerm" {
                $percent = GetNextPercent $childPercent 10 50
                $status = "Retrieving application permissions"
            }
            "DelegatePerm" {
                $percent = GetNextPercent $childPercent 50 90
                $status = "Retrieving delegate permissions"
            }
            "GenerateExcel" {
                $percent = GetNextPercent $childPercent 90 99
                $status = "Processing risk information"
            }
            "Complete" {
                $percent = 100
                $status = "Complete"
            }
        }

        Write-Progress -Id 0 -Activity "Generating App Consent Report" -PercentComplete $percent -Status $status
    }

    function GetNextPercent($childPercent, $parentPercent, $nextPercent) {
        if ($childPercent -eq 0) { return $parentPercent }

        $gap = $nextPercent - $parentPercent
        return (($childPercent / 100) * $gap) + $parentPercent
    }

    # Call main function
    Main
}
