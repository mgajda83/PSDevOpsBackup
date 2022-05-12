# PSDevOpsBackup
PowerShell module for backup DevOps repos.


$PAT = "Personal Access Token"
$OrganizationName = "OrgName"

Backup-Repository -PAT $PAT -OrganizationName $OrganizationName -OutputPath C:\Backup\AzureDevOps
Backup-Pipeline -PAT $PAT -OrganizationName $OrganizationName -OutputPath C:\Backup\AzureDevOps
Backup-Release -PAT $PAT -OrganizationName $OrganizationName -OutputPath C:\Backup\AzureDevOps
Backup-VariableGroup -PAT $PAT -OrganizationName $OrganizationName -OutputPath C:\Backup\AzureDevOps
