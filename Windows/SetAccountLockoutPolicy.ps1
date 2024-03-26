# Set the account lockout threshold to 3 invalid logon attempts
secedit /configure /db secedit.sdb /cfg secedit.inf /areas SECURITYPOLICY

# Create the security policy template file
$policyTemplate = @"
[Unicode]
Unicode=yes
[System Access]
LockoutBadCount = 3
[Event Audit]
AuditAccountLogon = 3
"@

# Save the policy template to a file
$policyTemplatePath = "$env:TEMP\secedit.inf"
$policyTemplate | Out-File -FilePath $policyTemplatePath -Encoding Unicode

# Apply the security policy
secedit /configure /db secedit.sdb /cfg $policyTemplatePath /areas SECURITYPOLICY

# Clean up the temporary policy template file
Remove-Item -Path $policyTemplatePath

# Enable auditing for logon events (success and failure)
auditpol /set /subcategory:"Logon/Logoff" /success:enable /failure:enable

# Inform the user that the policy has been applied
Write-Output "Account lockout policy and auditing have been configured."
