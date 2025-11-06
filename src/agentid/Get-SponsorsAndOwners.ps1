<#
.SYNOPSIS
Internal function to prompt for and validate sponsors and owners

.DESCRIPTION
Prompts the user for sponsor and owner information when not provided,
ensuring at least one sponsor or owner is specified

.PARAMETER SponsorUserIds
Array of user IDs to set as sponsors

.PARAMETER SponsorGroupIds
Array of group IDs to set as sponsors

.PARAMETER OwnerUserIds
Array of user IDs to set as owners

.OUTPUTS
Hashtable with SponsorUserIds, SponsorGroupIds, and OwnerUserIds arrays
#>
function Get-SponsorsAndOwners {
    [CmdletBinding()]
    param (
        [string[]]$SponsorUserIds,
        [string[]]$SponsorGroupIds,
        [string[]]$OwnerUserIds
    )

    # Check if at least one owner or sponsor is provided, if not prompt for them
    $hasSponsorsOrOwners = (($SponsorUserIds -and $SponsorUserIds.Count -gt 0) -or
        ($SponsorGroupIds -and $SponsorGroupIds.Count -gt 0) -or
        ($OwnerUserIds -and $OwnerUserIds.Count -gt 0))

    if (-not $hasSponsorsOrOwners) {
        # Prompt for sponsor users
        $sponsorUserInput = Read-Host "Enter sponsor user IDs (comma-separated, or press Enter to skip)"
        if ($sponsorUserInput -and $sponsorUserInput.Trim() -ne "") {
            $SponsorUserIds = $sponsorUserInput.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        }

        # Prompt for sponsor groups
        $sponsorGroupInput = Read-Host "Enter sponsor group IDs (comma-separated, or press Enter to skip)"
        if ($sponsorGroupInput -and $sponsorGroupInput.Trim() -ne "") {
            $SponsorGroupIds = $sponsorGroupInput.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        }

        # Prompt for owner users if no sponsors provided
        if ((-not $SponsorUserIds -or $SponsorUserIds.Count -eq 0) -and
            (-not $SponsorGroupIds -or $SponsorGroupIds.Count -eq 0)) {
            do {
                $ownerUserInput = Read-Host "Enter owner user IDs (comma-separated, required since no sponsors provided)"
                if ($ownerUserInput -and $ownerUserInput.Trim() -ne "") {
                    $OwnerUserIds = $ownerUserInput.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
                }
            } while (-not $OwnerUserIds -or $OwnerUserIds.Count -eq 0)
        }
        else {
            # Optional owners if sponsors are already provided
            $ownerUserInput = Read-Host "Enter owner user IDs (comma-separated, or press Enter to skip)"
            if ($ownerUserInput -and $ownerUserInput.Trim() -ne "") {
                $OwnerUserIds = $ownerUserInput.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
            }
        }
    }

    return @{
        SponsorUserIds  = $SponsorUserIds
        SponsorGroupIds = $SponsorGroupIds
        OwnerUserIds    = $OwnerUserIds
    }
}
