---
sidebar_position: 1
slug: /
title: Introduction

---

# MSIdentityTools

## Overview

[![PSGallery Version](https://img.shields.io/powershellgallery/v/MSIdentityTools.svg?style=flat&logo=powershell&label=PSGallery%20Version)](https://www.powershellgallery.com/packages/MSIdentityTools)
[![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/MSIdentityTools.svg?style=flat&logo=powershell&label=PSGallery%20Downloads)](https://www.powershellgallery.com/packages/MSIdentityTools)
[![PSGallery Platform](https://img.shields.io/powershellgallery/p/MSIdentityTools.svg?style=flat&logo=powershell&label=PSGallery%20Platform)](https://www.powershellgallery.com/packages/MSIdentityTools)
[![GitHub issues](https://img.shields.io/github/issues/AzureAD/MSIdentityTools)](https://github.com/AzureAD/MSIdentityTools/issues)

The Microsoft Identity Tools is an open-source PowerShell module built by the Microsoft Entra Customer Experience Engineering team and provides various tools for performing enhanced Identity administration activities. This module is built using [Microsoft Graph PowerShell](https://aka.ms/graphps).

## What is contained in the MSIdentityTools module?

A collection of commands that use the MS Graph SDK PowerShell module to simplify common tasks for administrators. See the [Command Reference](/commands) for a list of available commands.

## How do I install the module?

The module can be installed from the PowerShell gallery.

```powershell
Install-Module MSIdentityTools
```

MSIdentity Tools is also available in the [PowerShell Gallery](https://www.powershellgallery.com/packages/MSIdentityTools) or can be downloaded from the [releases](https://github.com/AzureAD/MSIdentityTools/releases) page on GitHub.

## Popular commands

A popular use of this module is to run a quick OAuth app audit of your tenant using the [Export-MsIdAppConsentGrantReport](/commands/Export-MsIdAppConsentGrantReport) command. This command help you identify any risky permissions that have been granted to applications in your tenant.

<iframe width="560" height="315" src="https://www.youtube.com/embed/vO0m5yE3dZA" title="Run a quick OAuth app audit of your tenant using this command and protect yourself" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

## Support

For issues, questions, and feature requests please review the guidance on the [Support](https://github.com/AzureAD/MSIdentityTools/blob/main/SUPPORT.md) page for this project for filing issues.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
