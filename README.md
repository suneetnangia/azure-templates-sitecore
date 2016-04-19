# Azure Sitecore Templates
Azure template(s) for Sitecore on Azure.

This template will deploy Sitecore 8.1 in CMS only mode.

Following resources are created by the template-
1. Content Delivery and Management role on two(configurable) VMs
2. SQL Server on a VM

The template will download and deploy Sitecore 8.1 from the user provided URLs.
User will need to provide two URLs-
1. license.xml URL
2. sitecore zip file URL.
It is advisable to use the secure SAS urls for the above two.
To learn about creating secure SAS urls please see this

Please note this is a work in progress and sone of the features in the pipeline are-
1. SQL AlwaysOn
2. MongoDB Cluster
3. Content Delivery/Management Role Split
4. Better Network/Security Design

MICROSOFT MAKES NO WARRANTIES, EXPRESS, IMPLIED, OR STATUTORY, BY POSTING SUCH DOCUMENTS OR ABOUT THE INFORMATION IN SUCH DOCUMENTS.
