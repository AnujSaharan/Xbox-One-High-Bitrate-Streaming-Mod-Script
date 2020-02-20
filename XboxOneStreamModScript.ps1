# Xbox One Console Companion App Mod Script for High Bitrate Streaming
# XboxOneStreamModScript.ps1

# Requires the Xbox and Xbox Console Companion Apps to function
# Supported Operating Systems: Windows 10
# Tested on Windows 10 Build 1904

Try {
    # --------------------------- PRELIMINARY ERROR CHECKING CODE --------------------------- #
    # Script termination
    function TerminateScript ([string]$explanation) {
        Write-Host -ForegroundColor Red $explanation
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        exit
    }

    # Verify if two given files are the same
    # Used to replace the config file, and then used again to replace with default config upon exit
    function VerifyFileCopy ($file1, $file2, $filetype) {
        $VerificationList = Compare-Object $file1 $file2 | Select-Object SideIndicator
        If ($VerificationList) {
            TerminateScript "ERROR: Verification failed. Unable to copy $filetype file. File formatted incorrectly."        
        }
        else {
            Write-Host -ForegroundColor Green "$filetype verified successfully. Replacing with the modded version."
        }
    }

    # Ensure the Xbox App isn't already running
    # Terminate the script if unable to start    
    If (Get-Process -Name XboxApp -ErrorAction SilentlyContinue) {
        $XboxProcess = Get-Process -Name XboxApp
        $XboxProcessThreads = $XboxProcess.Threads | Select-Object WaitReason | % { $_ -match "Suspended" }
        If (!($XboxProcessThreads -contains $true)) {
            TerminateScript "ERROR: Unable to start the script. Please exit the Xbox App and try again."        
        } 
    }


    # Ensure the App Settings file was found
    # Terminate the script if the file is not present
    $XboxConfigPath = $env:LOCALAPPDATA + "\Packages\" + (Get-AppxPackage -Name "Microsoft.XboxApp" | Select -ExpandProperty Name) + "_" + (Get-AppxPackage -Name "Microsoft.XboxApp" | Select -ExpandProperty PublisherId) + "\LocalState\settings.json"
    if (!(Test-Path -Path $XboxConfigPath )) {
        TerminateScript "ERROR: Unable to find the Xbox Console Companion App Settings file. Please log in to the Xbox app with your credentials and try again after streaming directly from the app."
    }

    # Terminate if the config file does not match our version
    # Ensure "GAME_STREAMING_VERY_HIGH_QUALITY_SETTINGS" exists in the default config file
    $XboxConfigFile = Get-Content $XboxConfigPath
    $XboxConfigFileCorrupted = $XboxConfigFile -match "GAME_STREAMING_VERY_HIGH_QUALITY_SETTINGS[`"][:][`"](\d+)[,]\d+[,](\d+)[,]"
    If (!($XboxConfigFileCorrupted -contains $true)) {
        TerminateScript "ERROR: The App Settings file detected seems to have a different structure than the modded version. The script will now exit."        
    }


    # Ensure the default config file was found
    # Terminate the script if the file is not present
    $ConfigPath = $PSScriptRoot + "\config.xml"
    if (!(Test-Path -Path $ConfigPath )) {
        TerminateScript "Unable to find the config.xml file. The script will now exit."
    }


    # Ensure the format of config.xml matches the current Microsoft version
    # Terminate the script if it does not
    try {
        $ConfigFile = [XML](Get-Content -ErrorAction SilentlyContinue $ConfigPath)
    }
    catch {
        if ($_) {
            TerminateScript "The modded version of config.xml seems to formatted incorrectly. Please ensure the format matches the default file."
        }
    }
    # --------------------------- PRELIMINARY ERROR CHECKING CODE --------------------------- #

    # Copy variables from the default config file
    $HostsBlocker = $ConfigFile.settings.hostsblocker
    $QualitySetting = $ConfigFile.settings.quality
    $DisplayResolution = $ConfigFile.settings.resolution
    $FrameRate = $ConfigFile.settings.framerate


    # Ensure the validity of parameters in config.xml
    # Terminate the script if it does not
    If (!$HostsBlocker -or !$QualitySetting -or !$FrameRate) {
        TerminateScript "Invalid configuration found. Please ensure the values are supported and try again."
    }

    # Check host file to ensure the blocker has been added
    # Add blocker to hosts file if not already present
    $HostsPath = $env:SystemRoot + "\System32\Drivers\etc\hosts"
    $HostsBackupPath = $PSScriptRoot + "\hosts.bak"
    $HostsFile = Get-Content $HostsPath
    $HostsBlockerToAppend = "`r`n" + $HostsBlocker
    $HostsBlockerPresent = $HostsFile | % { $_ -match "^$HostsBlocker" }
    if ($HostsBlockerPresent -contains $true) {
        Write-Host -ForegroundColor Yellow "SUCCESS: Host file already modified. Skipping adding blocker to host file."
    }
    else {
        Write-Host -NoNewLine "Creating a backup of default host file."
        Copy-Item -ErrorAction Stop $HostsPath -Destination $HostsBackupPath
        Write-Host -ForegroundColor Green "SUCCESS"
        VerifyFileCopy (Get-Content $HostsPath) (Get-Content $HostsBackupPath) "Host File backup"
        Write-Host -NoNewLine "Adding `"$HostsBlocker`" to hosts file"
        Add-Content -ErrorAction Stop -Value $HostsBlockerToAppend -Path $HostsPath
        Write-Host -ForegroundColor Green "SUCCESS"
    }


    # Backup Xbox App Settings File
    Write-Host -NoNewLine "Creating a backup of deafult Xbox App Settings file - "
    $XboxConfigBackupPath = $PSScriptRoot + "\settings.json.bak"
    Copy-Item -ErrorAction Stop $XboxConfigPath -Destination $XboxConfigBackupPath
    Write-Host -ForegroundColor Green "SUCCESS"
    VerifyFileCopy (Get-Content $XboxConfigPath) (Get-Content $XboxConfigBackupPath) "Xbox App Settings backup"


    # Lambda to find and replace corresponding settings in config.xml
    # Replace "GAME_STREAMING_VERY_HIGH_QUALITY_SETTINGS" in the config file
    Write-Host -NoNewLine "Modding stock config file with Bitrate = $QualitySetting, Resolution = $DisplayResolution, Framerate = $FrameRate "
    $XboxConfigFile = $XboxConfigFile -replace "GAME_STREAMING_VERY_HIGH_QUALITY_SETTINGS[`"][:][`"](\d+)[,]\d+[,](\d+)[,]", ("GAME_STREAMING_VERY_HIGH_QUALITY_SETTINGS`":`"" + $QualitySetting + "000000,$DisplayResolution,$FrameRate,")
    [IO.File]::WriteAllLines($XboxConfigPath, $XboxConfigFile)
    Write-Host -ForegroundColor Green "SUCCESS"


    # Launch Xbox Streaming
    # Wait till the app exits to initiate backup restoring procedures
    start xbox:
    Write-Host "Launching Xbox Console Companion. The script will now wait for the app to exit."
    While (Get-Process -Name XboxApp -ErrorAction SilentlyContinue) {
        Start-Sleep -Seconds 1

    }
    Write-Host "Xbox Console Companion exited successfully"

    # Restore default Hosts file
    if (!($HostsBlockerPresent -contains $true)) {
        Write-Host -NoNewLine "Restoring default hosts file "
        $HostsFile = Get-Content $HostsBackupPath
        [IO.File]::WriteAllLines($HostsPath, $HostsFile)
        Write-Host -ForegroundColor Green "SUCCESS"
        VerifyFileCopy (Get-Content $HostsBackupPath) (Get-Content $HostsPath) "Hosts"
        Write-Host -NoNewLine "Removing redundant backup "
        Remove-Item -ErrorAction Stop $HostsBackupPath
        Write-Host -ForegroundColor Green "SUCCESS"
    }


    # Restore default App Settings file
    Write-Host -NoNewLine "Restoring default Xbox App Settings file "
    $XboxConfigFile = Get-Content $XboxConfigBackupPath
    [IO.File]::WriteAllLines($XboxConfigPath, $XboxConfigFile)
    Write-Host -ForegroundColor Green "SUCCESS"
    VerifyFileCopy (Get-Content $XboxConfigBackupPath) (Get-Content $XboxConfigPath) "Xbox App Settings"
    Write-Host -NoNewLine "Removing redundant backup "
    Remove-Item -ErrorAction Stop $XboxConfigBackupPath
    Write-Host -ForegroundColor Green "SUCCESS"


    Write-Host "Script ended gracefully. Exiting now."
    Start-Sleep -Seconds 2

}
Catch {
    Write-Host -ForegroundColor Red "The script encountered an error. Please check XboxStreamLog.txt" 
    $_ | Out-File ($PSScriptRoot + "\XboxStreamLog.txt")
}