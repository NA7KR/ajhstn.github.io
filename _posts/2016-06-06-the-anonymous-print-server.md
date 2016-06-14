---
layout: post
title:  "The Anonymous Print Server"
categories: print
---

We are hosting a conference offiste, and one of our requirements is to allow guest printing.  We hire in computers which need to be configured for easy printing, and we dont want to bind each machine to our domain.

In this post i will setup a Windows Server 2012 R2 Print Server to allow for this.

# Install OS
Firstly prepare your windows server and install your OS.  This can be a virtual or physical machine.
One thing here to note, you should choose an appropriate/easy name as it will be the endpoint your users use.  In my case the fqdn will be 'print.domain.com'.
# Install Print Services Role
Here we will install the print services roles and software we need to turn this machine into a print server.

Generally here i will start up PowerShell and run the command `Get-WindowsFeature *print*` to discover what roles and features exist in my server that i need to configure.  Below is the result from the above command.
<pre>
PS C:\Users\Administrator> Get-WindowsFeature *print*

Display Name                                            Name                       Install State
------------                                            ----                       -------------
[ ] Print and Document Services                         Print-Services                 Available
    [ ] Print Server                                    Print-Server                   Available
    [ ] Distributed Scan Server                         Print-Scan-Server              Available
    [ ] Internet Printing                               Print-Internet                 Available
    [ ] LPD Service                                     Print-LPD-Service              Available
[ ] Internet Printing Client                            Internet-Print-Client          Available
        [ ] Print and Document Services Tools           RSAT-Print-Services            Available
</pre>

This is cool because now i can clearly see the correct names of which roles i may need to install.
Now that i know the name of the role i will run command `Install-WindowsFeature print-services -IncludeManagementTools`.  This will install the necessary "print-services" roles and also the management tools.

Alternatively if you prefer using Server Manger, open that up, click through and select the **"Print and Document Services"** role, and finish the wizard off clicking OK as you go.

# Configure Security
We now have the print services installed and now we need to allow anonymous access to the server and printer shares.
<div class="alert alert-danger" role="alert"><strong>Warning!</strong> DO NOT DO any of the below configuration in your production, domain LAN.  We are opening up the attack surface right now.</div>
<div class="alert alert-danger" role="alert">Because of the anonymous permissions allowed here, please be diligent and install anti-virus protection software on this host to help protect you and your client machines.</div>

To allow anonymous access to the printer shares and the print services open up `secpol.msc` or the **"Local Security Policy"** from Server Manager.
Navigate to Security Settings -> Local Policies -> Security Options and configure these policies.

Accounts: Guest account status: <span class="label label-info">Enabled</span>
: https://technet.microsoft.com/en-us/library/cc787725(v=ws.10).aspx

Network access: Let Everyone permissions apply to anonymous users: <span class="label label-info">Enabled</span>
: https://technet.microsoft.com/en-us/library/cc778182(v=ws.10).aspx

Network access: Restrict anonymous access to Named Pipes and Shares: <span class="label label-info">Disabled</span>
: https://technet.microsoft.com/en-us/library/cc778473(v=ws.10).aspx

# Add your Printer/s
Add your printer as usual, share it, and in the printer Security Tab, add in both the **"ANONYMOUS LOGON"** and **"Guest"** accounts, and give them the print permission.

Thats is pretty much it, now begin testing!

From your client machine UNC over to `\\print\` and you should see your printer.  Also note, that you were not stopped, asked for credentials, no questions asked.  Right click the printer, choose connect and you are good to go.
