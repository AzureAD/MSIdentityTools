<#
.SYNOPSIS
    Convert Azure AD connector space object Distinguished Name (DN) in AAD Connect

.EXAMPLE
    PS > ConvertFrom-MsIdAadcAadConnectorSpaceDn 'CN={414141414141414141414141414141414141414141413D3D}'

    Convert Azure AD connector space object DN in AAD Connect to sourceAnchor and sourceGuid.

.EXAMPLE
    PS > 'CN={4F626A656374547970655F30303030303030302D303030302D303030302D303030302D303030303030303030303030}' | ConvertFrom-MsIdAadcAadConnectorSpaceDn
    
    Convert Azure AD connector space object DN in AAD Connect to cloudAnchor and cloudGuid.

.INPUTS
    System.String
    
#>
function ConvertFrom-MsIdAadcAadConnectorSpaceDn {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        # Azure AD Connector Space DN from AAD Connect
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string] $InputObject
    )

    ## Extract Hex String
    if ($InputObject -imatch '(?:CN=)?\{?([0-9a-f]+)\}?') {
        [string] $HexString = $Matches[1]
    }
    else {
        [string] $HexString = $InputObject
    }

    ## Decode Hex String
    [string] $DecodedString = ConvertFrom-HexString $HexString
    if ($DecodedString -imatch '([a-z]+)_([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
        [guid] $CloudGuid = $Matches[2]
        $Result = [PSCustomObject]@{
            cloudAnchor = $DecodedString
            cloudGuid   = $CloudGuid
        }
    }
    else {
        [guid] $SourceGuid = ConvertFrom-Base64String $DecodedString -RawBytes
        $Result = [PSCustomObject]@{
            sourceAnchor = $DecodedString
            sourceGuid   = $SourceGuid
        }
    }

    return $Result
}
