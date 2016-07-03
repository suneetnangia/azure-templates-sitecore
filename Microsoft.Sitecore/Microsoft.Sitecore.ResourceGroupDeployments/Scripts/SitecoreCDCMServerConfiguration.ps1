param (
[string]$remoteSitecoreFileUrl = "https://sitecore.blob.core.windows.net/setup/Sitecore8.1rev.51207.zip",
[string]$remoteLicenseFileUrl = "https://sitecore.blob.core.windows.net/setup/license.xml",
[string]$localZipFilePath = "d:\sitecoresetup.zip",
[string]$localUnzippedFilePath = "d:\sitecoresetup",
[string]$websitePath = "C:\inetpub\wwwroot\AzureSitecore\Website",
[string]$coreDBConnectionString = "user id=sitecoreUser;password=;Data Source=SitecoreDBVM;Database=Sitecore.Core",
[string]$masterDBConnectionString = "user id=sitecoreUser;password=;Data Source=SitecoreDBVM;Database=Sitecore.Master",
[string]$webDBConnectionString = "user id=sitecoreUser;password=;Data Source=SitecoreDBVM;Database=Sitecore.Web",
[string]$reportingDBConnectionString = "user id=sitecoreUser;password=;Data Source=SitecoreDBVM;Database=Sitecore.Reporting",
[string]$sessionsDBConnectionString = "user id=sitecoreUser;password=;Data Source=SitecoreDBVM;Database=Sitecore.Sessions",
[string]$macDecryption = "DES",
[string]$macDecryptionKey = "DSFSFEWR3425452FDFS",
[string]$macValidation = "HMACSHA128",
[string]$macValidationKey = "DSFGDFDFSe3432523DSAFAFAS"
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

function DownloadFile
{
	param([string]$remoteFileUrl, [string]$localFilePath)
	Invoke-WebRequest -Uri $remoteFileUrl -OutFile $localFilePath  
}

function Unzip
{
	param([string]$zipfile, [string]$outpath)
	[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Function Set-ConnectionString{
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
        [string]$fileName="C:\inetpub\wwwroot\AzureSitecore\Website\App_Config\ConnectionStrings.config",
        [string]$connectionStringName = "core",
        [string]$connectionString = "user id=sitecoreUser;password=;Data Source=SitecoreDBVM;Database=Sitecore.Core"
    )
	
	$config = [xml](Get-Content -LiteralPath $fileName)
	
    $config.Configuration.connectionStrings
    
	$connStringElement = $config.SelectSingleNode("connectionStrings/add[@name='$connectionStringName']")
    
    if($connStringElement) {
        
        $connStringElement.connectionString = $connectionString
    	
    	if($pscmdlet.ShouldProcess("$fileName","Modify config connection string")){
    		Write-Host ("Updating config connection string {0} to be {1}" -f $connectionStringName, $connectionString)
    	
    		$config.Save($fileName)
    	}
    }
    else{
        Write-Error "Unable to locate connection string named: $connectionStringName"
    }
}

Function Add-ConnectionString{
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
        [string]$fileName="C:\inetpub\wwwroot\AzureSitecore\Website\App_Config\ConnectionStrings.config",
        [string]$connectionStringName = "core",
        [string]$connectionString = "user id=sitecoreUser;password=;Data Source=SitecoreDBVM;Database=Sitecore.Sessions"
    )
	
	$config = [xml](Get-Content -LiteralPath $fileName)
	$element = $config.SelectSingleNode("connectionStrings")
    
	if($element) {
		
        $addElement = $config.CreateElement("add")
		$nameAttribute = $config.CreateAttribute("name")
		$nameAttribute.Value = "sessions"    
		$connectionStringNameAttribute = $config.CreateAttribute("connectionString")
		$connectionStringNameAttribute.Value = $connectionString            		
		$addElement.Attributes.Append($nameAttribute)
		$addElement.Attributes.Append($connectionStringNameAttribute)
		$element.AppendChild($addElement)
    
		if($pscmdlet.ShouldProcess("$fileName","Add a connection string.")){
			$config.Save($fileName)
		}
	}
	else{
		Write-Error "Unable to locate the connectionStrings node."
	}
}

Function Set-CMSMode{
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
        [string]$fileName="C:\inetpub\wwwroot\AzureSitecore\Website\App_Config\Include\Sitecore.Xdb.config",
        [string]$isEnabled = "true"
    )
	
	$config = [xml](Get-Content -LiteralPath $fileName)
    
	$element = $config.SelectSingleNode("configuration/sitecore/settings/setting[@name='Xdb.Enabled']")
    
    if($element) {
        
        $element.value = $isEnabled 
    	
    	if($pscmdlet.ShouldProcess("$fileName","Modify config")){
    		Write-Host ("Updating config {0} to be {1}" -f 'Xdb.Enabled', $isEnabled)
    	
    		$config.Save($fileName)
    	}
    }
    else{
        Write-Error "Unable to locate the Xdb setting"
    }
}

