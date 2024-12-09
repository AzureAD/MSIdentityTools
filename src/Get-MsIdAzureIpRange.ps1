<#
.SYNOPSIS
    Get list of IP ranges for Azure

.EXAMPLE
    PS > Get-MsIdAzureIpRange -AllServiceTagsAndRegions

    Get list of IP ranges for Azure Public cloud catagorized by Service Tag and Region.

.EXAMPLE
    PS > Get-MsIdAzureIpRange -ServiceTag AzureActiveDirectory

    Get list of IP ranges for Azure Active Directory in Azure Public Cloud.

.EXAMPLE
    PS > Get-MsIdAzureIpRange -Region WestUS

    Get list of IP ranges for West US region of Azure Public Cloud.

.EXAMPLE
    PS > Get-MsIdAzureIpRange -Cloud China -Region ChinaEast -ServiceTag Storage

    Get list of IP ranges for Storage in ChinaEast region of Azure China Cloud.

.INPUTS
    System.String
    
#>
function Get-MsIdAzureIpRange {
    [CmdletBinding(DefaultParameterSetName = 'ById')]
    [OutputType([PSCustomObject], [string[]])]
    param(
        # Name of Azure Cloud. Valid values are: Public, Government, Germany, China
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('Public', 'Government', 'Germany', 'China')]
        [string] $Cloud = 'Public',

        # Name of Region. Use AllServiceTagsAndRegions parameter to see valid regions.
        [Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({
                param ( $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters )
                [string] $Cloud = 'Public'  # Default Cloud parameter value
                if ($fakeBoundParameters.ContainsKey('Cloud')) { $Cloud = $fakeBoundParameters.Cloud }
                [string] $ServiceTag = ''  # Default ServiceTag parameter value
                if ($fakeBoundParameters.ContainsKey('ServiceTag')) { $ServiceTag = $fakeBoundParameters.ServiceTag }

                #$StartPosition = $host.UI.RawUI.CursorPosition
                #Write-Host '...' -NoNewline

                [array] $AllServiceTagsAndRegions = Get-MsIdAzureIpRange -Cloud $Cloud -AllServiceTagsAndRegions -Verbose:$false
                #$AllServiceTagsAndRegions.values.properties.region | Select-Object -Unique | Where-Object { $_ }

                $listRegions = New-Object System.Collections.Generic.List[string]
                foreach ($Item in $AllServiceTagsAndRegions.values.name) {
                    if ($Item -like "$ServiceTag*.$wordToComplete*") {
                        $Region = $Item.Split('.')[1]
                        if (!$listRegions.Contains($Region)) { $listRegions.Add($Region) }
                    }
                }

                if ($listRegions) {
                    $listRegions #| ForEach-Object {$_}
                }

                #$host.UI.RawUI.CursorPosition = $StartPosition
                #Write-Host ('   ') -NoNewline
            })]
        [string] $Region,

        # Name of Service Tag. Use AllServiceTagsAndRegions parameter to see valid service tags.
        [Parameter(Mandatory = $false, Position = 3, ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({
                param ( $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters )
                [string] $Cloud = 'Public'  # Default Cloud parameter value
                if ($fakeBoundParameters.ContainsKey('Cloud')) { $Cloud = $fakeBoundParameters.Cloud }
                [string] $Region = ''  # Default Region parameter value
                if ($fakeBoundParameters.ContainsKey('Region')) { $Region = $fakeBoundParameters.Region }

                #Write-Host '...' -NoNewline
                [array] $AllServiceTagsAndRegions = Get-MsIdAzureIpRange -Cloud $Cloud -AllServiceTagsAndRegions -Verbose:$false
                #$AllServiceTagsAndRegions.values.properties.region | Select-Object -Unique | Where-Object { $_ }

                $listServiceTags = New-Object System.Collections.Generic.List[string]
                foreach ($Item in $AllServiceTagsAndRegions.values.name) {
                    if ($Item -like "$wordToComplete*?$Region*") {
                        $ServiceTag = $Item.Split('.')[0]
                        if (!$listServiceTags.Contains($ServiceTag)) { $listServiceTags.Add($ServiceTag) }
                    }
                }

                if ($listServiceTags) {
                    $listServiceTags #| ForEach-Object {$_}
                }
            })]
        [string] $ServiceTag,

        # List all IP ranges catagorized by Service Tag and Region.
        [Parameter(Mandatory = $false, ParameterSetName = 'AllServiceTagsAndRegions')]
        [switch] $AllServiceTagsAndRegions,

        # Bypass cache and download data again.
        [Parameter(Mandatory = $false)]
        [switch] $ForceRefresh
    )

    ## Get data cache
    if (!(Get-Variable cacheAzureIPRangesAndServiceTags -ErrorAction SilentlyContinue)) { New-Variable -Name cacheAzureIPRangesAndServiceTags -Scope Script -Value (New-Object hashtable) }

    ## Download data and update cache
    if ($ForceRefresh -or !$cacheAzureIPRangesAndServiceTags.ContainsKey($Cloud)) {
        Write-Verbose ('Downloading data for Cloud [{0}].' -f $Cloud)
        [hashtable] $MdcIdCloudMapping = @{
            Public     = 56519
            Government = 57063
            Germany    = 57064
            China      = 57062
        }

        [uri] $MdcUri = 'https://www.microsoft.com/en-us/download/details.aspx?id={0}' -f $MdcIdCloudMapping[$Cloud]
        [uri] $MdcDirectUri = $null  # Example: https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/ServiceTags_Public_20191111.json

        $MdcResponse = Invoke-WebRequest -UseBasicParsing -Uri $MdcUri
        if ($MdcResponse -match 'https://download\.microsoft\.com/download/.+?/ServiceTags_.+?_[0-9]{6,8}\.json') {
            $MdcDirectUri = $Matches[0]
        }

        if ($MdcDirectUri) {
            $cacheAzureIPRangesAndServiceTags[$Cloud] = Invoke-RestMethod -UseBasicParsing -Uri $MdcDirectUri -ErrorAction Stop
        }
    }
    else {
        Write-Verbose ('Using cached data for Cloud [{0}]. Use -ForceRefresh parameter to bypass cache.' -f $Cloud)
    }
    $AzureServiceTagsAndRegions = $cacheAzureIPRangesAndServiceTags[$Cloud]

    ## Return the data
    if ($AllServiceTagsAndRegions) {
        return $AzureServiceTagsAndRegions
    }
    else {
        [string] $Id = 'AzureCloud'
        if ($ServiceTag) {
            $Id = $ServiceTag
        }
        if ($Region) {
            $Id += '.{0}' -f $Region
        }

        $FilteredServiceTagsAndRegions = $AzureServiceTagsAndRegions.values | Where-Object id -EQ $Id
        if ($FilteredServiceTagsAndRegions) {
            return $FilteredServiceTagsAndRegions.properties.addressPrefixes
        }
    }
}
