<#
.SYNOPSIS
    Gets the form fields to login to AD FS server for the login URL and credentials.
.DESCRIPTION
.EXAMPLE
    PS C:\>New-AdfsLoginFormFields -Url $url -Credential $credential
    Gets the form fields for the variables.
#>
function New-AdfsLoginFormFields {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.Dictionary[string, string]])]
    param (
        # User credential
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [pscredential] $Credential
    )

    $user = $Credential.UserName
    $password = ConvertFrom-SecureStringAsPlainText $Credential.Password -Force

    $fields = New-Object -TypeName "System.Collections.Generic.Dictionary[string,string]"
    $fields.Add("UserName",$user)
    $fields.Add("Password",$password)
    $fields.Add("AuthMethod","FormsAuthentication")

    return $fields
}