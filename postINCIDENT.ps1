# Step 1: Define the list of required modules
$requiredModules = @("Az.Accounts", "Az.Automation", "Az.Storage")

foreach ($module in $requiredModules) {
    # Check if the module is available (either loaded or installable)
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Output "Module '$module' is not available. Attempting to install..."

        try {
            # Attempt to install the module if not found
            Install-Module -Name $module -Scope CurrentUser -Force -ErrorAction Stop
            Write-Output "Module '$module' installed successfully."
        } catch {
            Write-Error "Failed to install module '$module'. Error: $_"
            exit 1
        }
    }

    # Import the module if it's not already imported
    if (-not (Get-Module -Name $module)) {
        try {
            Import-Module -Name $module -ErrorAction Stop
            Write-Output "Module '$module' imported successfully."
        } catch {
            Write-Error "Failed to import module '$module'. Error: $_"
            exit 1
        }
    } else {
        Write-Output "Module '$module' is already loaded."
    }
}

# End of Module Checks --------------------------------------

# Step 2: Get credentials from Azure Automation (only needed once)
$creds = Get-AutomationPSCredential -Name "ServiceNowCredential"  # <---- Gets the Azure Automation Credentials

# Step 3: Import the CSV data
$csvFilePath = "C:\path\to\your\inactive_users.csv"  # Define the path to your CSV file
$csvData = Import-Csv -Path $csvFilePath

# Step 4: Aggregate the CSV data into a summary format
$inactiveUsersSummary = $csvData | ForEach-Object {
    "User: $($_.Username), Email: $($_.Email), Last Active: $($_.LastActiveDate)"
} -join "`n"

# Step 5: Define the ServiceNow instance and API details
$instance = "your-instance"
$tableName = "incident"  # Choose another table if needed
$uri = "https://$instance.service-now.com/api/now/table/$tableName"

# Step 6: Create the authentication header for ServiceNow
$authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("$username:$password")))
$headers = @{
    "Authorization" = "Basic $authInfo"
    "Content-Type" = "application/json"
    "Accept" = "*/*"
    "Connection" = "keep-alive"
}

# Step 7: Prepare the JSON body for the request
$body = @{
    "short_description" = "List of Inactive Users Detected"
    "description" = "The following users have been detected as inactive:`n`n$inactiveUsersSummary"
    "urgency" = "3"  # Assuming this is a low urgency issue
    "impact" = "3"   # Assuming this is a low impact issue
} | ConvertTo-Json

# Step 8: Make the API call to ServiceNow to create the ticket
try {
    # Make the POST request to create a new ticket in ServiceNow
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -Credential $creds

    # Log the result
    Write-Output "Ticket created successfully. Ticket number: $($response.result.number)"
} catch {
    # Log the error
    Write-Error "Failed to create the ticket. Error: $_"
}
