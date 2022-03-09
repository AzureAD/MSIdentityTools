<#
.SYNOPSIS
    Convert Azure AD Connect metaverse object sourceAnchor or Azure AD ImmutableId to sourceGuid.
    
.EXAMPLE
    PS > ConvertFrom-MsIdAadcSourceAnchor 'AAAAAAAAAAAAAAAAAAAAAA=='

    Convert Azure AD Connect metaverse object sourceAnchor base64 format to sourceGuid.

.EXAMPLE
    PS > ConvertFrom-MsIdAadcSourceAnchor '00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00'

    Convert Azure AD Connect metaverse object sourceAnchor hex format to sourceGuid.

.INPUTS
    System.String

#>
function ConvertFrom-MsIdAadcSourceAnchor {
    [CmdletBinding()]
    [Alias('ConvertFrom-MsIdAzureAdImmutableId')]
    [OutputType([guid], [string])]
    param (
        # Azure AD Connect metaverse object sourceAnchor.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string] $InputObject
    )

    if ($InputObject -imatch '(?:^|,)((?:[0-9a-f]{2} ?)+)(?:$|,)') {
        [guid] $SourceGuid = ConvertFrom-HexString $Matches[1].Trim() -RawBytes
    }
    elseif ($InputObject -imatch '(?:^|,)([0-9a-z+/=]+=+)(?:$|,)') {
        [guid] $SourceGuid = ConvertFrom-Base64String $Matches[1] -RawBytes
    }
    else {
        [guid] $SourceGuid = ConvertFrom-Base64String $InputObject -RawBytes
    }

    return $SourceGuid
}
