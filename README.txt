================================================================================
  Windows Clock Alarm Auto-Shutoff Utility (v1.6.1)
  Zero-Dependency, Smart App Control Compliant, Native Windows 11 Background Tool
================================================================================

OVERVIEW
--------------------------------------------------------------------------------
The default Windows Clock app (Alarms & Clock) provides no built-in auto-shutoff
feature. Alarms and countdown timers loop continuous audio and display banners
indefinitely until manually dismissed.

This utility runs invisibly in the background, automatically turning off ringing
alarms and countdown timers after a configurable duration.

KEY FEATURES
--------------------------------------------------------------------------------
* 100% Invisible Background Service (PowerShell-hosted, Smart App Control verified).
* Ultra-Low Footprint: Uses Windows 11 EcoQoS (Efficiency Mode) and memory compaction
  consuming only ~5.5MB to 16MB RAM and 0% CPU.
* Optional Smart Idle Gating: Defers auto-shutoff up to 60s while actively typing or moving your mouse.
* Differentiated Limits: Independent thresholds for wake-up alarms (default 5 min)
  and countdown timers (default 1 min).
* Silent Notification Center Reminders: Posts a quiet reminder in Action Center
  when an alarm is auto-silenced, preserving visual awareness.
* Self-Healing Watchdog: Wakes cleanly on Sleep/Modern Standby resume and unlock.
* Native Fluent WinUI 11 Control Panel: On-demand dark-mode dashboard with DWM Mica glass.

QUICK START (1-CLICK SETUP)
--------------------------------------------------------------------------------
1. Run "Setup.bat"
   - Choose [1] Standard Installation (installs cleanly into %LOCALAPPDATA%\AlarmAutoDismiss)
   - Or choose [2] Portable / In-Place Setup to run directly from this folder.
2. The setup will automatically:
   - Create Desktop and Start Menu shortcuts ("Alarm Auto-Shutoff Settings")
   - Configure automatic launch on Windows user login (HKCU Run)
   - Start the background monitoring daemon immediately
   - Open the Control Panel so you can customize your shutoff timeouts

MANAGEMENT TOOLS
--------------------------------------------------------------------------------
* AlarmSettings.bat : Opens the on-demand WinUI 11 Control Panel.
* test_alarm.bat    : Runs a 10-second live test alarm with authentic ringtone to
                      verify automatic audio and toast dismissal.
* status.bat        : Checks if the background service is running and provides
                      1-click recovery if stopped.
* Uninstall.bat     : Completely stops the service, deletes shortcuts, removes
                      startup entries, and cleans up files.

REQUIREMENTS
--------------------------------------------------------------------------------
* Windows 10 (Build 19041+) or Windows 11 (Build 22000, 22621, 26100+).
* Zero external runtimes: Uses pre-installed PowerShell 5.1 and .NET Framework 4.8.
* Standard user permissions (no Administrator or UAC prompts required).
================================================================================
