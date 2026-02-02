Function Backup-VariableGroup
{
	[CmdletBinding(DefaultParameterSetName="AccessToken")]
	param (
		# Personal Access Token with DevOps Access
		[Parameter(ParameterSetName="PAT",Mandatory=$true)]
		[String]$PAT,
		# AccessToken with with DevOps Access
		[Parameter(ParameterSetName="AccessToken",Mandatory=$true)]
		[String]$AccessToken,
		# Azure DevOps organization name
		[Parameter(Mandatory=$true)]
		[String]$OrganizationName,
		# Azure DevOps Api version
		[Parameter()]
		[String]$ApiVersion = "7.1",
		# Output localization
		[Parameter(Mandatory=$true)]
		[String]$OutputPath,
		# Project name or id
		[Parameter()]
		[String[]]$ProjectIds,
		# VariableGroup id
		[Parameter()]
		[String[]]$VariableGroupIds
	)

	$Header = [Ordered]@{
		"Content-Type" = "application/json"
		"Accept" = "application/json"
	}
	if($PAT) { $Header["Authorization"] = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
	if($AccessToken) { $Header["Authorization"] = "Bearer " + $AccessToken }

	#Get Projects
	$UriBase = "https://dev.azure.com/$($OrganizationName)/"

	$OrganizationPath = Join-Path -Path $OutputPath -ChildPath $OrganizationName
	if(!(Test-Path -Path $OrganizationPath))
	{
		New-Item -Path $OutputPath -Name $OrganizationName -ItemType Directory | Out-Null
	}

	if($ProjectIds.Count)
	{
		$Projects = @()
		Foreach($ProjectId in $ProjectIds)
		{
			$Uri = $UriBase + "_apis/projects/$($ProjectId)?api-version=$ApiVersion"
			$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header
			$Projects += $Response
		}
	} else {
		$Uri = $UriBase + "_apis/projects?api-version=$ApiVersion"
		$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header
		$Projects = $Response.value
	}

	Foreach($Project in $Projects)
	{
		Write-Output "Project: $($Project.Name)"

		$ProjectPath = Join-Path -Path $OrganizationPath -ChildPath $Project.Name
		if(!(Test-Path -Path $ProjectPath))
		{
			New-Item -Path $OrganizationPath -Name $Project.Name -ItemType Directory | Out-Null
		}

		#Get VariableGroup
		if($VariableGroupIds.Count)
		{
			$VariableGroups = @()
			Foreach($VariableGroupId in $VariableGroupIds)
			{
				$Uri = $UriBase + "$($Project.Name)/_apis/distributedtask/variablegroups/$($VariableGroupId)?api-version=$ApiVersion"
				$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header
				$VariableGroups += $Response
			}
		} else {
			$Uri = $UriBase + "$($Project.Name)/_apis/distributedtask/variablegroups?api-version=$ApiVersion"
			$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header
			$VariableGroups = $Response.value
		}

		Foreach($VariableGroup in $VariableGroups)
		{
			Write-Output "Project: $($Project.Name), VariableGroup: $($VariableGroup.Name)"

			$FileName = "VarGr_" + $VariableGroup.name + ".json"
			$OutFile = Join-Path -Path $ProjectPath -ChildPath $FileName

			$VariableGroup.variables | ConvertTo-Json | Out-File -FilePath $OutFile
		}
	}
}
