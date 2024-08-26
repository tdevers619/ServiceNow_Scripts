# Import the ImportExcel module
Import-Module ImportExcel

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

# Path to your Excel file
$excelFilePath = "C:\path\to\your\spreadsheet.xlsx"

# Read the Excel file into a variable
$data = Import-Excel -Path $excelFilePath

# Loop through each row in the Excel file
foreach ($row in $data) {
    # Extract the necessary information from each row
    $description = $row.Description # Adjust this to the correct column name in your Excel file
    $shortDescription = $row.'Short Description' # Adjust as needed

    # Define the payload for the new incident
    $body = @{
        short_description = $shortDescription
        description = $description
        urgency = "2" # Example urgency
        impact = "2"   # Example impact
    } | ConvertTo-Json

    # Make the POST request to create the incident
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Post -Body $body
        Write-Output "Incident created with number: $($response.result.number)"
    } catch {
        Write-Output "Error creating incident for row: $($row.Index). Error: $_"
    }
}
