<#
Script Name: Test-IntuneConnectivity.ps1

DESCRIPTION
The script checks all URL in https://learn.microsoft.com/en-us/mem/intune/fundamentals/intune-endpoints?WT.mc_id=M365-MVP-5004140&tabs=north-america#powershell-script using Invoke-WebRequest. 

PARAMETERS
n/a

PREREQUISITES
PowerShell 3.0 or later
Does not require elevation
#>

Function Get-M365CommonEndpointList {
    # Get up-to-date URLs
    $endpointListM365 = (invoke-restmethod -Uri ("https://endpoints.office.com/endpoints/WorldWide?ServiceAreas=Common`&clientrequestid=" + ([GUID]::NewGuid()).Guid)) | Where-Object { $_.ServiceArea -eq "Common" -and $_.urls }

    # Create categories to better understand what is being tested
    [PsObject[]]$endpointListCategoriesM365 = @()
    $endpointListCategoriesM365 += [PsObject]@{id = 56; category = 'M365 Common'; mandatory = $true }
    $endpointListCategoriesM365 += [PsObject]@{id = 59; category = 'M365 Common'; mandatory = $true }
    $endpointListCategoriesM365 += [PsObject]@{id = 78; category = 'M365 Common'; mandatory = $true }
    $endpointListCategoriesM365 += [PsObject]@{id = 83; category = 'M365 Common'; mandatory = $true }
    $endpointListCategoriesM365 += [PsObject]@{id = 84; category = 'M365 Common'; mandatory = $true }
    $endpointListCategoriesM365 += [PsObject]@{id = 125; category = 'M365 Common'; mandatory = $true }
    $endpointListCategoriesM365 += [PsObject]@{id = 156; category = 'M365 Common'; mandatory = $true }
    
    # Create new output object and extract relevant test information (ID, category, URLs only)
    [PsObject[]]$endpointRequestListM365 = @()
    for ($i = 0; $i -lt $endpointListM365.Count; $i++) {
        $endpointRequestListM365 += [PsObject]@{ id = $endpointListM365[$i].id; category = ($endpointListCategoriesM365 | Where-Object { $_.id -eq $endpointListM365[$i].id }).category; urls = $endpointListM365[$i].urls; mandatory = ($endpointListCategoriesM365 | Where-Object { $_.id -eq $endpointListM365[$i].id }).mandatory }
    }

    # Remove all *. from URL list (not useful)
    for ($i = 0; $i -lt $endpointRequestListM365.Count; $i++) {
        for ($j = 0; $j -lt $endpointRequestListM365[$i].urls.Count; $j++) {
            $targetUrl = $endpointRequestListM365[$i].urls[$j].replace('*.', '')
            $endpointRequestListM365[$i].urls[$j] = $targetURL
        }
        $endpointRequestListM365[$i].urls = $endpointRequestListM365[$i].urls | Sort-Object -Unique
    }
    
    return $endpointRequestListM365
}

Function Get-IntuneEndpointList {
    # Get up-to-date URLs
    $endpointList = (invoke-restmethod -Uri ("https://endpoints.office.com/endpoints/WorldWide?ServiceAreas=MEM`&clientrequestid=" + ([GUID]::NewGuid()).Guid)) | Where-Object { $_.ServiceArea -eq "MEM" -and $_.urls }

    # Create categories to better understand what is being tested
    [PsObject[]]$endpointListCategories = @()
    $endpointListCategories += [PsObject]@{id = 163; category = 'Global'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 164; category = 'Delivery Optimization'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 165; category = 'NTP Sync'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 169; category = 'Windows Notifications & Store'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 170; category = 'Scripts & Win32 Apps'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 171; category = 'Push Notifications'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 172; category = 'Delivery Optimization'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 173; category = 'Autopilot Self-deploy'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 178; category = 'Apple Device Management'; mandatory = $false }
    $endpointListCategories += [PsObject]@{id = 179; category = 'Android (AOSP) Device Management'; mandatory = $false }
    $endpointListCategories += [PsObject]@{id = 181; category = 'Remote Help'; mandatory = $false }
    $endpointListCategories += [PsObject]@{id = 182; category = 'Collect Diagnostics'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 186; category = 'Microsoft Azure attestation - Windows 11 only'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 187; category = 'Android Remote Help'; mandatory = $false }
    $endpointListCategories += [PsObject]@{id = 188; category = 'Remote Help GCC Dependency'; mandatory = $false }
    $endpointListCategories += [PsObject]@{id = 189; category = 'Feature Flighting'; mandatory = $false }
    
    # Create new output object and extract relevant test information (ID, category, URLs only)
    [PsObject[]]$endpointRequestList = @()
    for ($i = 0; $i -lt $endpointList.Count; $i++) {
        $endpointRequestList += [PsObject]@{ id = $endpointList[$i].id; category = ($endpointListCategories | Where-Object { $_.id -eq $endpointList[$i].id }).category; urls = $endpointList[$i].urls; mandatory = ($endpointListCategories | Where-Object { $_.id -eq $endpointList[$i].id }).mandatory }
    }

    # Remove all *. from URL list (not useful)
    for ($i = 0; $i -lt $endpointRequestList.Count; $i++) {
        for ($j = 0; $j -lt $endpointRequestList[$i].urls.Count; $j++) {
            $targetUrl = $endpointRequestList[$i].urls[$j].replace('*.', '')
            $endpointRequestList[$i].urls[$j] = $targetURL
        }
        $endpointRequestList[$i].urls = $endpointRequestList[$i].urls | Sort-Object -Unique
    }
    
    return $endpointRequestList
}

