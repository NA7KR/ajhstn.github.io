﻿$xmlquery = @'
<QueryList>
<Query Id="0" Path="Security">
<Select Path="Security">*[System[Provider[@Name='Microsoft-Windows-Security-Auditing'] and (EventID=4727 or EventID=4728 or EventID=4729 or EventID=4730 or EventID=4731 or EventID=4732 or EventID=4733 or EventID=4734 or EventID=4735 or EventID=4737 or EventID=4754 or EventID=4755 or EventID=4756 or EventID=4757 or EventID=4758 or EventID=4764) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
</Query>
</QueryList>
'@

$domain = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain()
$dcs = ($domain.DomainControllers).Name

$events = foreach ($dc in $dcs) {
Get-WinEvent -ComputerName $dc -ErrorAction:SilentlyContinue -FilterXml $xmlquery -MaxEvents 10
}

if ([bool]$events) {

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
$report

$html =@'
<!DOCTYPE html>
 <head>
 <meta name="viewport" content="width=device-width, initial-scale=1">
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

$subject = "Security Group Auditing"
$date = (Get-Date -Format "yyyy-MM-dd")
$handle = $subject -replace '\s'
$file = $date + "-" + $handle +".html"
$summary = $report | Group-Object EventName | Sort-Object Count -Descending | Select-Object Name,Count | ConvertTo-Html -Fragment -PreContent "<h1>Summary</h1>"
$body = $report | ConvertTo-Html -Fragment -PreContent "<h1>Details</h1>"
$html = $html.Replace('#summary', $summary)
$html = $html.Replace('#body', $body)
$html = $html.Replace('#file', $file)


Send-MailMessage -SmtpServer 'smtp.domain.com' -From 'Security Auditing <no-reply@domain.com>' -to 'securityauditing@domain.com' -Subject $subject -BodyAsHtml -Body $html

}
