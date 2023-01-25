<#
.SYNOPSIS
    Get Statistics for Set of Azure AD Provisioning Logs

.EXAMPLE
    PS > Get-MgAuditLogProvisioning -Filter "jobId eq '<jobId>'" | Get-MsIdProvisioningLogStatistics -SummarizeByCycleId -WriteToConsole

    Get Statistics for Set of Azure AD Provisioning Logs

#>
function Get-MsIdProvisioningLogStatistics {
    [CmdletBinding()]
    param (
        # Provisioning Logs
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]] $ProvisioningLogs,
        # Summarize Logs by CycleId
        [Parameter(Mandatory = $false)]
        [switch] $SummarizeByCycleId,
        # Write Summary to Host Console in addition to Standard Output
        [Parameter(Mandatory = $false)]
        [switch] $WriteToConsole
    )

    begin {
        function New-CycleSummary ($CycleId) {
            return [pscustomobject][ordered]@{
                CycleId          = $CycleId
                StartDateTime    = $null
                EndDateTime      = $null
                Changes          = 0
                Users            = 0
                ActionStatistics = @(
                    New-ActionStatusStatistics 'Create'
                    New-ActionStatusStatistics 'Update'
                    New-ActionStatusStatistics 'Delete'
                    New-ActionStatusStatistics 'Disable'
                    New-ActionStatusStatistics 'StagedDelete'
                    New-ActionStatusStatistics 'Other'
                )
            }
        }

        function New-ActionStatusStatistics ($Action) {
            return [PSCustomObject][ordered]@{
                Action  = $Action
                Success = 0
                Failure = 0
                Skipped = 0
                Warning = 0
            }
        }

        $CycleSummary = New-CycleSummary
        $CycleSummary.CycleId = New-Object 'System.Collections.Generic.List[string]'
        $CycleTracker = @{
            ChangeIds = New-Object 'System.Collections.Generic.HashSet[string]'
            UserIds   = New-Object 'System.Collections.Generic.HashSet[string]'
        }

        $CycleSummaries = [ordered]@{}
        $CycleTrackers = @{}
    }

    process {
        foreach ($ProvisioningLog in $ProvisioningLogs) {
            if ($SummarizeByCycleId) {
                if (!$CycleSummaries.Contains($ProvisioningLog.CycleId)) {
                    ## New CycleSummary object for new CycleId
                    $CycleSummaries[$ProvisioningLog.CycleId] = $CycleSummary = New-CycleSummary $ProvisioningLog.CycleId
                    $CycleTrackers[$ProvisioningLog.CycleId] = $CycleTracker = @{
                        ChangeIds = New-Object 'System.Collections.Generic.HashSet[string]'
                        UserIds   = New-Object 'System.Collections.Generic.HashSet[string]'
                    }
                }
                else {
                    $CycleSummary = $CycleSummaries[$ProvisioningLog.CycleId]
                    $CycleTracker = $CycleTrackers[$ProvisioningLog.CycleId]
                }
            }
            else {
                ## Add CycleId to a single summary object
                if (!$CycleSummary.CycleId.Contains($ProvisioningLog.CycleId)) { $CycleSummary.CycleId.Add($ProvisioningLog.CycleId) }
            }

            ## Update log date range
            if ($null -eq $CycleSummary.StartDateTime -or $ProvisioningLog.ActivityDateTime -lt $CycleSummary.StartDateTime) {
                $CycleSummary.StartDateTime = $ProvisioningLog.ActivityDateTime
            }
            if ($null -eq $CycleSummary.EndDateTime -or $ProvisioningLog.ActivityDateTime -gt $CycleSummary.EndDateTime) {
                $CycleSummary.EndDateTime = $ProvisioningLog.ActivityDateTime
            }

            ## Update summary object with statistics
            if ($CycleTracker.ChangeIds.Add($ProvisioningLog.ChangeId)) { $CycleSummary.Changes++ }
            if ($CycleTracker.UserIds.Add($ProvisioningLog.SourceIdentity.Id)) { $CycleSummary.Users++ }

            $CycleSummary.ActionStatistics | Where-Object Action -EQ $ProvisioningLog.ProvisioningAction | ForEach-Object { $_.($ProvisioningLog.ProvisioningStatusInfo.Status)++ }
        }
    }

    end {
        if ($SummarizeByCycleID) {
            [array] $CycleSummaries = $CycleSummaries.Values
        }
        else {
            [array] $CycleSummaries = $CycleSummary
        }

        foreach ($CycleSummary in $CycleSummaries) {
            Write-Output $CycleSummary

            if ($WriteToConsole) {
                Write-Host ('')
                Write-Host ("CycleId: {0}" -f ($CycleSummary.CycleId -join ', '))
                Write-Host ("Timespan: {0} - {1} ({2})" -f $CycleSummary.StartDateTime, $CycleSummary.EndDateTime, ($CycleSummary.EndDateTime - $CycleSummary.StartDateTime))
                Write-Host ("Total Changes: {0}" -f $CycleSummary.Changes)
                Write-Host ("Total Users: {0}" -f $CycleSummary.Users)
                Write-Host ('')

                $TableRowPattern = '{0,-12} {1,7} {2,7} {3,7} {4,7} {5,7}'
                Write-Host ($TableRowPattern -f 'Action', 'Success', 'Failure', 'Skipped', 'Warning', 'Total')
                Write-Host ($TableRowPattern -f '------', '-------', '-------', '-------', '-------', '-----')
                foreach ($row in $CycleSummary.ActionStatistics) {
                    Write-Host ($TableRowPattern -f $row.Action, $row.Success, $row.Failure, $row.Skipped, $row.Warning, ($row.Success + $row.Failure + $row.Skipped + $row.Warning))
                }
                Write-Host ('')
            }
        }
    }
}
