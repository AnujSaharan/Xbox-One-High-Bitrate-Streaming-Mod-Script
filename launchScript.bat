@echo off

REM Xbox One Console Companion App Mod Script for High Bitrate Streaming
REM launchScript.bat

echo Xbox One Console Companion App Mod Script
echo:
fsutil dirty query %systemdrive% > nul

REM Return an error if the script is not run in administrator mode
if not %errorlevel% == 0 (
	echo:
    echo ERROR: Administrator privileges not detected. 
	echo Please Shift+Right-Click and 'Run as administrator' to continue.
	echo:
	pause
	exit
)

REM Revert to local directory after the script is run in administrator mode
@setlocal enableextensions
@cd /d "%~dp0"

REM Launch the Mod Script
powershell.exe -File "./XboxOneStreamModScript.ps1"