Function Backup-Release
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
		# Release id
		[Parameter()]
		[Int[]]$ReleaseIds
	)

	$Header = [Ordered]@{
		"Content-Type" = "application/json"
		"Accept" = "application/json"
	}
	if($PAT) { $Header["Authorization"] = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
	if($AccessToken) { $Header["Authorization"] = "Bearer " + $AccessToken }

	#Get Projects
	$UriBase = "https://dev.azure.com/$($OrganizationName)/"
	$UriBase2 = "https://vsrm.dev.azure.com/$($OrganizationName)/"

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

		#Get Pipeline
		$Releases = @()
		if($ReleaseIds.Count)
		{
			Foreach($ReleaseId in $ReleaseIds)
			{
				$Uri = $UriBase2 + "$($Project.Name)/_apis/release/definitions/$($ReleaseId)?api-version=$ApiVersion"
				$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header
				$Releases += $Response
			}
		} else {
			$Uri = $UriBase2 + "$($Project.Name)/_apis/release/definitions?api-version=$ApiVersion"
			$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header
			Foreach($Release in $Response.value)
			{
				$ReleaseId = $Release.Id
				$Uri = $UriBase2 + "$($Project.Name)/_apis/release/definitions/$($ReleaseId)?api-version=$ApiVersion"
				$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header
				$Releases += $Response
			}
		}

		Foreach($Release in $Releases)
		{
			Write-Output "Project: $($Project.Name), Release: $($Release.Name)"

			#Get Release
			$FileName = "Release_" + $Release.name + ".json"
			$OutFile = Join-Path -Path $ProjectPath -ChildPath $FileName

			$Release | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutFile
		}
	}
}