Function Test-Connectivity  {
    param(
        [PsObject[]] $endpointList
        
    )
    $ErrorActionPreference = 'SilentlyContinue'
    $TestFailed = $false
    
    Write-Host "Starting Connectivity Check..." -ForegroundColor Yellow

    foreach ($endpoint in $endpointList) 
    {        
        if ($endpoint.mandatory -eq $true) 
        {  
            Write-Host "Checking Category: ..." $endpoint.category -ForegroundColor Yellow
            foreach ($url in $endpoint.urls) {
				$TestResult = $false
				$FailResult = ""
                $http_url = $url
                $url = "https://" + $url #try https first
            
                try
			{
				$TestResult = (Invoke-WebRequest -uri $url -UseBasicParsing ).StatusCode
			} catch {
				$TestResult = $_.Exception.Response.StatusCode.value__
			}
            
                if ($TestResult) 
                {
                    if (($url.StartsWith('approdimedata') -or ($url.StartsWith("intunemaape13") -or $url.StartsWith("intunemaape17") -or $url.StartsWith("intunemaape18") -or $url.StartsWith("intunemaape19")))) {
                        Write-Host "Connection to " $url ".............. Succeeded stat=$TestResult (needed for Asia & Pacific tenants only)." -ForegroundColor Green 
                    }
                    elseif (($url.StartsWith('euprodimedata') -or ($url.StartsWith("intunemaape7") -or $url.StartsWith("intunemaape8") -or $url.StartsWith("intunemaape9") -or $url.StartsWith("intunemaape10") -or $url.StartsWith("intunemaape11") -or $url.StartsWith("intunemaape12")))) {
                        Write-Host "Connection to " $url ".............. Succeeded stat=$TestResult (needed for Europe tenants only)." -ForegroundColor Green 
                    }
                    elseif (($url.StartsWith('naprodimedata') -or ($url.StartsWith("intunemaape1") -or $url.StartsWith("intunemaape2") -or $url.StartsWith("intunemaape3") -or $url.StartsWith("intunemaape4") -or $url.StartsWith("intunemaape5") -or $url.StartsWith("intunemaape6")))) {
                        Write-Host "Connection to " $url ".............. Succeeded stat=$TestResult (needed for North America tenants only)." -ForegroundColor Green 
                    }
                    else {
                        Write-Host "Connection to " $url ".............. Succeeded. stat=$TestResult" -ForegroundColor Green 
                    }
                }
                else 
                {
				    $url = $http_url #try http
					try
					{
						$TestResult = (Invoke-WebRequest -uri $url -UseBasicParsing ).StatusCode
					} catch {
						$TestResult = $_.Exception.Response.StatusCode.value__
						if (-not $TestResult) {
							$FailResult = $_ |select-string -Pattern 'could not be resolved'
						}
					}
				
					if ($TestResult) 
					{
						if (($url.StartsWith('approdimedata') -or ($url.StartsWith("intunemaape13") -or $url.StartsWith("intunemaape17") -or $url.StartsWith("intunemaape18") -or $url.StartsWith("intunemaape19")))) {
							Write-Host "Connection to " $url ".............. Succeeded stat=$TestResult (needed for Asia & Pacific tenants only)." -ForegroundColor Green 
						}
						elseif (($url.StartsWith('euprodimedata') -or ($url.StartsWith("intunemaape7") -or $url.StartsWith("intunemaape8") -or $url.StartsWith("intunemaape9") -or $url.StartsWith("intunemaape10") -or $url.StartsWith("intunemaape11") -or $url.StartsWith("intunemaape12")))) {
							Write-Host "Connection to " $url ".............. Succeeded stat=$TestResult (needed for Europe tenants only)." -ForegroundColor Green 
						}
						elseif (($url.StartsWith('naprodimedata') -or ($url.StartsWith("intunemaape1") -or $url.StartsWith("intunemaape2") -or $url.StartsWith("intunemaape3") -or $url.StartsWith("intunemaape4") -or $url.StartsWith("intunemaape5") -or $url.StartsWith("intunemaape6")))) {
							Write-Host "Connection to " $url ".............. Succeeded stat=$TestResult (needed for North America tenants only)." -ForegroundColor Green 
						}
						else {
							Write-Host "Connection to " $url ".............. Succeeded. stat=$TestResult" -ForegroundColor Green 
						}
					}
					else 
					{
					
						if (($url.StartsWith('approdimedata') -or ($url.StartsWith("intunemaape13") -or $url.StartsWith("intunemaape17") -or $url.StartsWith("intunemaape18") -or $url.StartsWith("intunemaape19")))) {
							Write-Host "Connection to " $url ".............. Failed $FailResult(needed for Asia & Pacific tenants only)." -ForegroundColor Red 
						}
						elseif (($url.StartsWith('euprodimedata') -or ($url.StartsWith("intunemaape7") -or $url.StartsWith("intunemaape8") -or $url.StartsWith("intunemaape9") -or $url.StartsWith("intunemaape10") -or $url.StartsWith("intunemaape11") -or $url.StartsWith("intunemaape12")))) {
							Write-Host "Connection to " $url ".............. Failed $FailResult (needed for Europe tenants only)." -ForegroundColor Red 
						}
						elseif (($url.StartsWith('naprodimedata') -or ($url.StartsWith("intunemaape1") -or $url.StartsWith("intunemaape2") -or $url.StartsWith("intunemaape3") -or $url.StartsWith("intunemaape4") -or $url.StartsWith("intunemaape5") -or $url.StartsWith("intunemaape6")))) {
							Write-Host "Connection to " $url ".............. Failed $FailResult(needed for North America tenants only)." -ForegroundColor Red 
						}
						else {
							Write-Host "Connection to " $url ".............. Failed.$FailResult" -ForegroundColor Red 
						}
					}
                }
            }
        }
        else 
        {
            #Write-Host "Skipping Category: ..." $endpoint.category -ForegroundColor Yellow
        }
    }
}



