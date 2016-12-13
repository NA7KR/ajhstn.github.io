$xmlquery = @'
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[(EventID=4776) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
  </Query>
</QueryList>
'@

$domain = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain()
$dcs = ($domain.DomainControllers).Name

$events = foreach ($dc in $dcs) {
    Get-WinEvent -ComputerName $dc -ErrorAction:SilentlyContinue -FilterXml $xmlquery
}

if ([bool]$events) {

$report = foreach($event in $events)
{
    if ($event.Properties -ne $null -and $event.Properties[3].Value -ne '0xC0000064')
    {
        $errorcodes = @{
            'c000005E' = 'NO_LOGON_SERVERS'
            'c0000022' = 'ACCESS_DENIED'
            '00000005' = 'ACCESS_DENIED'
            #'c0000064' = 'NO_SUCH_USER'
            'c000018A' = 'NO_TRUST_LSA_SECRET'
            'c000006D' = 'LOGON_FAILURE'
            'c000009A' = 'INSUFFICIENT_RESOURCES'
            'c0020050' = 'RPC_NT_CALL_CANCELLED'
            'c0000017' = 'NO_MEMORY'
            'c000006E' = 'ACCOUNT_RESTRICTION'
            'c000006C' = 'PASSWORD_RESTRICTION'
            'c0000070' = 'INVALID_WORKSTATION'
            'c000006A' = 'WRONG_PASSWORD'
            'c0000193' = 'ACCOUNT_EXPIRED'
            'c0000192' = 'NETLOGON_NOT_STARTED'
            'c0000071' = 'PASSWORD_EXPIRED'
            'c000006F' = 'INVALID_LOGON_HOURS'
            'c0000234' = 'ACCOUNT_LOCKED_OUT'
            'c0000072' = 'ACCOUNT_DISABLED'
            'c00000DC' = 'INVALID_SERVER_STATE'
            'c0000224' = 'PASSWORD_MUST_CHANGE'
        }
        $hexerror = $event.properties[3].Value
        $decerror = '{0:x}' -f $hexerror
        $verror = "none"
        foreach ($code in $errorcodes.GetEnumerator()){
            if ($decerror -match $code.Name) {
                $verror = $code.Value
            }
        }
		[PSCustomObject]@{
            MachineName=$event.MachineName
            TimeCreated=(Get-Date $event.TimeCreated -Format "dd-MMM-yyyy hh:mm:ss")
			Credential=$event.properties[1].value
            Source=$event.properties[2].value
            Error=$verror
		}
    }
}
$report

$html =@'
<!DOCTYPE html>
<head>
<meta name="viewport" content="width=device-width" />


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
This reports credential validation failures with reason codes.
#summary
#body
<br />
View this report in your browser. <a href=file:///\\hil-srv-dc1\c$\auditreports\#file>\\hil-srv-dc1\c$\auditreports\#file</a>
</body>
'@

$subject = "Credential Validation"
$date = (Get-Date -Format "yyyy-MM-dd")
$handle = $subject -replace '\s'
$file = $date + "-" + $handle +".html"
$computers = $report | Where-Object {($_.credential).endswith('$')}
$users = $report | Where-Object {-not ($_.credential).endswith('$')}
$summary = $report | Group-Object Error,MachineName | Sort-Object Count -Descending | Select-Object Name,Count | ConvertTo-Html -Fragment -PreContent "<h1>Summary</h1>"
$body = $users | ConvertTo-Html -Fragment -PreContent "<h1>Users</h1>"
$body += $computers | ConvertTo-Html -Fragment -PreContent "<h1>Computers</h1>"
$html = $html.Replace('#summary', $summary)
$html = $html.Replace('#body', $body)
$html = $html.Replace('#file', $file)

}