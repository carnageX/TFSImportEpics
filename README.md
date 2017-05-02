# Synopsis
Inspired by: Colin Dembovsky (http://colinsalmcorner.com)

Manual executions: https://blogs.msdn.microsoft.com/tfssetup/2015/09/16/configuring-the-epics-for-upgraded-team-projects-in-team-foundation-server-tfs-2015/ 

Updates 2013 Templates to 2015/2017 base templates, including addition of Epic Backlog. 
 
# Description
 
Adds SAFe support to the base templates. This involves adding the Epic work item (along with its backlog and color settings).
 
This isn't fully tested, so there may be issues depending on what customizations of the base templates you have already made. The script attempts to add in values, so it should work with your existing customizations.
 
To execute this script, first download the Agile, Scrum or CMMI template from the Process Template Manager in Team Explorer. You need the Epic.xml file for this script. 

To download the process template(s), see this link: https://www.visualstudio.com/en-us/docs/work/guidance/manage-process-templates 

# Prerequisites
Some prerequisites for running the script:
- PowerShell 3.0 (for running the script) - https://www.microsoft.com/en-us/download/details.aspx?id=34595 
- For downloading the process templates & other administration tasks: 
  - Visual Studio 2017  OR 
  - Team Explorer 2017 (available [here](https://www.visualstudio.com/thank-you-downloading-visual-studio/?sku=TeamExplorer&rel=15) )
- TFS Admin access
