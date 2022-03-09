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

                [array] $AllServiceTagsAndRegions = Get-MSIDAzureIpRange -Cloud $Cloud -AllServiceTagsAndRegions -Verbose:$false
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

                [array] $AllServiceTagsAndRegions = Get-MSIDAzureIpRange -Cloud $Cloud -AllServiceTagsAndRegions -Verbose:$false
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
        [switch] $AllServiceTagsAndRegions
    )

    [hashtable] $MdcIdCloudMapping = @{
        Public     = 56519
        Government = 57063
        Germany    = 57064
        China      = 57062
    }

    [uri] $MdcUri = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id={0}' -f $MdcIdCloudMapping[$Cloud]
    [uri] $MdcDirectUri = $null  # Example: https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/ServiceTags_Public_20191111.json

    $MdcResponse = Invoke-WebRequest -UseBasicParsing -Uri $MdcUri
    if ($MdcResponse -match 'https://download\.microsoft\.com/download/.+?/ServiceTags_.+?_[0-9]{6,8}\.json') {
        $MdcDirectUri = $Matches[0]
    }

    if ($MdcDirectUri) {
        $AzureIPs = Invoke-RestMethod -UseBasicParsing -Uri $MdcDirectUri -ErrorAction Stop
    }

    if ($AllServiceTagsAndRegions) {
        return $AzureIPs
    }
    else {
        [string] $Id = 'AzureCloud'
        if ($ServiceTag) {
            $Id = $ServiceTag
        }
        if ($Region) {
            $Id += '.{0}' -f $Region
        }

        $OutputIPs = $AzureIPs.values | Where-Object id -EQ $Id
        if ($OutputIPs) {
            return $OutputIPs.properties.addressPrefixes
        }
    }
}
