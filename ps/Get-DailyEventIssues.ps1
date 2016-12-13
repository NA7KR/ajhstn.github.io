$domain = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain()
$dcs = ($domain.DomainControllers).Name

try {
    $events = Invoke-Command -ComputerName $dcs -ScriptBlock {
        Get-EventLog -LogName System -EntryType Error -Newest 10 -After (Get-Date).AddHours(-24)
} -ErrorAction:SilentlyContinue
}
catch {

}

$report = foreach($event in $events)
{
    [PSCustomObject]@{
            Computer=$event.PSComputerName
            EventID=$event.EventID
            EventType=$event.EntryType
            EventSource=$event.Source
            TimeCreated=$event.TimeGenerated
			Message=$event.Message
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
This reports the newest 10 Error Events, on all servers it successfully connects.
#summary
#body
</body>
'@

$subject = "Daily Event Issues"
$summary = $report | Group-Object Computer,EventSource,EventType | Sort-Object Count -Descending | Select-Object Name,Count | ConvertTo-Html -Fragment -PreContent "<h1>Summary</h1>"
$body = $report | ConvertTo-Html -Fragment -PreContent "<h1>Details</h1>"
$html = $html.Replace('#summary', $summary)
$html = $html.Replace('#body', $body)
