# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Style Guide for Contributions
# Cmdlet Format
When creating a cmdlet for inclusion please follow these guidelines.

## Structure
Create your cmdlet as an advanced function.

See `Get-Help about_Functions_Advanced`

## Verb
Please ensure that you are using an approved verb as per the guidelines in 
[Approved Verbs for PowerShell Commands](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.2)

## Noun Prefix
Please use this prefix for your cmdlet: **MsId** 

For example, `Get-MsIdUserDetails`

## Help
Please provide detailed coment based help and good parameter descriptions to help the end-user.

See `Get-Help about_Comment_Based_Help` 

## Parameters
Use advanced function parameters with validation (where feasible):

See `Get-Help about_Functions_Advanced_Parameters` 

# Cmdlet Status Feedback
Utilize `Write-Verbose` statements for providing optional feedback on the processing of the cmdlet during execution, for example:

`Write-Verbose -Message "$(Get-Date -f T) - <your_message>"`

If you've created your cmdlet as an advanced function it will already include a `[CmdletBinding()]` statement which enables `-Verbose`. 

See `Get-Help about_Functions_CmdletBindingAttribute` and `Get-Help about_Functions_Advanced_Methods`
