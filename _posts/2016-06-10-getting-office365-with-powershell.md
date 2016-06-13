---
layout: post
title: Connecting to Office365 with PowerShell
comments: true
categories: o365
---

In this post i will show you how to connect your PowerShell session to Office365 and Exchange Online.

First you need to install the PS module and bits onto your machine, so click the links below and install the Sign-In Assistant and then the Azure Active Directory Module for PowerShell.  Check the quote below for your OS support.

>The Azure AD Module is supported on the following Windows operating systems with the default version of Microsoft .NET Framework and Windows PowerShell: Windows 8.1, Windows 8, Windows 7, Windows Server 2012 R2, Windows Server 2012, or Windows Server 2008 R2.
First install the [Microsoft Online Services Sign-In Assistant for IT Professionals RTW] from the Microsoft Download Center. Then install the [Azure Active Directory Module for Windows PowerShell (64-bit version)], and click Run to run the installer package.

[Microsoft Online Services Sign-In Assistant for IT Professionals RTW]: http://go.microsoft.com/fwlink/?LinkID=286152
[Azure Active Directory Module for Windows PowerShell (64-bit version)]: http://go.microsoft.com/fwlink/p/?linkid=236297

To make your connecting a smooth and easy process each time, we will make use of your PowerShell profile.  We will add a function into your profile that you can **_call_** anytime and connect.  Your profile is a configuration file that loads into your session each time you start powershell.

First we will get your O365 credentials, encrypt them and save them to disk.
<div class="alert alert-danger" role="alert">Yeah sure, because we are saving your credentials to disk, there is an element of risk, however they cannot be decrypted from anywhere else except the machine and disk they were created on.  Be sensible of course, but don't sweat too much.</div>

Start PowerShell on your client machine, and type `Get-Credential name@domain.com | Export-Clixml -Path C:\path\to\o365creds.xml`.

Note: Replace name@domain.com with your O365 admin credentials.

Note: Your tenant admin must assign you PowerShell permissions prior to connecting.

Now that your credentials are encrypted into o365creds.xml, lets prepare our `$Profile`.

In your PowerShell console type `notepad $Profile`.  This will either load your existing PowerShell profile, or start Notepad with a blank empty file.

Copy/Paste the code below into your notepad/profile file and save it to its default location.  Replace `'C:\path\to\o365creds.xml'` in the top line with the file path to your credentials that we created in the step above.

```powershell
$credential = Import-Clixml 'C:\path\to\o365creds.xml'

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
```
Now type `. $Profile` and hit enter.  This will reload your $profile into your session, which now includes the code above.  Alternatively, close and re-open PowerShell, which will load powershell again, and by doing so will load your $profile again.

Now the `Function` named `Get-Office365` is ready to use in our session, we can call it at any time and it will run the code, which will connect us to Office365 and Exchange Online.

Let go ahead and do that right now, run `Get-Office365` and you should start to see some verbose output `Connecting to O365..`  It will take 10 seconds or so to finish importing the Exchange cmdlets, but it will give you a progress bar while you wait so you know what is happening.

Enjoy!
