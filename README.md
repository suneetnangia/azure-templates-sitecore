# Azure Sitecore Templates
Azure template(s) for Sitecore on Azure.

This template will deploy Sitecore 8.1 in CMS only mode.

Following resources are created by the template-
- Content Delivery and Management role on two(configurable) VMs
- SQL Server on a VM

The template will download and deploy Sitecore 8.1 from the user provided URLs.
User will need to provide two URLs-
- license.xml URL
- sitecore zip file URL.

**It is highly advisable to use the secure SAS urls for the above two.**

To learn about creating secure SAS urls please see the video tutorial here (@ 2:40)-
http://storageexplorer.com/

Please note this is a work in progress and some of the features in the pipeline are-
- SQL AlwaysOn
- MongoDB Cluster
- Content Delivery/Management Role Split
- Better Network/Security Design

MICROSOFT MAKES NO WARRANTIES, EXPRESS, IMPLIED, OR STATUTORY, BY POSTING SUCH DOCUMENTS OR ABOUT THE INFORMATION IN SUCH DOCUMENTS.
