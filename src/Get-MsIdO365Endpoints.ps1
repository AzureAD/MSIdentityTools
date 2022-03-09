<#
.SYNOPSIS
    Get list of URLs and IP ranges for O365
    
.DESCRIPTION
    http://aka.ms/ipurlws

.EXAMPLE
    PS > Get-MsIdO365Endpoints

    Get list of URLs and IP ranges for O365 Worldwide cloud.

.EXAMPLE
    PS > Get-MsIdO365Endpoints -Cloud China -ServiceAreas Exchange,SharePoint

    Get list of URLs and IP ranges for Exchange and SharePoint in O365 China Cloud.

.EXAMPLE
    PS > Get-MsIdO365Endpoints -Cloud Worldwide -ServiceAreas Common | Where-Object id -In 54,56,59,96

    Get list of URLs and IP ranges related to Azure Active Directory.

.INPUTS
    System.String

#>
function Get-MsIdO365Endpoints {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        # Name of O365 Cloud. Valid values are: 'Worldwide','USGovGCCHigh','USGovDoD','Germany','China'
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('Worldwide', 'USGovGCCHigh', 'USGovDoD', 'Germany', 'China')]
        [string] $Cloud = 'Worldwide',
        # Office 365 tenant name.
        [Parameter(Mandatory = $false)]
        [string] $TenantName,
        # Exclude IPv6 addresses from the output
        [Parameter(Mandatory = $false)]
        [switch] $NoIPv6,
        # Name of Service Area.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Common', 'Exchange', 'SharePoint', 'Skype')]
        [string[]] $ServiceAreas,
        # Client Request Id.
        [Parameter(Mandatory = $false)]
        [guid] $ClientRequestId = (New-Guid)
    )

    [hashtable] $EndpointsParameters = @{
        clientrequestid = $ClientRequestId
    }
    if ($TenantName) { $EndpointsParameters.Add('TenantName', $TenantName) }
    if ($NoIPv6) { $EndpointsParameters.Add('NoIPv6', $NoIPv6) }
    if ($ServiceAreas) { $EndpointsParameters.Add('ServiceAreas', ($ServiceAreas -join ',')) }

    [System.UriBuilder] $O365EndpointsUri = 'https://endpoints.office.com/endpoints/{0}' -f $Cloud
    $O365EndpointsUri.Query = ConvertTo-QueryString $EndpointsParameters

    $O365Endpoints = Invoke-RestMethod -UseBasicParsing -Uri $O365EndpointsUri.Uri -ErrorAction Stop
    return $O365Endpoints
}
