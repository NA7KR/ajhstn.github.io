---
layout: posts
title: "Security Group Auditing"
date: 2016-05-22
---

In this script we will query all of our domain controllers for security events in the security log.

## Prerequisites
* You need permissions to do PowerShell remoting, and query your domain controller event logs.
* You need to turn on appropriate event log autditing for your domain controllers.
* If you want to send the output through email, you also need an smtp server.

## Script Output
This script produces an HTML email.

![screen shot of resulting email](../../../img/gsga-small.png)

## The Code
This first block is the XML query used to run against the eventlog.  This type of XML query can easily be created in the Windows EventViewer, by creating a custom view, then switching to the XML Tab, and copy the code. 

```
$xmlquery = <QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[Provider[@Name='Microsoft-Windows-Security-Auditing'] and (EventID=4727 or EventID=4728 or EventID=4729 or EventID=4730 or EventID=4731 or EventID=4732 or EventID=4733 or EventID=4734 or EventID=4735 or EventID=4737 or EventID=4754 or EventID=4755 or EventID=4756 or EventID=4757 or EventID=4758 or EventID=4764) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
  </Query>
</QueryList>
```

This stores all of our domain controllers in $dcs

```powershell
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain()
$dcs = ($domain.DomainControllers).Name
```

This loops throuh each domain controller, and stores all matching events in $events

```powershell
$events = foreach ($dc in $dcs) {
    Get-WinEvent -ComputerName $dc -ErrorAction:SilentlyContinue -FilterXml $xmlquery
}
```

This loops through the events and extracts out the details we want to collect, namely what happened, by who, when and where, and builds a PSCustomObject.

```powershell
$report = foreach($event in $events)
{
    if ($event.Properties -ne $null)
    {
        switch($event.Id)
        {
            4727{$eventName = 'A security-enabled global group was created'}
            4728{$eventName = 'A member was added to a security-enabled global group'}
            4729{$eventName = 'A member was removed from a security-enabled global group'}
            4730{$eventName = 'A security-enabled global group was deleted'}
            4731{$eventName = 'A security-enabled local group was created'}
            4732{$eventName = 'A member was added to a security-enabled local group'}
            4733{$eventName = 'A member was removed from a security-enabled local group'}
            4734{$eventName = 'A security-enabled local group was deleted'}
            4735{$eventName = 'A security-enabled local group was changed'}
            4737{$eventName = 'A security-enabled global group was changed'}
            4754{$eventName = 'A security-enabled universal group was created'}
            4755{$eventName = 'A security-enabled universal group was changed'}
            4756{$eventName = 'A member was added to a security-enabled universal group'}
            4757{$eventName = 'A member was removed from a security-enabled universal group'}
            4758{$eventName = 'A security-enabled universal group was deleted'}
            4764{$eventName = 'A group''s type was changed'}

        }
		[PSCustomObject]@{
            EventName=$eventName
            EventID=$event.Id
            TimeCreated=(Get-Date $event.TimeCreated -Format "dd-MMM-yyyy hh:mm:ss")
			AdminName=if($event.id -in (4758,4731,4735,4737,4755)){$event.Properties[4].Value} else {$event.Properties[6].Value}
			MemberName=if($event.id -in (4731,4735,4737,4758,4755)){'-'} else {$event.Properties[0].Value}
            GroupName=if($event.id -in (4731,4735,4737,4758,4755)){$event.Properties[0].Value} else {$event.Properties[2].Value}
		}
    }
}
```
At this point we have the full report saved in the $report variable.  This could easily be output to the screen if you so desire.  Because it is a PSObject you can also futher filter, sort, select etc.

If you want to continue and produce an HTML email lets go.

This sets up a basic mobile friendly html email skeleton.

```powershell
$html = @'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> <html
xmlns="http://www.w3.org/1999/xhtml"> <head> <meta name="viewport"
content="width=device-width" />

<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<style type='text/css'>
table {
    border-collapse: collapse;
    border-spacing: 0;
    border: 1px solid #bbb;
		width: 100%;

}
td,th {
	text-align: left;
    border-top: 1px solid #ddd;
    padding: 4px 8px;
}
tbody tr:nth-child(even)  td { background-color: #eee; }

@media screen and (max-width: 640px) {
	table {
		overflow-x: auto;
		display: block;
	}
}

</style>
</head>
<body>
This reports changes made to security groups.
#summary
#body
</body>
'@
```

Here we set some of the email configuration and parmeters.

```powershell
$subject = "Security Group Auditing"
$date = (Get-Date -Format "yyyy-MM-dd")
$handle = $subject -replace '\s'
$file = $date + "-" + $handle +".html"
$summary = $report | Group-Object EventName | Sort-Object Count -Descending | Select-Object Name,Count | ConvertTo-Html -Fragment -PreContent "<h1>Summary</h1>"
$body = $report | ConvertTo-Html -Fragment -PreContent "<h1>Details</h1>"
$html = $html.Replace('#summary', $summary)
$html = $html.Replace('#body', $body)
$html = $html.Replace('#file', $file)

# If you want to save this to a html file, uncomment below.
$html | Out-File c:\AuditReports\$file -Force
```

Here we sent the email with the html body we created above.

```powershell
Send-MailMessage -SmtpServer 'your mail server' -From 'Security Auditing <no-reply@domain.com>' -to 'securityauditing@domain.com' -Subject $subject -BodyAsHtml -Body $html
```

See the full <a href="https://github.com/ajhstn/ajhstn.github.io/blob/master/ps/Get-SecurityGroupAuditing.ps1">code</a> on GitHub.

