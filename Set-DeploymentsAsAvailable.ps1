

Param(
    [Parameter(Mandatory)]
    [string]$deploymentBaseFilter,

    [Parameter(Mandatory)]
    [string]$collectionBaseFilter,

    [string]$deploymentDate = $(get-date -Format yyyy-MM)
)


Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
$SiteCode = "" # Site code goes here
$SiteServer = "" # SMS Provider machine name goes here

if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer
}


Push-Location $SiteCode`: # Set the current location to be the site code.

$deploymentfilter = "$deploymentBaseFilter $deploymentDate*"
$sugNames = (Get-CMSoftwareUpdateGroup -Name $deploymentfilter).LocalizedDisplayName
$availableCollections = Get-CMDeviceCollection -Name $collectionBaseFilter


foreach ($sug in $sugNames) {
    $deployments = Get-CMSoftwareUpdateDeployment -Name $sug
    $availableDeployment = ($deployments | Where-Object {$_.TargetCollectionID -in $availableCollections.CollectionID})
    $params = @{
        SoftwareUpdateGroupName = $sug
        DeploymentName = $availableDeployment.AssignmentName
        CollectionID = $availableDeployment.TargetCollectionID
        DeploymentType = "Available"
        Enable = $True
    }
    Set-CMSoftwareUpdateDeployment @params
}

Pop-Location