Function Test-IntuneConnectivity  {
    # Get the current network config of the system and display
    $NetworkConfiguration = @()
    Get-NetIPConfiguration | ForEach-Object {
        $NetworkConfiguration += New-Object PSObject -Property @{
            InterfaceAlias = $_.InterfaceAlias
            ProfileName = if($null -ne $_.NetProfile.Name){$_.NetProfile.Name}else{""}
            IPv4Address = if($null -ne $_.IPv4Address){$_.IPv4Address}else{""}
            IPv6Address = if($null -ne $_.IPv6Address){$_.IPv6Address}else{""}
            IPv4DefaultGateway = if($null -ne $_.IPv4DefaultGateway){$_.IPv4DefaultGateway.NextHop}else{""}
            IPv6DefaultGateway = if($null -ne $_.IPv6DefaultGateway){$_.IPv6DefaultGateway.NextHop}else{""}
            DNSServer = if($null -ne $_.DNSServer){$_.DNSServer.ServerAddresses}else{""}
        }
    }

    $NetworkConfiguration | Format-Table -AutoSize
    $endpointListM365Common = Get-M365CommonEndpointList
    $endpointListIntune = Get-IntuneEndpointList
    
    Test-Connectivity -endpointList $endpointListM365Common 
    Test-Connectivity -endpointList $endpointListIntune 
    Write-Host "Test-DeviceIntuneConnectivity completed successfully." -ForegroundColor Green -BackgroundColor Black
}

Test-IntuneConnectivity
