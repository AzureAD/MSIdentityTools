<#
.SYNOPSIS
    Generate Random password for user in Azure AD.
.EXAMPLE
    PS C:\>New-MSIDTemporaryUserPassword
    Generates a new password.
#>
function New-MSIDTemporaryUserPassword {
    [CmdletBinding()]
    [OutputType([securestring])]
    param ()

    [char[]] $Consonants = 'bcdfghjklmnpqrstvwxyz'
    [char[]] $Vowels = 'aou'
    [securestring] $Password = ConvertTo-SecureString ('{0}{1}{2}{3}{4}' -f (Get-Random -InputObject $Consonants).ToString().ToUpper(),(Get-Random -InputObject $Vowels),(Get-Random -InputObject $Consonants),(Get-Random -InputObject $Vowels),(Get-Random -Minimum 1000 -Maximum 9999)) -AsPlainText -Force
    return $Password
}
