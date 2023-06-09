$allLabels = gh label list --limit 1000 --json name | ConvertFrom-Json

$allServiceIssues = gh issue list --state open --limit 1000 --label 'Service Attention' --json number,title,url,labels,createdAt,updatedAt | ConvertFrom-Json

Write-Host "Total service issues: " $allServiceIssues.Count

$now = Get-Date

Write-Host "Now is " $now "."

$result = @{}
foreach($serviceIssue in $allServiceIssues){
	$createdDays = ($now - $serviceIssue.createdAt).Days
	$notUpdatedDays = ($now - $serviceIssue.updatedAt).Days
	$serviceIssue | Add-Member -MemberType NoteProperty -Name "createdDays" -Value $createdDays
	$serviceIssue | Add-Member -MemberType NoteProperty -Name "notUpdatedDays" -Value $notUpdatedDays
	foreach($issueLabel in $serviceIssue.labels.name){
		if(-not $result.Contains($issueLabel)){
			$result[$issueLabel] = @()
		}
		$result[$issueLabel] += $serviceIssue
	}
}

$result.Remove("Service Attention")

Write-Host "Total notified services: " $result.Count

$outFile = 'azps_service_issue.html'
if( Test-Path -PathType Leaf $outFile ){
	Write-Host "Clear content of " $outFile
	Clear-Content $outFile
}else{
	Write-Host "Create a new output file" $outFile "for report."
	New-Item $outFile
}

echo "<h1>Azure PowerShell Issue Report<!--StartFragment --></h1>" > $outFile

$index = 0
$totalSize = $result.Count

foreach($service in ($result.Keys | Sort-Object)){
	$index += 1
	$serviceResult = $result[$service]
	$totalServiceIssueCount = $serviceResult.Count
	
	Write-Host "[${index}/${totalSize}]:" $service $totalServiceIssueCount
	echo "<h2>${service}</h2>" >> $outFile
	
	$serviceIssueCountLessThan30Days = ($serviceResult | where notUpdatedDays -LE 30).Count
	$serviceIssueCountGreaterThan30DaysLessThan90days = ($serviceResult | where notUpdatedDays -GT 30 | where notUpdatedDays -LE 90).Count
	$serviceIssueCountGreaterThan90days = ($serviceResult | where notUpdatedDays -GT 90).Count
	
	echo "<ul>" >> $outFile
	echo "<li>Total issue: ${totalServiceIssueCount}</li>" >> $outFile
	echo "<li>Issue counted by Idle Days:" >> $outFile
	echo "<ul>" >> $outFile
	if($serviceIssueCountGreaterThan90days -GT 0){
		echo "<li>&gt;90: ${serviceIssueCountGreaterThan90days}</li>" >> $outFile
	}
	if($serviceIssueCountGreaterThan30DaysLessThan90days -GT 0){
		echo "<li>30~60: ${serviceIssueCountGreaterThan30DaysLessThan90days}</li>" >> $outFile
	}
	if($serviceIssueCountLessThan30Days -GT 0){
		echo "<li>&lt;30: ${serviceIssueCountLessThan30Days}</li>" >> $outFile
	}
	echo "</ul>" >> $outFile
	echo "</li>" >> $outFile
	echo "</ul>" >> $outFile
	
	echo "<table border=""1"" cellpadding=""1"" cellspacing=""1"">" >> $outFile
	echo "<tbody>" >> $outFile
	# table header
	echo "<tr><th>number</th><th>title</th><th>idle days</th>" >> $outFile
	# table rows
	foreach($serviceIssue in ($serviceResult | Sort-Object -Property notUpdatedDays -Descending)){
		echo "<tr>" >> $outFile
		
		$notUpdatedDays = $serviceIssue.notUpdatedDays
		
		$style = ""
		if($notUpdatedDays -LE 30){
			$style = ""
		}elseif($notUpdatedDays -LE 90){
			$style = 'style="background-color:#f1c40f"'
		}else{
			$style = 'style="background-color:#e74c3c"'
		}
		
		echo "<td><p>$($serviceIssue.number)</p></td>" >> $outFile
		echo "<td><p><a href=""$($serviceIssue.url)"">$($serviceIssue.title)</a></p></td>" >> $outFile
		echo "<td><p><span ${style}>${notUpdatedDays}</span></p></td>" >> $outFile
		
		echo "</tr>" >> $outFile
	}
	
	echo "</tbody>" >> $outFile
	echo "</table>" >> $outFile
}