Function Set-PrivateSessionSQLProvider{
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
        [string]$fileName="C:\inetpub\wwwroot\AzureSitecore\Website\App_Config\Include\Sitecore.Xdb.config",
		[string]$connStringName="session"
    )
	
	$config = [xml](Get-Content -LiteralPath $fileName) 
	$element = $config.SelectSingleNode("configuration/system.web/sessionState[@mode='InProc']")
    
	if($element) {

		$providersElement = $config.CreateElement("providers")

		$addElement = $config.CreateElement("add")
		$nameAttribute = $config.CreateAttribute("name")
		$nameAttribute.Value = "mssql"    
		$typeAttribute = $config.CreateAttribute("type")
		$typeAttribute.Value = "Sitecore.SessionProvider.Sql.SqlSessionStateProvider, Sitecore.SessionProvider.Sql"            
		$connectionStringNameAttribute = $config.CreateAttribute("connectionStringName")
		$connectionStringNameAttribute.Value = $connStringName
		$pollingIntervalAttribute = $config.CreateAttribute("pollingInterval")
		$pollingIntervalAttribute.Value = "2"
		$compressionAttribute = $config.CreateAttribute("compression")
		$compressionAttribute.Value = "true"
		$sessionTypeAttribute = $config.CreateAttribute("sessionType")
		$sessionTypeAttribute.Value = "private"
		$addElement.Attributes.Append($nameAttribute)
		$addElement.Attributes.Append($typeAttribute)
		$addElement.Attributes.Append($connectionStringNameAttribute)
		$addElement.Attributes.Append($pollingIntervalAttribute)
		$addElement.Attributes.Append($compressionAttribute)
		$addElement.Attributes.Append($sessionTypeAttribute)

		$sqlSessionStateElement = $config.CreateElement("sessionState")
		$modeAttribute = $config.CreateAttribute("mode")
		$modeAttribute.Value = "Custom"
		$customProviderAttribute = $config.CreateAttribute("customProvider")
		$customProviderAttribute.Value = "mssql"
		$cookielessAttribute = $config.CreateAttribute("cookieless")
		$cookielessAttribute.Value = "false"
		$timeoutAttribute = $config.CreateAttribute("timeout")
		$timeoutAttribute.Value = "20"
		$sqlSessionStateElement.Attributes.Append($modeAttribute)
		$sqlSessionStateElement.Attributes.Append($customProviderAttribute)
		$sqlSessionStateElement.Attributes.Append($cookielessAttribute)
		$sqlSessionStateElement.Attributes.Append($timeoutAttribute)
    
		$sqlSessionStateElement.AppendChild($providersElement)
		$providersElement.AppendChild($addElement)

		$element.ParentNode.AppendChild($sqlSessionStateElement)
		$element.ParentNode.RemoveChild($element)
    
		if($pscmdlet.ShouldProcess("$fileName","Remove default sessionState element and add sql session provider.")){
			$config.Save($fileName)
		}
	}
	else{
		Write-Error "Unable to locate the default private session node."
	}
}

