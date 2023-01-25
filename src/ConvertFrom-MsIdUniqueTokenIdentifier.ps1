<#
.SYNOPSIS
    Convert Azure AD Unique Token Identifier to Request Id.
    
.EXAMPLE
    PS > ConvertFrom-MsIdUniqueTokenIdentifier 'AAAAAAAAAAAAAAAAAAAAAA'

    Convert Azure AD Unique Token Identifier to Request Id.

.EXAMPLE
    PS > Get-MgBetaAuditLogSignIn -Top 1 | ConvertFrom-MsIdUniqueTokenIdentifier

    Get a Sign-in Log Entry and Convert Azure AD Unique Token Identifier to Request Id.

.INPUTS
    System.String

#>
function ConvertFrom-MsIdUniqueTokenIdentifier {
    [CmdletBinding()]
    [OutputType([guid])]
    param (
        # Azure AD Unique Token Identifier
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateLength(22,22)]
        [Alias("UniqueTokenIdentifier")]
        [string] $InputObject
    )

    process {
        [guid] $SourceGuid = ConvertFrom-Base64String $InputObject -Base64Url -RawBytes
        return $SourceGuid
    }
}
