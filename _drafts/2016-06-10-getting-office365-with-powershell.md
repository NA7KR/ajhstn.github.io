---
layout: post
title: Connecting to Office365 with PowerShell
comments: true
---

In this post i will show you how to connect your PowerShell session to Office365.

First you need to install the PS module and bits onto your machine, quoted directly from Microsoft, so click the links below and install the Sign-In Assistant and then the Azure Active Directory Module for PowerShell.

>Install the Azure AD Module
The Azure AD Module is supported on the following Windows operating systems with the default version of Microsoft .NET Framework and Windows PowerShell: Windows 8.1, Windows 8, Windows 7, Windows Server 2012 R2, Windows Server 2012, or Windows Server 2008 R2.
First install the [Microsoft Online Services Sign-In Assistant for IT Professionals RTW] from the Microsoft Download Center. Then install the [Azure Active Directory Module for Windows PowerShell (64-bit version)], and click Run to run the installer package.

[Microsoft Online Services Sign-In Assistant for IT Professionals RTW]: http://go.microsoft.com/fwlink/?LinkID=286152
[Azure Active Directory Module for Windows PowerShell (64-bit version)]: http://go.microsoft.com/fwlink/p/?linkid=236297

What we will do to make your connecting a smooth and easy process each time is make use of your PowerShell profile.  We will add a function into your profile that you can **_call_** anytime and connect.  Your profile is a configuration 

Click/open/start PowerShell on your client machine, and type `notepad $Profile`.  This will open your PowerShell profile in Notepad.

````Powershell
$credential = Import-Clixml 'c:\path\to\o365creds.xml'

<#
.Synopsis
  Connects to O365 Quickly
.Description
  Connects to MSOnline and Exchange Online
#>
Function Get-Office365
{
write-verbose "Connecting to O365.." -v
Import-Module MsOnline
Connect-MsolService -Credential $credential
write-verbose "Connecting to Exchange Online.." -v
$exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
Import-PSSession $exchangeSession -DisableNameChecking
$Host.UI.RawUI.WindowTitle = "Connected to O365 and EO.."
}
````