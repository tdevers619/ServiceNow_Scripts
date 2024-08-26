Connect-MgGraph -Scopes User.ReadWrite.All -NoWelcome

# Functions for Colored Output
function Green { process { Write-Host $_ -ForegroundColor Green } }
function Red { process { Write-Host $_ -ForegroundColor Red } }

# Function for Numbered Array
function Add-Index {
    param (
        [Parameter(Mandatory=$true)]
        [array]$InputArray,
        [string]$IndexName = "Index"
    )
    
    $i = 0
    return $InputArray | ForEach-Object {
        # Clone Object
        $clone = $_ | Select-Object -Property * -ExcludeProperty $IndexName

        # Add or Update the Index
        $clone | Add-Member -MemberType NoteProperty -Name $IndexName -Value (++$i) -PassThru
    }
}

# Function for Outputting Results
function OutputResults {
    param (
        [string]$Title,
        [string]$Description,
        [array]$Data,
        [array]$Columns
    )

    $Title | Red
    $Description | Red
    if ($Data) {
        $IndexedData = Add-Index -InputArray $Data
        $IndexedData | Format-Table @($Columns)
    } else {
        "No Results Found" | Green
        "" | Out-String
    }
}

# Fetch All Active Users
$ActiveUsers = Get-MgUser -All -Filter 'accountEnabled eq true' -Select "displayName,UserPrincipalName,employeeType,ID,SignInActivity,CompanyName"
$DisabledUsers = Get-MgUser -All -Filter 'accountEnabled eq false' -Select "displayName,UserPrincipalName,employeeType,ID,SignInActivity"

# Convert Active User List to Hashtable
$UserList = @{}
foreach ($User in $ActiveUsers) {
    $UserList[$User.ID] = [PSCustomObject]@{
        DisplayName = $User.DisplayName
        UserPrincipalName = $User.UserPrincipalName
        ID = $User.ID
        EmployeeType = $User.employeeType
        SignInActivity = $User.SignInActivity
        CompanyName = $User.CompanyName
    }
}

# Split and Categorize Users
$SharedMailBoxUsers = $UserList.Values | Where-Object { $_.EmployeeType -eq "Shared Mailbox" }
$UsersWithoutEmployeeType = $UserList.Values | Where-Object { [string]::IsNullOrEmpty($_.EmployeeType) }
$UsersIncorrectEmployeeType = $UserList.Values | Where-Object { $_.EmployeeType -notin @("Full-Time Employee", "Contractor", "Service Account", "Shared Mailbox", "External Vendor") }
$VendorAccounts = $UserList.Values | Where-Object { $_.EmployeeType -eq "External Vendor" }
$ServiceAccounts = $UserList.Values | Where-Object { $_.EmployeeType -eq "Service Account" }
$ContractorAccounts = $UserList.Values | Where-Object { $_.EmployeeType -eq "Contractor" }
$ActiveAccounts = $UserList.Values | Where-Object { $_.EmployeeType -eq "Full-Time Employee"}
$ActiveFTRAccounts = $UserList.Values | Where-Object { $_.EmployeeType -eq "Full-Time Employee" -and $_.CompanyName -eq "For The Record" }
$ActiveLabsAccounts = $UserList.Values | Where-Object { $_.EmployeeType -eq "Full-Time Employee" -and $_.CompanyName -eq "For The Record - Labs" }
$SharedMailboxes = $DisabledUsers | Where-Object { $_.DisplayName -like "SMB*" }

# Disabled Users Consuming Licenses
$DisabledLicensedAccounts = foreach ($User in $DisabledUsers) {
    $Licenses = (Get-MgUserLicenseDetail -UserId $User.Id)
    if ($Licenses) {
        [PSCustomObject]@{
            Username = $User.DisplayName
            UserPrincipalName = $User.UserPrincipalName
            ID = $User.Id
            Licenses = $Licenses.SkuPartNumber -join ", "
        }
    }
}

# Active Stale Users > 14 days 
$2WeeksAgo = (Get-Date).AddDays(-14)
$StaleUsers = $UserList.Values | Where-Object {
    $_.SignInActivity.LastSignInDateTime -lt $2WeeksAgo
} | Select-Object DisplayName, UserPrincipalName, ID, @{Name="LastSignInDateTime"; Expression={$_.SignInActivity.LastSignInDateTime}}

# Users Not in Any Role Groups.
$Groups = Get-MgGroup -All | Where-Object { $_.DisplayName -like "RG*" }
$UsersNotInRG = @()
foreach ($User in $ActiveAccounts) {
    $UserGroups = Get-MgUserMemberOf -UserId $User.ID
    $IsInRG = $Groups | Where-Object { $UserGroups.Id -contains $_.Id }

    if (-not $IsInRG) {
        $UsersNotInRG += $User
    }
}

