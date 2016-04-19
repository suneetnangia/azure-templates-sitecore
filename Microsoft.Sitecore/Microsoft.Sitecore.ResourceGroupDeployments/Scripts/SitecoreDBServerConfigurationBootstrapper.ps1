param (
$localZipFilePath = "d:\sitecoresetup.zip",
$localUnzippedFilePath = "d:\sitecoresetup",
$localUnzippedDBFilesPath = ("{0}{1}" -f $localUnzippedFilePath,"\Sitecore 8.1 rev. 151207\Databases"),
$remoteSitecoreFileUrl = "https://setupstore.blob.core.windows.net/setup/Sitecore8.1rev.51207.zip",
$sqlDataFilesPath = "u:\Sitecore\SQL\Data",
$sqlLogFilesPath = "l:\Sitecore\SQL\Log",
$vmAdminUsername = "sitecoredbvmadmin",
$vmAdminPassword = "Pa55w0rd*?"
)

$user = whoami
Write-Output ("Startup Script")
Write-Output ("user: {0}" -f $user)
Write-Output ("localZipFilePath: {0}" -f $localZipFilePath)
Write-Output ("localUnzippedFilePath: {0}" -f $localUnzippedFilePath)
Write-Output ("localUnzippedDBFilesPath: {0}" -f $localUnzippedDBFilesPath)
Write-Output ("remoteSitecoreFileUrl: {0}" -f $remoteSitecoreFileUrl)
Write-Output ("sqlDataFilesPath: {0}" -f $sqlDataFilesPath)
Write-Output ("sqlLogFilesPath: {0}" -f $sqlLogFilesPath)
Write-Output ("vmAdminUsername: {0}" -f $vmAdminUsername)
Write-Output ("vmAdminPassword: {0}" -f '**************')

$password =  ConvertTo-SecureString $vmAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$vmAdminUsername", $password)
$command = "SitecoreDBServerConfiguration.ps1"

Enable-PSRemoting –force
Invoke-Command -FilePath $command -Credential $credential -ComputerName $env:COMPUTERNAME -ArgumentList $localZipFilePath, $localUnzippedFilePath, $localUnzippedDBFilesPath, $remoteSitecoreFileUrl, $sqlDataFilesPath, $sqlLogFilesPath
Disable-PSRemoting -Force