
# ServiceNow Scripts

This repository contains PowerShell scripts designed for use with ServiceNow.

## Post Incident Script (PowerShell)

**Purpose:** Efficiently import spreadsheet data into ServiceNow incidents.

### Important Notes

- **Column Names:** Ensure that the column names in your PowerShell script, such as `$row.Description` and `$row.'Short Description'`, match the column headers in your Excel file. Adjust them if necessary.

- **Security:** Avoid hardcoding sensitive information, such as credentials, in scripts used in production. Use secure credential storage methods or environment variables to manage sensitive data.

- **Reading the Excel File:** Use the `Import-Excel` cmdlet to read spreadsheet data into a variable. Update the `$excelFilePath` variable to point to the location of your Excel file.

---

## Clean Incident Queue Script

**Purpose:** Retrieve old incidents from ServiceNow and delete them based on specific conditions.

### Security and Usage Notes

- **Credentials:** Do not hardcode credentials in scripts for production environments. Use secure storage or environment variables for managing credentials.

- **State Codes:** Ensure you use the correct state codes according to your ServiceNow instance configuration. The example script uses `state=6` for resolved incidents. Other state codes may include:
  - `1`: New
  - `2`: In Progress
  - `3`: On Hold
  - `4`: Canceled
  - `7`: Closed

---

## Troubleshooting

1. **SSL Verification:** Make sure SSL verification is enabled in production environments to ensure secure communication.

---

This revised README provides a clearer structure and improves readability, helping users understand and follow the instructions more effectively.