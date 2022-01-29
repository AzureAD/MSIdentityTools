<#
.SYNOPSIS
    Convert/Decrypt SecureString to Plain Text String.
.DESCRIPTION

.EXAMPLE
    PS C:\>ConvertFrom-SecureStringAsPlainText (ConvertTo-SecureString 'SuperSecretString' -AsPlainText -Force) -Force
    Convert plain text to SecureString and then convert it back.
.INPUTS
    System.Security.SecureString
.LINK
    https://github.com/jasoth/Utility.PS
#>
function ConvertFrom-SecureStringAsPlainText {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # Secure String Value
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [securestring] $SecureString,
        # Confirms that you understand the implications of using the AsPlainText parameter and still want to use it.
        [Parameter(Mandatory = $false)]
        [switch] $Force
    )

    begin {
        if ($PSVersionTable.PSVersion -ge [version]'7.0') {
            Write-Warning 'PowerShell 7 introduced an AsPlainText parameter to the ConvertFrom-SecureString cmdlet.'
        }
        if (!${Force}) {
            ## Terminating Error
            $Exception = New-Object ArgumentException -ArgumentList 'The system cannot protect plain text output. To suppress this warning and convert a SecureString to plain text, reissue the command specifying the Force parameter.'
            Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::InvalidArgument) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'ConvertSecureStringFailureForceRequired' -TargetObject ${SecureString} -ErrorAction Stop
        }
    }

    process {
        try {
            [IntPtr] $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            Write-Output ([System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR))
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }
}
