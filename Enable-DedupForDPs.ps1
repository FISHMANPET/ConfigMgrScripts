if ((Get-WindowsFeature fs-data-deduplication -ErrorAction Stop).InstallState -ne "Installed") {
    $result = Install-WindowsFeature fs-data-deduplication -ErrorAction Stop
    if ($result.RestartNeeded -eq "Yes") {
        Write-Host "Reboot needed, reboot and rerun this script"
        return
    }
}

$drives = Get-Volume | Where-Object {$_.DriveType -eq "Fixed"}
$sccmdrives = @()
foreach ($drive in $drives) {
    if (-not (test-path "$($drive.DriveLetter):\NO_SMS_ON_DRIVE.SMS")) {
        $sccmdrives += $drive
    }
}
$deduped = Get-DedupVolume
foreach ($drive in $sccmdrives) {
    if ($deduped | Where-Object {$_.volume -eq "$($drive.DriveLetter):"}) {
        Write-Host "$($drive.DriveLetter):\ is already deduped"
    } else {
        [string[]]$dedupexludes =@()
        [string[]]$exclude = @("SCCMContentLib","SMSPKG$($drive.DriveLetter)`$","`$RECYCLE.BIN","System Volume Information")
        foreach ($folder in Get-ChildItem -Path "$($drive.DriveLetter):\" -Attributes D+H, D -Exclude $exclude -Name) {
            $dedupexludes += "$($drive.DriveLetter):\$folder"
        }
        Write-Host "Deduping $($drive.DriveLetter):\"
        Enable-DedupVolume -Volume "$($drive.DriveLetter):" -UsageType Default
        Set-DedupVolume -Volume "$($drive.DriveLetter):" -MinimumFileAgeDays 1 -ExcludeFolder $dedupexludes
    }
}

