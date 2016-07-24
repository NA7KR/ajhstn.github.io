---
layout: post
title: Creating a PRTG Countdown Sensor
---
This sensor will return a simple digit counter of days remaining from the current date and a specified future date.

You may want to use this sensor as a countdown to an important date, eg conference, project deadline etc..

This sensor is a [EXE/Script](https://www.paessler.com/manuals/prtg/exe_script_sensor) PowerShell script sensor, and so we need to write a PowerShell script and save it to "\Custom Sensors\EXE\" in your PRTG installation folder.

Copy and Paste the script below to the location "\Custom Sensors\EXE\DaysUntil.ps1".  

<div class="alert alert-info" role="alert"><strong>Note!</strong> i called my script "DaysUntil.ps1" but you can call yours whatever you want.</div>

## PowerShell script
````powershell
# PRTG Days Until / Countdown

$givenDate = $args[0]
$today = Get-Date
$ts = $null

try
{
    # Try converting the given date to DateTime
    $ts = New-TimeSpan -Start (Get-Date) -End (Get-Date $givenDate)
}
Catch
{
    Write-Host "2:Bad date format"
    Exit 2;
}

if ($ts -gt 0) {
    Write-Host "$($ts.Days):Ok"
    Exit 0;
}
else {
    Write-Host "2:Date has allready passed"
    Exit 2;
}
````

Now in your PRTG web interface or chosen management tool, go to your appropriate device, and follow the steps below.

1. Add Sensor
1. Choose EXE/Script sensor
1. Sensor Name: Type a sensor name of your choice
1. EXE/Script: DaysUntil.ps1 (or whatever you called your script)
1. Parameters: The date you are counting from
1. Value Type: Integer

At this point we can Save this new sensor and wait a minute for it to run and return some results.

Here is a sample shot of it working, and you can see that i have 160 days before my date occurs.

![Days Until Sensor Screen Shot](img/prtg-daysuntil-160.PNG)

## limits
You may wish to enable limits on your sensor to alert you once you hit a certain threshold.

Eg, i have enabled a 14 day warning, so that when i have less than 14 days before i hit my date, prtg will begin to notify and warn me.

![Days Until Sensor Screen Shot](/img/prtg-daysuntil-belowlimits.png)

## Sensor output
If you enter a date in a bad format eg 32/01/2020 the script will write an error.

![Days Until Sensor Screen Shot](/img/prtg-daysuntil-badformat.jpg)

If you provide a date in the past, you will receive a warning.

![Days Until Sensor Days Passed](/img/prtg-daysuntil-dayspassed.jpg)

### One last thing
If you are wondering,  YES YOU CAN!!, you can write other scripts also, and create prtg graphs using PowerShell (and/or any other scripting language).  Literally, any values you can return from your scripts, can be put into PRTG and have gauges and graphs created from them.

If you need a hand with this, let me know, I'd be glad to help.
