# Example usage of the function
$instance = "your-instance"
$username = "your-username"
$password = "your-password"

$authData = Get-ServiceNowAuthHeaders -username $username -password $password -instance $instance

# Extract URI and headers from the returned hash table
$uri = $authData["Uri"]
$headers = $authData["Headers"]

# Prepare the JSON body for the request
$body = @{
    "short_description" = "Annual Account Check"
    "description"       = "The following users have been detected as inactive:`n`n$inactiveUsersSummary"
    "urgency"           = "3"  # Assuming this is a low urgency issue
    "impact"            = "3"  # Assuming this is a low impact issue
} | ConvertTo-Json

# Make the API call to ServiceNow to create the ticket
try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body

    # Log the result
    Write-Output "Ticket created successfully. Ticket number: $($response.result.number)"
} catch {
    # Log the error
    Write-Error "Failed to create the ticket. Error: $_"
}