# Users in More Than One Role Group
$usersInMultipleGroups = @{}
foreach ($Group in $Groups) {
    $Members = Get-MgGroupMember -GroupId $Group.Id
    foreach ($Member in $Members) {
        if ($usersInMultipleGroups.ContainsKey($Member.Id)) {
            $usersInMultipleGroups[$Member.Id].Groups += $Group.DisplayName
        } else {
            $usersInMultipleGroups[$Member.Id] = [PSCustomObject]@{
                UserPrincipalName = $Member.UserPrincipalName
                DisplayName = $Member.DisplayName
                Groups = @($Group.DisplayName)
            }
        }
    }
}
$MultipleRGs = $usersInMultipleGroups.Values | Where-Object { $_.Groups.Count -gt 1 }

# Define Columns for Output Format
$CommonColumns = @(
    @{Expression={$_.Index}; Label="No."; Width=5},
    @{Expression={$_.DisplayName}; Label="Display Name"; Width=30},
    @{Expression={$_.UserPrincipalName}; Label="User Principal Name"; Width=40},
    @{Expression={$_.ID}; Label="ID"; Width=40},
    @{Expression={$_.EmployeeType}; Label="Employee Type"; Width=30}
)

$LicenseColumns = @(
    @{Expression={$_.Index}; Label="No."; Width=5},
    @{Expression={$_.Username}; Label="Display Name"; Width=30},
    @{Expression={$_.UserPrincipalName}; Label="User Principal Name"; Width=40},
    @{Expression={$_.ID}; Label="ID"; Width=40},
    @{Expression={$_.Licenses}; Label="Licenses"; Width=30}
)

$StaleColumns = @(
    @{Expression={$_.Index}; Label="No."; Width=5},
    @{Expression={$_.DisplayName}; Label="Display Name"; Width=30},
    @{Expression={$_.UserPrincipalName}; Label="User Principal Name"; Width=40},
    @{Expression={$_.ID}; Label="ID"; Width=40},
    @{Expression={$_.LastSignInDateTime}; Label="Last Sign-In Date"; Width=30}
)

# Output categorized data
OutputResults -Title "1. Users - Not in Role Group." -Description "Users Must be a Member of a Role Group, Please Refer to Functionally and Correct the Following Users." -Data $UsersNotInRG -Columns $CommonColumns
OutputResults -Title "2. Users - In Multiple Role Groups" -Description "Users Must be in One Role Group Only, Please Refer to Functionally and Correct the Following Users." -Data $MultipleRGs -Columns $CommonColumns
OutputResults -Title "3. Accounts - With EmployeeType Set Incorrectly" -Description "Accounts Must Fall Under an Approved EmployeeType, Please Correct the Following Accounts." -Data $UsersIncorrectEmployeeType -Columns $CommonColumns
OutputResults -Title "4. Accounts - Without EmployeeType" -Description "All Accounts Must Have the 'EmployeeType' Field Set, Please Correct the Following Accounts." -Data $UsersWithoutEmployeeType -Columns $CommonColumns
OutputResults -Title "5. Accounts - Disabled & Licensed" -Description "Disabled Accounts Should Not Consume a License, Please Correct the Following Accounts." -Data $DisabledLicensedAccounts -Columns $LicenseColumns
OutputResults -Title "6. Accounts - Active 'Shared Mailbox' Users" -Description "'Shared Mailbox' Accounts Must be Disabled, Please Correct the Following Accounts." -Data $SharedMailBoxUsers -Columns $CommonColumns
OutputResults -Title "7. Accounts - Active 'Shared Mailboxes'" -Description "These are Correctly Configured Shared Mailboxes, Are These Still Required?" -Data $SharedMailboxes -Columns $CommonColumns 
OutputResults -Title "8. Accounts - Active 'External Vendor'" -Description "Please Review the Following 'Vendor' Accounts, Are These Still Required?" -Data $VendorAccounts -Columns $CommonColumns
OutputResults -Title "9. Accounts - Active 'FTR Service'" -Description "Please Review the Following 'Service' Accounts, Are These Still Required?" -Data $ServiceAccounts -Columns $CommonColumns
OutputResults -Title "10. Accounts - Active FTR 'Contractor'" -Description "Please Review the Following 'Contractor' Accounts, Are These Still Required?" -Data $ContractorAccounts -Columns $CommonColumns
OutputResults -Title "11. Accounts - Active 'Stale' > 14 Days" -Description "Please Review the Following 'Stale' Accounts, Are These Still Required?" -Data $StaleUsers -Columns $StaleColumns
OutputResults -Title "12. Users - Active 'Fulltime' FTR Employees" -Description "A Complete List of All Active FTR Staff" -Data $ActiveFTRAccounts -Columns $CommonColumns
OutputResults -Title "13. Users - Active 'Fulltime' LABS Employees" -Description "A Complete List of All Active LABS Staff" -Data $ActiveLabsAccounts -Columns $CommonColumns