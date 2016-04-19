configuration SitecoreDBServerSetup
{ 
    param($nodeName="localhost")

    Import-DscResource –ModuleName ’PSDesiredStateConfiguration'
	Import-DSCResource -ModuleName xNetworking -ModuleVersion "2.7.0.0"
    Import-DSCResource -ModuleName xDisk -ModuleVersion "1.0"
    Import-DSCResource -ModuleName xSQLServer -ModuleVersion "1.4.0.0"
 
    Node $nodeName 
    { 
        $logDriveLetter = 'L'
        $dataDriveLetter = 'U'

        xFirewall Firewall
        { 
            Direction = "Inbound"
            Name = "SQL-Server-Database-TCP-In"
            DisplayName = "Sitecore SQL Server Database TCP In"
            Description = "Inbound rule for SQL Server to allow TCP traffic for the Database."
            Protocol = "TCP"
            LocalPort = "1433"
            Ensure = "Present"
        } 

        xWaitforDisk Disk2
        {
             DiskNumber = 2
             RetryIntervalSec = 60
             RetryCount = 60
        }

        xDisk UVolume
        {
             DiskNumber = 2
             DriveLetter = $logDriveLetter
        }

        xWaitforDisk Disk3
        {
             DiskNumber = 3
             RetryIntervalSec = 60
             RetryCount = 60
        }

        xDisk LVolume
        {
             DiskNumber = 3
             DriveLetter = $dataDriveLetter
        }

        LocalConfigurationManager
        { 
            RebootNodeIfNeeded = $true
        }
    } 
}