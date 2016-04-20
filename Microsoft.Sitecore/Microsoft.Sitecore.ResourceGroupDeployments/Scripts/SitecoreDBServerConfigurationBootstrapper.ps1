param (
$localZipFilePath,
$localUnzippedFilePath,
$localUnzippedDBFilesPath,
$remoteSitecoreFileUrl,
$sqlDataFilesPath,
$sqlLogFilesPath,
$vmAdminUsername,
$vmAdminPassword,
$sqlServerSqlLoginName,
$sqlServerSqlLoginPassword,
$sqlServerDbUsername,
$sqlServerDbRoleName
)

$password =  ConvertTo-SecureString $vmAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$vmAdminUsername", $password)
$command = "SitecoreDBServerConfiguration.ps1"

Enable-PSRemoting –force
Invoke-Command -FilePath $command -Credential $credential -ComputerName $env:COMPUTERNAME -ArgumentList $localZipFilePath, $localUnzippedFilePath, $localUnzippedDBFilesPath, $remoteSitecoreFileUrl, $sqlDataFilesPath, $sqlLogFilesPath, $sqlServerSqlLoginName, $sqlServerSqlLoginPassword, $sqlServerDbUsername, $sqlServerDbRoleName
Disable-PSRemoting -Force