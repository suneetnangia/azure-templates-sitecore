configuration SitecoreCMCDServerSetup
{ 
 param($nodeName="localhost", $sitecoreAppPoolName = "SitecoreAppPool", $sitecoreWebsiteName = "AzureSitecore")

    Import-DscResource -ModuleName cNtfsAccessControl -ModuleVersion "1.2.0"
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName xWebAdministration -ModuleVersion "1.10.0.0"
	Import-DscResource -ModuleName xComputerManagement -ModuleVersion "1.10.0.0"
	Import-DscResource -ModuleName cWSUS -ModuleVersion "1.10.0.0"

    Node $nodeName
    {
		cWSUSUpdateMode WSUSMode {
            Mode = "Notify"
        }

        WindowsFeature SetupIIS {
            Ensure = "Present"
            Name = "Web-Server"           
        }

		WindowsFeature IISManagementTools {
			Ensure = "Present" 
			Name = "Web-Mgmt-Tools" 
			IncludeAllSubFeature = $false
			DependsOn  = "[WindowsFeature]SetupIIS"
		}

        WindowsFeature AspNet45 
        { 
            Ensure          = "Present"
            Name            = "Web-Asp-Net45" 
        } 

       xWebAppPool SitecoreAppPool 
       {
			Name  = $sitecoreAppPoolName
			Ensure = "Present"
			managedPipelineMode = "Integrated"
			managedRuntimeVersion = "v4.0"
			maxProcesses = 1
			identityType = "ApplicationPoolIdentity"
			loadUserProfile = $true
			State  = "Started"
			startMode = "AlwaysRunning"
			idleTimeout = 0
			DependsOn  = "[WindowsFeature]SetupIIS" 
       }
		 
       xWebsite DefaultSite
       {
           Ensure          = "Present"
           Name            = "Default Web Site"
           State           = "Stopped"
           PhysicalPath    = "C:\inetpub\wwwroot"
           DependsOn       = "[WindowsFeature]SetupIIS"
       }

        File CreateDirectory
        {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = "C:\inetpub\wwwroot\$sitecoreWebsiteName\Website"
        }

        cNtfsPermissionEntry PermissionSet
        {
            Ensure = "Present"
            Path = "C:\inetpub\wwwroot\$sitecoreWebsiteName"
            Principal = "IIS AppPool\$sitecoreAppPoolName"
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
            DependsOn = '[File]CreateDirectory'
        }

		Group UserGroup{
		  GroupName = "Performance Monitor Users"
		  Ensure = "Present"
		  MembersToInclude = "IIS AppPool\$sitecoreAppPoolName"
		  DependsOn = '[xWebAppPool]SitecoreAppPool'
		}
        
		xWebsite SitecoreWebSite  
        { 
            Ensure          = "Present" 
			ApplicationPool = $sitecoreAppPoolName
            Name            = $sitecoreWebsiteName
            State           = "Started" 
            PhysicalPath    = "C:\inetpub\wwwroot\$sitecoreWebsiteName\Website"
            DependsOn       = @('[xWebAppPool]SitecoreAppPool', '[xWebsite]DefaultSite')
        } 

        LocalConfigurationManager 
        { 
            RebootNodeIfNeeded = $true 
        }
    } 
}