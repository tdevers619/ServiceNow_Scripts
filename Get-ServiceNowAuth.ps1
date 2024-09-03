function Get-ServiceNowAuthHeaders {
    param (
        [string]$username,
        [string]$password,
        [string]$instance,
        [string]$tableName = "incident"  # Default table is "incident"
    )

    # Define the ServiceNow API URI
    $uri = "https://$instance.service-now.com/api/now/table/$tableName"

    # Create the authentication header for ServiceNow
    $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$username`:$password"))
    $headers = @{
        "Authorization" = "Basic $authInfo"
        "Content-Type"  = "application/json"
        "Accept"        = "*/*"
        "Connection"    = "keep-alive"
    }

    return @{
        "Uri" = $uri
        "Headers" = $headers
    }
}


