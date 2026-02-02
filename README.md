# PSDevOpsBackup
PowerShell module for backup DevOps repos.

With PAT:
```
$PAT = "Personal Access Token"
$OrganizationName = "OrgName"

Backup-Repository -PAT $PAT -OrganizationName $OrganizationName -OutputPath C:\Backup\AzureDevOps
Backup-Pipeline -PAT $PAT -OrganizationName $OrganizationName -OutputPath C:\Backup\AzureDevOps
Backup-Release -PAT $PAT -OrganizationName $OrganizationName -OutputPath C:\Backup\AzureDevOps
Backup-VariableGroup -PAT $PAT -OrganizationName $OrganizationName -OutputPath C:\Backup\AzureDevOps
Backup-Endpoint -PAT $PAT -OrganizationName $OrganizationName -OutputPath C:\Backup\AzureDevOps
Backup-TaskGroup -PAT $PAT -OrganizationName $OrganizationName -OutputPath C:\Backup\AzureDevOps
```

With SPN AccessToken:
```
$Params = @{
	Scope = @("https://app.vssps.visualstudio.com/.default")
	ClientId = $ApplicationId
	RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
	Certificate = $Certificate
	TenantId = $TenantId
}
$Token = Get-PSMSALToken @Params
$OrganizationName = "OrgName"

Backup-Repository -AccessToken $Token.AccessToken -OrganizationName $OrganizationName -OutputPath /Users/mgajda/Downloads/Backup/AzureDevOps
```
