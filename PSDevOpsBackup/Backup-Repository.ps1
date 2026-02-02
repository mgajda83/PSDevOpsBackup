Function Backup-Repository
{
	[CmdletBinding(DefaultParameterSetName="Token")]
	param (
		# Personal Access Token with DevOps Access
		[Parameter(ParameterSetName="PAT",Mandatory=$true)]
		[String]$PAT,
		# Token with with DevOps Access
		[Parameter(ParameterSetName="Token",Mandatory=$true)]
		[String]$Token,
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
		# Repository name or id
		[Parameter()]
		[String[]]$RepositoryIds
	)

	$Header = @{
		"Content-Type" = "application/json"
		"Accept" = "application/json"
	}
	if($PAT) { $Header["Authorization"] = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
	if($Token) { $Header["Authorization"] = "Bearer " + $($Token.AccessToken) }

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

		#Get Repos
		if($RepositoryIds.Count)
		{
			$Repositories = @()
			Foreach($RepositoryId in $RepositoryIds)
			{
				$Uri = $UriBase + "_apis/projects/$($ProjectId)?api-version=$ApiVersion"
				$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header
				$Repositories += $Response
			}
		} else {
			$Uri = $UriBase + "$($Project.Name)/_apis/git/repositories/$($RepositoryId)?api-version=$ApiVersion"
			$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header
			$Repositories = $Response.value
		}

		Foreach($Repository in $Repositories)
		{
			Write-Output "Project: $($Project.Name), Repository: $($Repository.Name)"

			#Download Items
			$Uri = $UriBase + $Project.Name + "/_apis/git/repositories/$($Repository.Name)/items?api-version=$ApiVersion&`$format=zip&download=true"

			$FileName = "Repo_" + $Repository.name + ".zip"
			$OutFile = Join-Path -Path $ProjectPath -ChildPath $FileName

			$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header -OutFile $OutFile
		}
	}
}
