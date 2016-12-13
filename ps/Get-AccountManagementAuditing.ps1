$xmlquery = @'
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[Provider[@Name='Microsoft-Windows-Security-Auditing'] and (EventID=4720 or EventID=4722 or EventID=4723 or EventID=4724 or EventID=4725 or EventID=4726 or EventID=4738 or EventID=4765 or EventID=4766 or EventID=4767 or EventID=4780 or EventID=4781) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
  </Query>
</QueryList>
'@

$domain = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain()
$dcs = ($domain.DomainControllers).Name

$events = foreach ($dc in $dcs) {
    Get-WinEvent -ComputerName $dc -ErrorAction:SilentlyContinue -FilterXml $xmlquery
}

if ([bool]$events) {

$report = foreach ($event in $events)
{
    if ($event.Properties -ne $null)
    {
        switch($event.Id)
        {
            4720{$eventName = 'A user account was created.'}
            4722{$eventName = 'A user account was enabled.'}
            4723{$eventName = 'An attempt was made to change an account''s password.'}
            4724{$eventName = 'An attempt was made to reset an account''s password.'}
            4725{$eventName = 'A user account was disabled.'}
            4726{$eventName = 'A user account was deleted.'}
            4738{$eventName = 'A user account was changed.'}
            4740{$eventName = 'A user account was locked out.'}
            4765{$eventName = 'SID History was added to an account.'}
            4766{$eventName = 'An attempt to add SID History to an account failed.'}
            4767{$eventName = 'A user account was unlocked.'}
            4780{$eventName = 'The ACL was set on accounts which are members of administrators groups.'}
            4781{$eventName = 'The name of an account was changed'}
            4794{$eventName = 'An attempt was made to set the Directory Services Restore Mode.'}
            5376{$eventName = 'Credential Manager credentials were backed up.'}
            5377{$eventName = 'Credential Manager credentials were restored from a backup.'}
        }
        $changes = @{}
        $var = $null
        if ($events.Id -eq 4738)
        {
            if ($event.Properties[9].Value -ne '-'){$changes.Add("SAMAccountName" , $event.Properties[9].Value)}
            if ($event.Properties[10].Value -ne '-'){$changes.Add("DisplayName", $event.Properties[10].Value)}
            if ($event.Properties[11].Value -ne '-'){$changes.Add("UPN", $event.Properties[11].Value)}
            if ($event.Properties[12].Value -ne '-'){$changes.Add("HomeDirectory", $event.Properties[12].Value)}
            if ($event.Properties[13].Value -ne '-'){$changes.Add("HomeDrive", $event.Properties[13].Value)}
            if ($event.Properties[14].Value -ne '-'){$changes.Add("ScriptPath", $event.Properties[14].Value)}
            if ($event.Properties[15].Value -ne '-'){$changes.Add("ProfilePath", $event.Properties[15].Value)}
            if ($event.Properties[16].Value -ne '-'){$changes.Add("UserWorkstations", $event.Properties[16].Value)}
            if ($event.Properties[17].Value -ne '-'){$changes.Add("PasswordLastSet", $event.Properties[17].Value)}
            if ($event.Properties[18].Value -ne '-'){$changes.Add("AccountExpires", $event.Properties[18].Value)}
            if ($event.Properties[19].Value -ne '-'){$changes.Add("PrimaryGroupID", $event.Properties[19].Value)}
            if ($event.Properties[20].Value -ne '-'){$changes.Add("OldUACValue", $event.Properties[20].Value)}
            if ($event.Properties[21].Value -ne '-'){$changes.Add("NewUACValue", $event.Properties[21].Value)}
            if ($event.Properties[22].Value -ne '-'){$changes.Add("UserAccountControl", $event.Properties[22].Value)}
            if ($event.Properties[23].Value -ne '-'){$changes.Add("UserParameters", $event.Properties[23].Value)}
            if ($event.Properties[24].Value -ne '-'){$changes.Add("SIDHistory", $event.Properties[24].Value)}
            if ($event.Properties[25].Value -ne '-'){$changes.Add("AllowedToDelegateTo", $event.Properties[25].Value)}
            if ($event.Properties[26].Value -ne '-'){$changes.Add("LogonHours", $event.Properties[26].Value)}
            #$properties = for ($i=9;$i-lt27;$i++){$event.Properties[$i].value | Where-Object {$_ -ne '-'}}
        }
        [PSCustomObject]@{
            EventName=$eventName
            EventID=$event.Id
            TimeCreated=(Get-Date $event.TimeCreated -Format "dd-MMM-yyyy hh:mm:ss")
			AdminName=if($event.id -eq 4738){$event.Properties[5].Value} else {$event.Properties[4].Value}
			TargetName=if($event.id -eq 4738){$event.Properties[1].Value} else {$event.Properties[0].Value}
            AttributeChanges=if($event.id -eq 4738){$var = foreach ($c in $changes.GetEnumerator()) {[string]::Format("({0}: {1}), ",$c.Name,$c.Value)};$var -join ''}else{"-"}
		}
    }
    
}

if ([bool]$report) {

# $report <-- Do whatever you want with the $report object, or convert it to HMTL below.


$html =@'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
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
This reports shows changes made to accounts.
#summary
#body
<br />
</body>
'@

$summary = $report | Group-Object EventName | Sort-Object Count -Descending | Select-Object Name,Count | ConvertTo-Html -Fragment -PreContent "<h1>Summary</h1>"
$body = $report | ConvertTo-Html -Fragment -PreContent "<h1>Details</h1>"
$html = $html.Replace('#summary', $summary)
$html = $html.Replace('#body', $body)
$html = $html.Replace('#file',$file)


}
}