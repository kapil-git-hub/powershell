# 1. Create Website, Web app and Virtual Dirs
# 2. Create App Pool and attach web app, virtual dirs with it
# 3. Verify websites are running properly on IIS server or not

# Import module to access IIS web management console
Import-Module "WebAdministration"

# Define computer/host name where IIS server is running
$server = 'localhost'
$project_dir = 'C:\DemoSite'
$app_pool_name = 'DemoAppPool'
$site_name = 'DemoSite'

# This function will check the status of IIS server
function Get-IIS-Status {
    $iis = Get-WmiObject Win32_Service -Filter "Name = 'W3SVC'" -ComputerName $server
    if ($iis.State -eq 'Running') { 
        Write-Host "`n`nIIS is up and running on $server ...`n`n" -ForegroundColor Green
        return 0;
    }
    Else { 
        Write-Host "IIS Server is not running on $server `n`n" -ForegroundColor Red
        return 1;        
    }
}

$check_status = Get-IIS-Status
# Check the status and Start IIS server if not running
if ($check_status){
    Write-Host "Starting IIS server $server ...`n`n" -ForegroundColor Yellow
    try{
        iisreset.exe /start
    }
    catch{
        Write-Host "Failed to Start IIS server $server ..." -ForegroundColor Red
        exit
    }
}

# It will clean workspace and created resource on IIS server
function Cleanup {
    Remove-IISSite -Name $site_name -Confirm:$False
    Write-Host "Deleted site : $site_name.`n`n" -ForegroundColor Green
    Remove-WebAppPool $app_pool_name
    Write-Host "Deleted apppool: $app_pool_name.`n`n" -ForegroundColor Green
    Remove-Item $project_dir -recurse
    Write-Host "Deleted project workspace: $project_dir.`n`n" -ForegroundColor Green
}

# Create project directories
Write-Host "Creating project directories...`n`n" -ForegroundColor Yellow
New-Item $project_dir -type Directory
New-Item $project_dir\DemoApp -type Directory
New-Item $project_dir\DemoVirtualDir1 -type Directory
New-Item $project_dir\DemoVirtualDir2 -type Directory
Write-Host "Successfully created project directories.`n`n" -ForegroundColor Green

# Add project content
Write-Host "Adding project content...`n`n" -ForegroundColor Yellow
Set-Content $project_dir\Default.htm "DemoSite Default Page"
Set-Content $project_dir\DemoApp\Default.htm "DemoSite\DemoApp Default Page"
Set-Content $project_dir\DemoVirtualDir1\Default.htm "DemoSite\DemoVirtualDir1 Default Page"
Set-Content $project_dir\DemoVirtualDir2\Default.htm "DemoSite\DemoApp\DemoVirtualDir2 Default Page"
Write-Host "Successfully added project content.`n`n" -ForegroundColor Green

Write-Host "Creating app pool, website, web app and virtual dirs...`n`n" -ForegroundColor Yellow
# Create application pool
New-Item IIS:\AppPools\$app_pool_name
# Create/add website
New-Item IIS:\Sites\$site_name -physicalPath $project_dir -bindings @{protocol="http";bindingInformation=":8080:"}
# Add/attach website in application pool
Set-ItemProperty IIS:\Sites\$site_name -name applicationPool -value $app_pool_name
# Create web application and attach further in application pool
New-Item IIS:\Sites\$site_name\DemoApp -physicalPath $project_dir\DemoApp -type Application
Set-ItemProperty IIS:\sites\$site_name\DemoApp -name applicationPool -value $app_pool_name
# Create virtual directories underneath the website and web application
New-Item IIS:\Sites\$site_name\DemoVirtualDir1 -physicalPath $project_dir\DemoVirtualDir1 -type VirtualDirectory
New-Item IIS:\Sites\$site_name\DemoApp\DemoVirtualDir2 -physicalPath $project_dir\DemoVirtualDir2 -type VirtualDirectory
Write-Host "Successfully created app pool, website, web app and virtual dirs...`n`n" -ForegroundColor Green

# Download different web page's content using the .NET WebClient classes
Write-Host "Downloading different web page's content using the .NET WebClient classes...`n" -ForegroundColor Yellow
$webclient = New-Object Net.WebClient
$webclient.DownloadString("http://localhost:8080/");
$webclient.DownloadString("http://localhost:8080/DemoApp");
$webclient.DownloadString("http://localhost:8080/DemoVirtualDir1");
$webclient.DownloadString("http://localhost:8080/DemoApp/DemoVirtualDir2");
Write-Host "Successfully downloaded all web pages content using the .NET WebClient classes.`n`n" -ForegroundColor Green

# Call cleanup function to clean workspace and created resources over IIS server
Cleanup
Write-Host "Done!!" -ForegroundColor Green
