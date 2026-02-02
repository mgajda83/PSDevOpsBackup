Function Backup-Endpoint
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
		# Endpoint name
		[Parameter()]
		[String[]]$EndpointNames
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

		#Get Endpoint
		$Endpoints = @()
		if($EndpointIds.Count)
		{
			Foreach($EndpointId in $EndpointIds)
			{
				$Uri = $UriBase + "$($Project.Name)/_apis/serviceendpoint/endpoints?endpointNames=$($EndpointNames)&api-version=$ApiVersion"
				$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header
				$Endpoints += $Response.value
			}
		} else {
			$Uri = $UriBase + "$($Project.Name)/_apis/serviceendpoint/endpoints?api-version=$ApiVersion"
			$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header
			Foreach($Endpoint in $Response.value)
			{
				$EndpointId = $Endpoint.Id
				$Uri = $UriBase + "$($Project.Name)/_apis/serviceendpoint/endpoints?endpointNames=$($EndpointNames)&api-version=$ApiVersion"
				$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Header
				$Endpoints += $Response.value
			}
		}

		Foreach($Endpoint in $Endpoints)
		{
			Write-Output "Project: $($Project.Name), Endpoint: $($Endpoint.Name)"

			#Get Endpoint Conf
			$FileName = "EndpointConf_" + $Endpoint.name + ".json"
			$OutFile = Join-Path -Path $ProjectPath -ChildPath $FileName

			$Endpoint | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutFile
		}
	}
}