Function Set-MACKey{
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
        [string]$fileName="D:\SitecoreSetup\Sitecore 8.1 rev. 151207\Website\web.config",
		[string]$macDecryption="AES",
		[string]$macDecryptionKey="470D1F481C6389C358F1E08C3DFADDDC4AF2A498597FF894EA40A6D488EDA000",
		[string]$macValidation="HMACSHA256",
		[string]$macValidationKey="D451149B2BAC52F48B2CB88160D4189EFEAE7FEC2A83818C19F0D521412C498856498DAC52DB58B28A86A31FE024A6EEC37C720AD261372C80059D09F06C3FD4"
    )
	
	$config = [xml](Get-Content -LiteralPath $fileName) 
	$element = $config.SelectSingleNode("configuration/system.web")
    
	if($element.SelectSingleNode("machineKey")) {

		#Remove existing machine key if exist.
        Write-Information "Machine key already exist, removing it..."    
        $element.RemoveChild($element.SelectSingleNode("machineKey"))
	}
		$machineKeyElement = $config.CreateElement("machineKey")
		$decryptionAttribute = $config.CreateAttribute("decryption")
		$decryptionAttribute.Value = $macDecryption    
		$decryptionKeyAttribute = $config.CreateAttribute("decryptionKey")
		$decryptionKeyAttribute.Value = $macDecryptionKey
		$validationAttribute = $config.CreateAttribute("validation")
		$validationAttribute.Value = $macValidation
		$validationKeyAttribute = $config.CreateAttribute("validationKey")
		$validationKeyAttribute.Value = $macValidationKey
       
		$machineKeyElement.Attributes.Append($decryptionAttribute)
		$machineKeyElement.Attributes.Append($decryptionKeyAttribute)
		$machineKeyElement.Attributes.Append($validationAttribute)
		$machineKeyElement.Attributes.Append($validationKeyAttribute)

		$element.AppendChild($machineKeyElement)
    
		if($pscmdlet.ShouldProcess("$fileName","Add machine key to the web.config.")){
			$config.Save($fileName)
		}
	
}

Function Set-SharedSessionSQLProvider{
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
        [string]$fileName="C:\inetpub\wwwroot\AzureSitecore\Website\App_Config\Include\Sitecore.Xdb.config",
		[string]$connStringName="session"
    )	
	
	$config = [xml](Get-Content -LiteralPath $fileName)       
	$element = $config.SelectSingleNode("configuration/sitecore/tracking/sharedSessionState[@defaultProvider='InProc']")
    
	if($element) {

		$managerElement = $config.CreateElement("manager")
		$configElement = $config.CreateElement("config")    

		#add Element
		$addElement = $config.CreateElement("add")
		$nameAttribute = $config.CreateAttribute("name")
		$nameAttribute.Value = "mssql"    
		$typeAttribute = $config.CreateAttribute("type")
		$typeAttribute.Value = "Sitecore.SessionProvider.Sql.SqlSessionStateProvider, Sitecore.SessionProvider.Sql"            
		$connectionStringNameAttribute = $config.CreateAttribute("connectionStringName")
		$connectionStringNameAttribute.Value = $connStringName
		$pollingIntervalAttribute = $config.CreateAttribute("pollingInterval")
		$pollingIntervalAttribute.Value = "2"
		$compressionAttribute = $config.CreateAttribute("compression")
		$compressionAttribute.Value = "true"
		$sessionTypeAttribute = $config.CreateAttribute("sessionType")
		$sessionTypeAttribute.Value = "shared"
		$addElement.Attributes.Append($nameAttribute)
		$addElement.Attributes.Append($typeAttribute)
		$addElement.Attributes.Append($connectionStringNameAttribute)
		$addElement.Attributes.Append($pollingIntervalAttribute)
		$addElement.Attributes.Append($compressionAttribute)
		$addElement.Attributes.Append($sessionTypeAttribute)

		#providersElement
		$providersElement = $config.CreateElement("providers")
		$providersElement.AppendChild($addElement)

		#sharedSessionState Element
		$sqlSessionStateElement = $config.CreateElement("sharedSessionState")
		$defaultProviderAttribute = $config.CreateAttribute("defaultProvider")
		$defaultProviderAttribute.Value = "mssql"   
		$sqlSessionStateElement.Attributes.Append($defaultProviderAttribute)
    
		#managerElement    
		$descAttribute = $config.CreateAttribute("desc")
		$descAttribute.Value = "configuration"
		$refcAttribute = $config.CreateAttribute("ref")
		$refcAttribute.Value = "tracking/sharedSessionState/config"    
		$paramElement = $config.CreateElement("param")
		$paramElement.Attributes.Append($descAttribute)
		$paramElement.Attributes.Append($refcAttribute)
    
		$typeAttribute = $config.CreateAttribute("type")
		$typeAttribute.Value = "Sitecore.Analytics.Tracking.SharedSessionState.SharedSessionStateManager, Sitecore.Analytics"
		$managerElement = $config.CreateElement("manager")
		$managerElement.Attributes.Append($typeAttribute)
		$managerElement.AppendChild($paramElement)

		#configElement    
		$descAttribute = $config.CreateAttribute("desc")
		$descAttribute.Value = "maxLockAge"    
		$paramElement = $config.CreateElement("param")
		$paramElement.Attributes.Append($descAttribute)
		$paramElement.InnerText = "5000"
    
		$typeAttribute = $config.CreateAttribute("type")
		$typeAttribute.Value = "Sitecore.Analytics.Tracking.SharedSessionState.SharedSessionStateConfig, Sitecore.Analytics"
		$configElement = $config.CreateElement("config")
		$configElement.Attributes.Append($typeAttribute)
		$configElement.AppendChild($paramElement)

		$sqlSessionStateElement.AppendChild($providersElement)
		$sqlSessionStateElement.AppendChild($managerElement)
		$sqlSessionStateElement.AppendChild($configElement)

		$element.ParentNode.AppendChild($sqlSessionStateElement)
		$element.ParentNode.RemoveChild($element)
    
		if($pscmdlet.ShouldProcess("$fileName","Remove default sessionState element and add sql session provider.")){
			$config.Save($fileName)
		}
	}
	else{
		Write-Error "Unable to locate the default shared session node."
	}
}

