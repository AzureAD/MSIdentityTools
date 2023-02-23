<#
.SYNOPSIS
    Return groups with an expiration date via lifecycle policy.
    
.EXAMPLE
    PS > Get-MsIdGroupsWithExpiration | Select-Object Id,DisplayName,ExpirationDateTime,RenewedDateTime

    Return all groups with an expiration date.

.EXAMPLE
    PS > Get-MsIdGroupsWithExpiration -After (Get-Date).AddDays(-30) -Before (Get-Date).AddDays(30) | Select-Object Id,DisplayName,ExpirationDateTime,RenewedDateTime

    Return all groups with an expiration date between 30 days before today and 30 days after today.

.EXAMPLE
    PS > Get-MsIdGroupsWithExpiration -Days 30 | Select-Object Id,DisplayName,ExpirationDateTime,RenewedDateTime

    Return all groups with an expiration date between now and 30 days from now.
    
.INPUTS
    None

#>
function Get-MsIdGroupsWithExpiration {
    [CmdletBinding(DefaultParameterSetName = 'DateTimeSpan')]
    param (
        # Numbers of days
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Days')]
        [int] $Days,
        # Start of DateTime range
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'DateTimeSpan')]
        [datetime] $After = [datetime]::MinValue,
        # End of DateTime range
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'DateTimeSpan')]
        [datetime] $Before = [datetime]::MaxValue
    )

    ## Initialize Critical Dependencies
    if (!(Test-MgCommandPrerequisites 'Get-MgGroup' -MinimumVersion 1.9.2 -ErrorVariable CriticalError)) { return }

    if ($PSCmdlet.ParameterSetName -eq 'Days') {
        [datetime] $After = Get-Date
        [datetime] $Before = $After.AddDays($Days)
    }

    ## Filter for groups with an expiration date
    Get-MgGroup -Filter "expirationDateTime ge $($After.ToUniversalTime().ToString('o')) and expirationDateTime le $($Before.ToUniversalTime().ToString('o'))" -All -CountVariable MgCount -ConsistencyLevel eventual | Sort-Object expirationDateTime
}
