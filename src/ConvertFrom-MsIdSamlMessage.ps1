<#
.SYNOPSIS
    Convert SAML Message structure to PowerShell object.

.EXAMPLE
    PS > ConvertFrom-MsIdSamlMessage 'Base64String'

    Convert Saml Message to XML object.

.INPUTS
    System.String

.OUTPUTS
    SamlMessage : System.Xml.XmlDocument
    
#>
function ConvertFrom-MsIdSamlMessage {
    [CmdletBinding()]
    [Alias('ConvertFrom-MsIdSamlRequest')]
    [Alias('ConvertFrom-MsIdSamlResponse')]
    #[OutputType([xml])]
    param (
        # SAML Message
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]] $InputObject
    )

    process {
        foreach ($_InputObject in $InputObject) {
            ConvertFrom-SamlMessage $_InputObject
        }
    }
}