#Download Sitecore Setup
DownloadFile $remoteSitecoreFileUrl $localZipFilePath
Unzip $localZipFilePath $localUnzippedFilePath

#Get Sitecore setup folder location
$setupLocalFolderPath = Get-ChildItem $localUnzippedFilePath | ?{ $_.PSIsContainer } | Select-Object FullName 
$setupLocalFolderPath = $setupLocalFolderPath.FullName

#Download License File
DownloadFile $remoteLicenseFileUrl "$setupLocalFolderPath\Data\License.xml"

#Update connection strings
Set-ConnectionString ("{0}\{1}" -f $setupLocalFolderPath, "\Website\App_Config\ConnectionStrings.config") "core" $coreDBConnectionString
Set-ConnectionString ("{0}\{1}" -f $setupLocalFolderPath, "\Website\App_Config\ConnectionStrings.config") "web" $webDBConnectionString
Set-ConnectionString ("{0}\{1}" -f $setupLocalFolderPath, "\Website\App_Config\ConnectionStrings.config") "master" $masterDBConnectionString
Set-ConnectionString ("{0}\{1}" -f $setupLocalFolderPath, "\Website\App_Config\ConnectionStrings.config") "reporting" $reportingDBConnectionString
Add-ConnectionString ("{0}\{1}" -f $setupLocalFolderPath, "\Website\App_Config\ConnectionStrings.config") "sessions" $sessionsDBConnectionString

#Enable CMS only mode
Set-CMSMode ("{0}\{1}" -f $setupLocalFolderPath, "\Website\App_Config\Include\Sitecore.Xdb.config") "false"

#Configure SQL Private/Shared Session Provider
Set-PrivateSessionSQLProvider ("{0}\{1}" -f $setupLocalFolderPath, "\Website\web.config") "sessions"
Set-SharedSessionSQLProvider ("{0}\{1}" -f $setupLocalFolderPath, "\Website\App_Config\Include\Sitecore.Analytics.Tracking.config") "sessions"

#Configure MAC key
Set-MACKey ("{0}\{1}" -f $setupLocalFolderPath, "\Website\web.config") $macDecryption $macDecryptionKey $macValidation $macValidationKey

#Copy to website directory
Copy-Item ("{0}\{1}" -f $setupLocalFolderPath, "\Website\*") ("{0}" -f $websitePath) -Recurse -Force
Copy-Item ("{0}\{1}" -f $setupLocalFolderPath, "\Data") ("{0}\Data" -f $websitePath) -Recurse -Force
