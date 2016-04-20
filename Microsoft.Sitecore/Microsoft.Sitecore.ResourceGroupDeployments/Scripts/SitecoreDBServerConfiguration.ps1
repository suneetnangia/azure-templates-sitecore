param (
$localZipFilePath,
$localUnzippedFilePath,
$localUnzippedDBFilesPath,
$remoteSitecoreFileUrl,
$sqlDataFilesPath,
$sqlLogFilesPath,
$sqlLoginName,
$sqlPassword,
$dbUserName,
$dbRoleName
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$user = whoami

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

DownloadFile $remoteSitecoreFileUrl $localZipFilePath
Unzip $localZipFilePath $localUnzippedFilePath

New-Item -ItemType Directory -Path $sqlDataFilesPath -Force
New-Item -ItemType Directory -Path $sqlLogFilesPath -Force
Copy-Item ("{0}\{1}" -f $localUnzippedDBFilesPath, "*.mdf") $sqlDataFilesPath -Force
Copy-Item ("{0}\{1}" -f $localUnzippedDBFilesPath, "*.ldf") $sqlLogFilesPath -Force

Write-Output ("Checking Files in {0}" -f $sqlDataFilesPath)
	
Import-Module SQLPS -DisableNameChecking

$server = new-object Microsoft.SqlServer.Management.Smo.Server("(local)")

# Change Auth to Mixed Mode and Restart SQL Server
$server.Settings.LoginMode = [Microsoft.SqlServer.Management.SMO.ServerLoginMode]::Mixed
$server.Alter()
Restart-Service MSSQLSERVER -Force

# Create DB User for Sitecore
$login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $server, $sqlLoginName
$login.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::SqlLogin
$login.PasswordExpirationEnabled = $false
$login.Create($sqlPassword)

# loop through each  of the file
foreach ($file in Get-ChildItem $sqlDataFilesPath)
{
	if ($file.Extension -eq '.mdf')
	{
		Write-Output ("Need to attach database {0}" -f $file.FullName)

		# attach the databases
		$dbfiles = New-Object System.Collections.Specialized.StringCollection

		$dbfiles.Add($file.FullName) | Out-Null

		#get database name (TODO: Use Sitecore instance name as prefix for DB name)
		$dbname = $file.BaseName

		# get log file, assuming same basename as mdf
		$logfile = $sqlLogFilesPath + "\"+ $file.BaseName + ".ldf"
		$dbfiles.Add($logfile) | Out-Null

		Write-output ("Attaching as database {0}, from mdf {1} and ldf {2}" -f $dbname, $file.FullName, $logfile)

		try
		{
			# Attach DB
			$server.AttachDatabase($dbname, $dbfiles)

			#Assign User Access
            $database = $server.Databases[$dbname]
            $dbUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User -ArgumentList $database, $dbUserName
            $dbUser.Login = $loginName
            $dbUser.Create()
            Write-Host("User $dbUser created successfully.")

            #assign database role for a new user
            $dbrole = $database.Roles[$dbRoleName]
            $dbrole.AddMember($dbUserName)
            $dbrole.Alter()
            Write-Host("User $dbUser successfully added to $roleName role.")
		}
		catch
		{
			Write-Output $_.exception;
			$error[0]|format-list -force
		}

	#end if - check extension
	}

#end loop through files
}