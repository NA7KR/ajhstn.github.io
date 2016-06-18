---
layout: post
title: Add windows printers with PowerShell from CSV
---
Some days ago I wrote an article and built up a print server that was not domain bound and open for anonymous printing.  
<div class="alert alert-warning" role="alert"><strong>Warning!</strong> This should not necessarily be a standard practice, however it was my requirement for a short temporary offsite event.</div>

In this post I will go through the steps in adding printers to the server, configuring and sharing them.  These steps could be for a single printer or many thousand, the same process applies.

Knowing I had many printers to add, I wanted to automate this process, so I turned to PowerShell and searched for commands or functions containing the word 'print', like so `Get-Command *print*`.  This returned me a few commands that sounded like what I wanted, namely `Add-Printer`.

So off to research this command to learn how to use it. Either google it, run `help add-printer`, which will give you help within your PS console, or `help add-printer -online`, which will launch the same help information, but in your browser directly from Technet.

I used the help provided by powershell and from a quick read of the synopsis, it sounds like exactly what i need to use to add printers to my server.
```
SYNOPSIS
    Adds a printer to the specified computer.
```
Taking a look at the examples given at the bottom of my console, i can see that Name, DriverName and PortName properties are used to issue the command.

I have a a CSV file with printer information including the name and model, but i dont know exactly what the drive name is, so i need to find that out.

I remember in the list of available commands that i searched for earlier, one of them was `Get-PrinterDriver`.  So i run this command, and as expected, it returned a list of driver names that were currently installed on this system.

Now i know that i can come back to this command after i have my drives installed.

I knew i had 3 different models, requiring 3 different drivers. So i went to the drivers download pages for each of these models and downloaded the drivers i needed, and added them to the print server.

Then i run the command `Get-PrinterDriver` again and there are the driver names for me to use.

I am now ready to write some code, so the next thing i did was get my PowerShell ISE ready.

As a test i entered `Add-Printer -Name '{name}' -DriverName '{drivername}' -PortName '{portname}'`, but meh, i got errors.
`Add-Printer : The specified port does not exist.  Use add-printerport to add a new port, or specify an existing port.`

Sounds like i need to add a port first using the `add-printerport` command.  Ok then, another quick read through the help for this new command and now i try another test, this time to add a printerport, with this command `Add-PrinterPort -Name 'dummy' -PrinterHostAddress '0.0.0.0.'`
This worked, great.  Here i am adding a printer port with a fake name and invalid printer IP address.  Now that i know how to use this command, i can go back and test my `add-printer` command and this time give it the port name that i just created, namely `dummy`.  Ok great, this works.  Now i can add a port, then add a printer attached to that port.

I have about 50 printers, and i don't want to run the above two commands 50 times each, changing names and details each time round.  I get my list of printers and all required printer information into a csv, with the following column headers.

In this example I will use a csv file containing my printer details. Prepare yourself a csv file with headers [printername,ipaddress,driver,department,location], and save it to your computer `c:\path\to\file.csv`.  You can now run the below code to create our printer ports, then create our printers.

~~~powershell
$csv = Import-Csv c:\path\to\file.csv
$csv | ForEach-Object {
  #Add-PrinterPort -Name $_.printername -PrinterHostAddress $_.ipaddress
  #Add-Printer -Name $_.PrinterName -DriverName $_.driver -PortName $_.printername -Comment $_.department  -Location $_.location -Shared -ShareName $_.printername
}
~~~

Once the printers are added, i opened the properties on one of them and immediately see that it's great for our American friends who use the default paper size of letter but for us in Australia we need to configure each printer to use A4.

Looking back at the commands available to use i saw one called `Set-PrintConfiguration`. This sounds like a good start. Again i briefly open and read the help article, scroll to bottom, boom! There is an example where they are setting the papers size to A4

Copy paste `Set-PrintConfiguration -PrinterName $_.printername -PaperSize A4` back into our for each loop. Comment out the `Add-PrinterPort` and `Add-Printer` command because we don't want to execute these again.  Run the loop again, check printer properties, great, it worked.

Now the last step for my requirement was to add the "anonymous" user principal with print permission to each printer.

More research took me to the never failing [Scripting Guy!](https://blogs.technet.microsoft.com/heyscriptingguy/2014/08/10/weekend-scripter-add-security-groups-to-print-servers-by-using-powershell/) blog.  Here he shows that you need to copy the security permissions from one printer first, and then you can apply it to the rest of them.

So go to one printer, right click, properties, security, add anonymous, click OK, done.

Copy the code below, update "printer-x" with your printer name.

~~~powershell
$perms = Get-Printer -Name "printer-x" -Full
$csv | ForEach-Object {
  Set-Printer -Name $_.printername -PermissionSDDL $perms.PermissionSDDL
}
~~~

Run this, great, it worked!

That is it, now you can share your \\printserver out for clients to connect to.  There is a plethora of ways to do this and connect to shared printers so I won't go any further with that here.
