# Define your ServiceNow instance and credentials
$instanceName = "your_instance_name"
$username = "your_username"
$password = "your_password"

# Create the ServiceNow API URL for the incident table
$apiUrl = "https://$instanceName.service-now.com/api/now/table/incident"

# Create the authentication header
$authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("$username:$password")))
$headers = @{
    "Authorization" = "Basic $authInfo"
    "Content-Type" = "application/json"
}

# Set the query to find old incidents, e.g., incidents resolved more than 90 days ago
$daysOld = 90
$queryDate = (Get-Date).AddDays(-$daysOld).ToString("yyyy-MM-dd")
$query = "resolved_at<=$queryDate^state=6" # Example query for resolved incidents (state=6)

# Get the incidents to be deleted
$response = Invoke-RestMethod -Uri "$apiUrl?sysparm_query=$query" -Headers $headers -Method Get

if ($response.result.Count -eq 0) {
    Write-Output "No old incidents found matching the criteria."
} else {
    Write-Output "$($response.result.Count) old incidents found. Proceeding with deletion."

    foreach ($incident in $response.result) {
        $incidentSysId = $incident.sys_id
        $deleteUrl = "$apiUrl/$incidentSysId"

        try {
            # Delete the incident
            Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Delete
            Write-Output "Incident with Sys ID: $incidentSysId deleted successfully."
        } catch {
            Write-Output "Failed to delete incident with Sys ID: $incidentSysId. Error: $_"
        }
    }
}
