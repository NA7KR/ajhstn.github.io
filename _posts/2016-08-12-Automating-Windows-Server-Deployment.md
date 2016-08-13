---
layout: post
---
This post talks about automating the deployment of Hyper-V Guest Windows servers using PowerShell.  This is part1 of a two part series.

1. Preparing the base Windows Image (this post)
2. Deploying New Virtual Machines (coming soon)

If your in a large enterprise you may already use tools like SCCM or SCVMM, or any other plethora of deployment tools, but if not, then read along and maybe this could help you.  In fact this same method can be used with SCCM and Windows Deployment tools.

My workflow is across 2 phases.  In this post we will cover the first phase.

1. Preparing our base Windows Image (VHDX File)
  * Extracting the wim
  * Patching the wim
  * Converting it to VHDX
2. Creating our Virtual Machine
  * PowerShell script to create the VM

The PowerShell script has an option GUI front end.
![CloudBuilder GUI](img/cloudbuilder.PNG)

### Preparing the base Windows image (VHDX File)

#### Extract the wim
Get your windows server ISO, mount it, then copy the `d:\sources\install.wim` file to a working directory on your machine, where `d:\` is your drive mount.  I created a folder at `c:\build` as my working directory, and copied the wim file there. In Windows10, you can simply double click the ISO or use this command.
`Mount-DiskImage -ImagePath "path to ISO"`. Once you have copied, you may now dismount the ISO image.

#### Patching the wim
Every month Microsoft releases security updates and distributes them via ISO image.  You can download the latest file here
https://support.microsoft.com/en-au/kb/913086.

Using the same method above, mount this ISO image and copy the contents to a new folder in your working directory.  I created a folder and called it `c:\build\updates`. This ISO contains `*.msu` packages which can be applied to a wim file.

Now what we want to do is loop through the updates in the updates folder and inject them into our wim file.  We will use DISM to inject the updates, and to do that we need to first flatten the directory.  Before we flatten the directory it looks a little like this.

```dos
c:\Build\Updates>tree
Folder PATH listing
Volume serial number is A288-2B9FC:.
├───3122653
│   └───X86
│       └───NEU
├───3123055
│   └───Windows7
│       └───X86
│           └───NEU
├───3127223
│   └───Windows7
│       └───X86
│           └───NEU
```

We need it so that there is a single folder containing all our `*.msu` packages.

Before that though, head over to the MS script repository and get a copy of [Convert-WindowsImage](https://gallery.technet.microsoft.com/scriptcenter/Convert-WindowsImageps1-0fe23a8f).  This is an amazing tool for anyone that deals with modern techniques in windows deployments.  Download and save this script to  `C:\Build\Convert-WindowsImage.ps1`.

Now create yourself a new PowerShell script in our working directory, i called mine `Build-BaseImage.ps1`.  This is really just a few 1 line commands, but i want to install the new security updates each month into my wim file, i have decided to put the commands into a reusable script file.

At the top, begin your script by changing into your working directory.

`Set-Location C:\Build`

Now dot source the Convert-WindowsImage script.  This will load the functions in the script and make them available for us to use later.

`. .\Convert-WindowsImage.ps1`

Now loop through the updates folder and copy them to a flat directory.  I have included a filter to only include `*.msu` packages that are in 2012r2 folders, as that is the OS i am deploying.

`Get-ChildItem -Recurse .\Updates\* -Filter *.msu | Where-Object {$_.FullName -like "*2012r2*"} | Copy-Item -Destination .\MSUPackages`

Now we need to mount our wim file in offline serviceing mode, so that we can work on it. This will mount the install.wim with index 2, which is "server standard with gui", as aposed to index 1 which is "server standard core", file into a folder called offline.

`Dism /Mount-Image /ImageFile:C:\Build\install.wim /index:2 /MountDir:C:\Build\offline`

This adds the `*.msu` packages to the wim file.

`Dism /Image:C:\Build\offline /LogPath:AddPackage.log /Add-Package /PackagePath:C:\Build\MSUPackages`

This unmounts the wim file.

`Dism /Unmount-Image /MountDir:C:\Build\offline /commit`

This uses the Convert-WindowsImage function to convert our wim file and applies a unattend.xml file to preconfigure some Windows settings.  It will create a 96GB, Dynamically Expanding, GPT style VHDX file.

`Convert-WindowsImage -SourcePath .\install.wim -Edition 'serverstandard' -SizeBytes 96GB -VHDType Dynamic -VHDPartitionStyle GPT -UnattendPath .\unattend.xml -VHDPath .\base.vhdx -Verbose`

The unattend file is optional, you can omit this if you wish. The unnatend file is an xml file, that describes a set of windows settings and configurations, in an unnattended fashion.  You can view my unattend file [here](/ps/Unattend.xml).  You will need to customise your own file, but you can use this as a starting point.  You can use the unattend file to configure almost anything within Windows, so have a lot of fun with that, and i can help you if you need a hand.  I have only set a few settings, like Organisation and Owner name, TimeZone, and also some Firewall Rules to allow PSRemoting and WinRM connections.  The reason being is because after deployment, i generally want to install and configure Chef configuration management tool which connects over these protocols (WSMan).

At this point, after running the Convert-WindowsImage script, you will now have a serverstandard.vhdx file in your working directory.

This is a ready to go pristine, never been booted, Windows 2012 R2 template/base/what ever you wish to call it. You now simply copy this and use it to create Virtual Machines from.

The full script containing all the above code is [here](https://github.com/ajhstn/ajhstn.github.io/blob/master/ps/Build-BaseImage.ps1).

In the next part of this series we will be using the above vhdx file to automate the deployment of Hyper-V VM Servers.
