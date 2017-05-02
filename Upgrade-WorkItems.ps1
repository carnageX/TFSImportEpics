<#
.SYNOPSIS
 
Author: Chase Bennett
Inspired by: Colin Dembovsky (http://colinsalmcorner.com)
Manual executions: https://blogs.msdn.microsoft.com/tfssetup/2015/09/16/configuring-the-epics-for-upgraded-team-projects-in-team-foundation-server-tfs-2015/ 

Updates 2013 Templates to 2015/2017 base templates, including addition of Epic Backlog.
 
 
.DESCRIPTION
 
Adds SAFe support to the base templates. This involves adding the Epic work item (along with its backlog and color settings).
 
This isn't fully tested, so there may be issues depending on what customizations of the base templates you have already made. The script attempts to add in values, so it should work with your existing customizations.
 
To execute this script, first download the Agile, Scrum or CMMI template from the Process Template Manager in Team Explorer. You need the Epic.xml file for this script. 

To download the process template(s), see this link: https://www.visualstudio.com/en-us/docs/work/guidance/manage-process-templates 
 
.PARAMETER baseUrl
 
The TFS base URL; defaults to http://tfs:8080/tfs

.PARAMETER collection
 
The Team Project Collection
 
.PARAMETER project
 
The name of the Team Project to ugprade
 
.PARAMETER baseTemplate
 
The name of the base template. Must be Agile, Scrum or CMMI
 
.PARAMETER pathToEpic
 
The path to the WITD xml file for the Epic work item
 
.PARAMETER layoutGroupToAddValueAreaControlTo
 
The name of the control group to add the Value Area field to in the FORM - defaults to 'Classification' (Agile), 'Details' (SCRUM) and '' (CMMI). Leave this as $null unless you've customized your form layout.
 
.PARAMETER pathToWitAdmin
 
The path to witadmin.exe. Defaults to 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\witadmin.exe or C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\witadmin.exe'
 
.PARAMETER exportDirectory
 
Working directory to export XML files to; defaults to <current directory>\Exports

.EXAMPLE

Upgrade-WorkItems -collection "DefaultCollection" -project "TestProject" -baseTemplate "Scrum" -pathToEpic "C:\TFS\Scrum\WorkItem Tracking\TypeDefinitions\Epic.xml" 


 
#>
 
param(
    [string]$baseUrl = 'http://tfs:8080/tfs',

    [Parameter(Mandatory=$true)]
    [string]$collection,
 
    [Parameter(Mandatory=$true)]
    [string]$project,
 
    [Parameter(Mandatory=$true)]
    [ValidateSet("Agile", "Scrum", "CMMI")]
    [string]$baseTemplate,
 
    [Parameter(Mandatory=$true)]
    [string]$pathToEpic,
 
    [string]$layoutGroupToAddValueAreaControlTo = $null,
 
    [string]$pathToWitAdmin = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\witadmin.exe',

    [string]$exportDirectory = '.\Exports'
)
 
if (-not (Test-Path $pathToEpic)) {
    Write-Error "Epic WITD not found at $pathToEpic"
    exit 1
}
 
if ((Get-Alias -Name witadmin -ErrorAction SilentlyContinue) -eq $null) {
    New-Alias witadmin -Value $pathToWitAdmin
}

if(-not (Test-Path $pathToWitAdmin)) {
    # Fallback to VS 2015's directory for WitAdmin.exe 
    $pathToWitAdmin = 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\witadmin.exe'
    if(-not(Test-Path $pathToWitAdmin)) {
        Write-Error "WITAdmin.exe not found at $pathToWitAdmin"
        exit 1
    }
}
Write-Host "Using WitAdmin.exe from: $pathtoWitAdmin" -ForegroundColor Cyan

$fullExportPath = (resolve-path $exportDirectory).Path
if(-not (Test-Path $exportDirectory)) {
    Write-Host "Creating working/export directory at $fullExportPath" -ForegroundColor Cyan
    New-Item $exportDirectory -ItemType Directory
}

$tpcUri = "$baseUrl/$collection"
$tpcUri = [uri]::EscapeUriString($tpcUri)

$valueAreadFieldXml = '
<FIELD name="Value Area" refname="Microsoft.VSTS.Common.ValueArea" type="String">
<REQUIRED />
<ALLOWEDVALUES>
<LISTITEM value="Architectural" />
<LISTITEM value="Business" />
</ALLOWEDVALUES>
<DEFAULT from="value" value="Business" />
<HELPTEXT>Business = delivers value to a user or another system; Architectural = work to support other stories or components</HELPTEXT>
</FIELD>'
$valueAreaFieldFormXml = '<Control FieldName="Microsoft.VSTS.Common.ValueArea" Type="FieldControl" Label="Value area" LabelPosition="Left" />'
 
$epicCategoryXml = '
<CATEGORY name="Epic Category" refname="Microsoft.EpicCategory"><DEFAULTWORKITEMTYPE name="Epic" /></CATEGORY>'

$epicBacklogXml = ''

$epicBacklogXmlAgile = '
<PortfolioBacklog category="Microsoft.EpicCategory" pluralName="Epics" singularName="Epic" workItemCountLimit="1000">
<States>
<State value="New" type="Proposed" />
<State value="Active" type="InProgress" />
<State value="Resolved" type="InProgress" />
<State value="Closed" type="Complete" />
</States>
<Columns>
<Column refname="System.WorkItemType" width="100" />
<Column refname="System.Title" width="400" />
<Column refname="System.State" width="100" />
<Column refname="Microsoft.VSTS.Scheduling.Effort" width="50" />
<Column refname="Microsoft.VSTS.Common.BusinessValue" width="50" />
<Column refname="Microsoft.VSTS.Common.ValueArea" width="100" />
<Column refname="System.Tags" width="200" />
</Columns>
<AddPanel>
<Fields>
<Field refname="System.Title" />
</Fields>
</AddPanel>
</PortfolioBacklog>'

$epicBacklogXmlScrum = '
    <PortfolioBacklog category="Microsoft.EpicCategory" pluralName="Epics" singularName="Epic" workItemCountLimit="1000">
      <States>
        <State value="New" type="Proposed" />
        <State value="In Progress" type="InProgress" />
        <State value="Done" type="Complete" />
      </States>
      <Columns>
        <Column refname="System.WorkItemType" width="100" />
        <Column refname="System.Title" width="400" />
        <Column refname="System.State" width="100" />
        <Column refname="Microsoft.VSTS.Scheduling.Effort" width="50" />
        <Column refname="Microsoft.VSTS.Common.BusinessValue" width="50" />
        <Column refname="Microsoft.VSTS.Common.ValueArea" width="100" />
        <Column refname="System.Tags" width="200" /></Columns><AddPanel><Fields><Field refname="System.Title" /></Fields></AddPanel></PortfolioBacklog>'

$epicBacklogXmlCmmi = '
    <PortfolioBacklog category="Microsoft.EpicCategory" pluralName="Epics" singularName="Epic" workItemCountLimit="1000">
      <States>
        <State value="Proposed" type="Proposed" />
        <State value="Active" type="InProgress" />
        <State value="Resolved" type="InProgress" />
        <State value="Closed" type="Complete" />
      </States>
      <Columns>
        <Column refname="System.WorkItemType" width="100" />
        <Column refname="System.Title" width="400" />
        <Column refname="System.State" width="100" />
        <Column refname="Microsoft.VSTS.Scheduling.Effort" width="50" />
        <Column refname="Microsoft.VSTS.Common.BusinessValue" width="50" />
        <Column refname="Microsoft.VSTS.Common.ValueArea" width="100" />
        <Column refname="System.Tags" width="200" />
      </Columns>
      <AddPanel>
        <Fields>
          <Field refname="System.Title" />
        </Fields>
      </AddPanel>
    </PortfolioBacklog>'

$epicColorXml = '<WorkItemColor primary="FFFF7B00" secondary="FFFFD7B5" name="Epic" />'

$hiddenBacklogPropertyFull = '
<Properties> 
<Property name="BugsBehavior" value="AsRequirements" /> 
<Property name="HiddenBacklogs" value="Microsoft.EpicCategory" /> 
</Properties>'


#####################################################################

function Add-Fragment([System.Xml.XmlNode]$node, [string]$xml) {
    $newNode = $node.OwnerDocument.ImportNode(([xml]$xml).DocumentElement, $true)
    [void]$node.AppendChild($newNode)
}

#####################################################################

Write-Host "Importing $pathToEpic to $project" -ForegroundColor Cyan
witadmin importwitd /collection:$tpcUri /p:$project /f:$pathToEpic

Write-Host "Exporting $project to $exportDirectory\categories.xml" -ForegroundColor Cyan
witadmin exportcategories /collection:$tpcUri /p:$project /f:"$exportDirectory\categories.xml"

$catXml = [xml](gc "$exportDirectory\categories.xml")
if (($catXml.CATEGORIES.ChildNodes | ? { $_.name -eq "Epic Category" }) -ne $null) {
    Write-Host "Epic category already exists...skipping" -ForegroundColor Yellow
} else {
    Write-Host "Updating $exportDirectory\categories.xml" -ForegroundColor Cyan
    Add-Fragment -node $catXml.CATEGORIES -xml $epicCategoryXml
    $catXml.Save((gi "$exportDirectory\categories.xml").FullName)
    
    Write-Host "Importing $exportDirectory\categories.xml to $project" -ForegroundColor Cyan
    witadmin importcategories /collection:$tpcUri /p:$project /f:"$exportDirectory\categories.xml"
}

Write-Host "Exporting ProcessConfiguration for $project to $exportDirectory\ProcessConfiguration.xml" -ForegroundColor Cyan
witadmin exportprocessconfig /collection:$tpcUri /p:$project /f:"$exportDirectory\ProcessConfiguration.xml"

$procXml = [xml](gc "$exportDirectory\ProcessConfiguration.xml")
switch ($baseTemplate) {
        "Agile" { $epicBacklogXml = $epicBacklogXmlAgile }
        "Scrum" { $epicBacklogXml = $epicBacklogXmlScrum }
        "CMMI"  { $epicBacklogXml = $epicBacklogXmlCmmi }
}

Write-Host "Adding Epic Backlog XML to ProcessConfig" -ForegroundColor Cyan
if (($procXml.ProjectProcessConfiguration.PortfolioBacklogs.PortfolioBacklog | ? { $_.category -eq "Microsoft.EpicCategory" }) -ne $null) {
    Write-Host "Epic Backlog XML already exists...skipping" -ForegroundColor Yellow
} else {
    Add-Fragment -node $procXml.ProjectProcessConfiguration.PortfolioBacklogs -xml $epicBacklogXml
}

Write-Host "Adding Epic Color XML" -ForegroundColor Cyan
if (($procXml.ProjectProcessConfiguration.WorkItemColors.ChildNodes | ? { $_.name -eq "Epic" }) -ne $null) {
    Write-Host "Epic color already exists...skipping" -ForegroundColor Yellow
} else {
    Add-Fragment -node $procXml.ProjectProcessConfiguration.WorkItemColors -xml $epicColorXml
}

Write-Host "Adding EpicCategory parent to FeatureCategory" -ForegroundColor Cyan
$featureCat = $procXml.ProjectProcessConfiguration.PortfolioBacklogs.PortfolioBacklog | ? { $_.category -eq "Microsoft.FeatureCategory" }
if (($featureCat | ? { $_.parent -eq "Microsoft.EpicCategory" }) -ne $null) { 
    Write-Host "Epic parent already exists...skipping" -ForegroundColor Yellow
} else {
    $parentAttrib = $featureCat.OwnerDocument.CreateAttribute("parent")
    $parentAttrib.Value = "Microsoft.EpicCategory"
    $featureCat.Attributes.Append($parentAttrib)
}

if ($procXml.ProjectProcessConfiguration.SelectSingleNode('Properties')) {
    Write-Host "Adding HiddenBacklogs EpicCategory" -ForegroundColor Cyan
    
    if (($procXml.ProjectProcessConfiguration.Properties.Property | ? { $_.value -eq "Microsoft.EpicCategory" }) -ne $null) {
        Write-Host "HiddenBacklogs already exists...skipping" -ForegroundColor Yellow
    } else {
        Add-Fragment -node $procXml.ProjectProcessConfiguration.Properties -xml '<Property name="HiddenBacklogs" value="Microsoft.EpicCategory" />'    
    }

} else {
    Write-Host "Adding Full Properties"
    Add-Fragment -node $procXml.ProjectProcessConfiguration -xml $hiddenBacklogPropertyFull
}

$procXml.Save((gi "$exportDirectory\ProcessConfiguration.xml").FullName)

Write-Host "Importing $exportDirectory\ProcessConfiguration.xml to $project" -ForegroundColor Cyan
witadmin importprocessconfig /collection:"$tpcUri" /p:$project /f:"$exportDirectory\ProcessConfiguration.xml"
 
Write-Host "Done!" -ForegroundColor Green