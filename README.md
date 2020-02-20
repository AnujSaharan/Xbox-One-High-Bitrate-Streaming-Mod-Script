# Xbox One Console Companion App Mod Script for High Bitrate Streaming

The following is a __Windows Powershell__ script to replace the Xbox Companion App config file with a modified version to achieve higher bitrates for Xbox One Streaming on Windows 10.

## Instructions

1. Set your desired bitrate, resolution, and framerate in config.xml.
2. Run 'launchScript.bat' with administrator privileges.
3. Follow on-screen instructions.

__NOTE__: Do not force stop the script while it's running. The script exits automatically when the Xbox Console Companion app is closed. It attempts to replace the original config file for the Xbox Console Companion App upon exit.

### Supported Configurations for config.xml

- Bitrate: Expressed as a value between 10 and 90

- Resolutions: 480P, 720P, 1080P

- Framerate: 30FPS, 60FPS
