# AlarmSettings.ps1 - WinUI 11 Control Panel
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System

if (-not ([System.Management.Automation.PSTypeName]'Win32.DwmBackdrop').Type) {
    try {
        Add-Type 'using System;using System.Runtime.InteropServices;namespace Win32{public static class DwmBackdrop{[DllImport("dwmapi.dll")]public static extern int DwmSetWindowAttribute(IntPtr h,int a,ref int v,int s);public const int DWMWA_USE_IMMERSIVE_DARK_MODE=20,DWMWA_SYSTEMBACKDROP_TYPE=38,DWMSBT_MAINWINDOW=2;}}'
    } catch {}
}

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$baseDir = if (Test-Path (Join-Path (Split-Path -Parent $scriptDir) "config.json")) { Split-Path -Parent $scriptDir } else { $scriptDir }
$daemonScript = if (Test-Path (Join-Path $scriptDir "AlarmAutoDismiss.ps1")) { Join-Path $scriptDir "AlarmAutoDismiss.ps1" } else { Join-Path $baseDir "src\AlarmAutoDismiss.ps1" }
$configPath = Join-Path $baseDir "config.json"
$logPath = Join-Path $baseDir "alarm_history.log"
$runRegPath   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$runRegName   = "AlarmAutoDismiss"
$alarmWavPath = "C:\Windows\Media\Alarm01.wav"
$psExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

function Get-DaemonStatus {
    try {
        $m = [System.Threading.Mutex]::OpenExisting("Local\AlarmAutoDismiss_PS1_SingleInstance")
        $m.Close(); return $true
    } catch { return $false }
}

function Start-DaemonService {
    if (-not (Get-DaemonStatus)) {
        $cmd = "`"$psExe`" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$daemonScript`""
        Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd } | Out-Null
    }
}

function Stop-DaemonService {
    & "$psExe" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$daemonScript" -Action stop | Out-Null
}

function Get-StartupEnabled {
    try { return ($null -ne (Get-ItemProperty $runRegPath $runRegName -ErrorAction SilentlyContinue)) } catch { return $false }
}

function Set-StartupEnabled([bool]$enable) {
    if ($enable) {
        $cmd = "`"$psExe`" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$daemonScript`""
        Set-ItemProperty $runRegPath $runRegName -Value $cmd -Type String -Force -ErrorAction SilentlyContinue
    } else {
        Remove-ItemProperty $runRegPath $runRegName -ErrorAction SilentlyContinue
    }
}

function Load-ConfigSettings {
    $c = @{ timeout = 300; timerTimeout = 60; smartIdle = $false; notify = $true }
    if (Test-Path $configPath) {
        try {
            $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($cfg.timeoutSeconds -gt 0) { $c.timeout = [int]$cfg.timeoutSeconds }
            if ($cfg.timerTimeoutSeconds -gt 0) { $c.timerTimeout = [int]$cfg.timerTimeoutSeconds }
            if ($null -ne $cfg.smartIdleGating) { $c.smartIdle = [bool]$cfg.smartIdleGating }
            if ($null -ne $cfg.notifyOnDismiss) { $c.notify = [bool]$cfg.notifyOnDismiss }
        } catch {}
    }
    return $c
}

function Save-ConfigSettings([int]$timeout, [int]$timerTimeout, [bool]$smartIdle, [bool]$notify) {
    $cInt = 2; $logEn = $true
    if (Test-Path $configPath) {
        try {
            $ex = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($ex.checkIntervalSeconds -gt 0) { $cInt = [int]$ex.checkIntervalSeconds }
            if ($null -ne $ex.loggingEnabled) { $logEn = [bool]$ex.loggingEnabled }
        } catch {}
    }
    $json = @{
        timeoutSeconds = $timeout
        timerTimeoutSeconds = $timerTimeout
        smartIdleGating = $smartIdle
        notifyOnDismiss = $notify
        checkIntervalSeconds = $cInt
        loggingEnabled = $logEn
    } | ConvertTo-Json
    $tmp = "$configPath.tmp"
    [System.IO.File]::WriteAllText($tmp, $json, [System.Text.Encoding]::UTF8)
    try {
        if (Test-Path $configPath) { [System.IO.File]::Replace($tmp, $configPath, $null) }
        else { [System.IO.File]::Move($tmp, $configPath) }
    } catch { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
}
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Alarm Auto-Shutoff"
        Height="740" Width="600"  
        Background="Transparent" Foreground="#F0F0F0"
        FontFamily="Segoe UI">
<Window.Resources>
<Style TargetType="Button">
<Setter Property="Background" Value="#2B2B2B"/><Setter Property="Foreground" Value="#FFFFFF"/>
<Setter Property="BorderBrush" Value="#383838"/><Setter Property="BorderThickness" Value="1"/>
<Setter Property="Padding" Value="12,4"/><Setter Property="Cursor" Value="Hand"/>
<Setter Property="FontSize" Value="13"/><Setter Property="FontWeight" Value="SemiBold"/>
<Setter Property="Template">
<Setter.Value>
<ControlTemplate TargetType="Button">
<Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6">
<ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
</Border>
</ControlTemplate>
</Setter.Value>
</Setter>
<Style.Triggers>
<Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#383838"/><Setter Property="BorderBrush" Value="#4A4A4A"/></Trigger>
<Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.45"/><Setter Property="Cursor" Value="Arrow"/></Trigger>
</Style.Triggers>
</Style>
<Style x:Key="Card" TargetType="Border">
<Setter Property="Background" Value="#D0202020"/><Setter Property="BorderBrush" Value="#353535"/>
<Setter Property="BorderThickness" Value="1"/><Setter Property="CornerRadius" Value="8"/>
<Setter Property="Padding" Value="12"/><Setter Property="Margin" Value="0,0,0,10"/>
</Style>
</Window.Resources>
<ScrollViewer VerticalScrollBarVisibility="Auto">
<StackPanel Margin="18">
<Grid Margin="0,0,0,12">
<Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
<StackPanel Grid.Column="0">
<TextBlock Text="Alarm Auto-Shutoff" FontSize="20" FontWeight="Bold" Foreground="#FFFFFF"/>
<TextBlock Text="Clock Auto-Dismiss Settings" FontSize="12" Foreground="#9E9E9E" Margin="0,2,0,0"/>
</StackPanel>
<Border Grid.Column="1" Background="#242830" BorderBrush="#303848" BorderThickness="1" CornerRadius="12" Padding="10,3" VerticalAlignment="Center">
<TextBlock Text="v1.6.1 | Self-Healing" FontSize="11" Foreground="#4DA3FF" FontWeight="SemiBold"/>
</Border>
</Grid>
<Border Style="{StaticResource Card}">
<StackPanel>
<Grid>
<Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
<StackPanel Orientation="Horizontal" VerticalAlignment="Center">
<Ellipse x:Name="StatusDot" Width="10" Height="10" Fill="#107C41" Margin="0,0,10,0"/>
<TextBlock x:Name="StatusText" Text="Running" FontSize="14" FontWeight="Bold" Foreground="#FFFFFF"/>
</StackPanel>
<StackPanel Grid.Column="1" Orientation="Horizontal">
<Button x:Name="BtnStart" Content="Start" Background="#107C41" BorderBrush="#15944E" Margin="0,0,6,0" Padding="12,4"/>
<Button x:Name="BtnStop" Content="Stop" Background="#8A1818" BorderBrush="#A32424" Margin="0,0,6,0" Padding="12,4"/>
<Button x:Name="BtnRestart" Content="Restart" Background="#2B2B2B" Padding="10,4"/>
</StackPanel>
</Grid>
<TextBlock Text="Runs invisibly in the background with EcoQoS efficiency (~16MB RAM)." FontSize="11" Foreground="#888888" Margin="20,4,0,0"/>
</StackPanel>
</Border>
<Border Style="{StaticResource Card}">
<StackPanel>
<TextBlock Text="Auto-Shutoff Timeouts" FontSize="14" FontWeight="Bold" Foreground="#FFFFFF" Margin="0,0,0,2"/>
<TextBlock Text="Separate shutoff limits for alarms and timers." FontSize="12" Foreground="#888888" Margin="0,0,0,8"/>
<TextBlock Text="Wake-Up Alarms Timeout" FontSize="12" FontWeight="SemiBold" Foreground="#E0E0E0" Margin="0,0,0,4"/>
<WrapPanel Margin="0,0,0,6">
<Button x:Name="BtnPreset1m" Content="1 min" Margin="0,0,6,4" Padding="10,3"/>
<Button x:Name="BtnPreset2m" Content="2 min" Margin="0,0,6,4" Padding="10,3"/>
<Button x:Name="BtnPreset3m" Content="3 min" Margin="0,0,6,4" Padding="10,3"/>
<Button x:Name="BtnPreset5m" Content="5 min (Default)" Margin="0,0,6,4" Padding="12,3" Background="#005A9E" BorderBrush="#0078D4"/>
<Button x:Name="BtnPreset10m" Content="10 min" Margin="0,0,6,4" Padding="10,3"/>
</WrapPanel>
<Grid Margin="0,0,0,8">
<Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="105"/></Grid.ColumnDefinitions>
<Slider x:Name="TimeoutSlider" Minimum="30" Maximum="1200" SmallChange="10" LargeChange="60" TickFrequency="60" VerticalAlignment="Center" Margin="0,0,12,0"/>
<Border Grid.Column="1" Background="#161616" BorderBrush="#383838" BorderThickness="1" CornerRadius="6" Padding="6,3">
<TextBlock x:Name="TimeoutDisplay" Text="300s (5m 0s)" Foreground="#4DA3FF" FontWeight="Bold" HorizontalAlignment="Center"/>
</Border>
</Grid>
<TextBlock Text="Countdown Timers Timeout" FontSize="12" FontWeight="SemiBold" Foreground="#E0E0E0" Margin="0,2,0,4"/>
<WrapPanel Margin="0,0,0,6">
<Button x:Name="BtnTimer30s" Content="30 sec" Margin="0,0,6,4" Padding="10,3"/>
<Button x:Name="BtnTimer1m" Content="1 min (Default)" Margin="0,0,6,4" Padding="12,3" Background="#005A9E" BorderBrush="#0078D4"/>
<Button x:Name="BtnTimer2m" Content="2 min" Margin="0,0,6,4" Padding="10,3"/>
<Button x:Name="BtnTimer5m" Content="5 min" Margin="0,0,6,4" Padding="10,3"/>
</WrapPanel>
<Grid Margin="0,0,0,12">
<Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="105"/></Grid.ColumnDefinitions>
<Slider x:Name="TimerSlider" Minimum="15" Maximum="300" SmallChange="5" LargeChange="15" TickFrequency="30" VerticalAlignment="Center" Margin="0,0,12,0"/>
<Border Grid.Column="1" Background="#161616" BorderBrush="#383838" BorderThickness="1" CornerRadius="6" Padding="6,3">
<TextBlock x:Name="TimerDisplay" Text="60s (1m 0s)" Foreground="#4DA3FF" FontWeight="Bold" HorizontalAlignment="Center"/>
</Border>
</Grid>
<CheckBox x:Name="ChkSmartIdle" Margin="0,0,0,6" VerticalAlignment="Center">
<TextBlock Text="Smart Idle Gating (Defer shutoff up to 60s while active at PC)" FontSize="12" Foreground="#E0E0E0"/>
</CheckBox>
<CheckBox x:Name="ChkNotify" Margin="0,0,0,6" VerticalAlignment="Center">
<TextBlock Text="Show silent reminder in Notification Center when auto-silenced" FontSize="12" Foreground="#E0E0E0"/>
</CheckBox>
<CheckBox x:Name="ChkStartup" Margin="0,0,0,8" VerticalAlignment="Center">
<TextBlock Text="Start automatically when I log into Windows" FontSize="12" Foreground="#E0E0E0"/>
</CheckBox>
<Grid>
<Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
<Button x:Name="BtnSave" Content="Save Settings" Background="#0078D4" BorderBrush="#1A88E0" Padding="16,6" FontWeight="Bold"/>
<TextBlock x:Name="SaveFeedback" Grid.Column="1" Text="" Foreground="#107C41" FontWeight="SemiBold" VerticalAlignment="Center" Margin="12,0,0,0"/>
</Grid>
</StackPanel>
</Border>
<Border Style="{StaticResource Card}">
<StackPanel>
<TextBlock Text="Test &amp; Verification" FontSize="14" FontWeight="Bold" Foreground="#FFFFFF" Margin="0,0,0,2"/>
<TextBlock Text="Play a 10-second test alarm to verify audio cuts off automatically." FontSize="12" Foreground="#888888" Margin="0,0,0,8"/>
<Grid Margin="0,0,0,6">
<Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
<Button x:Name="BtnTestAlarm" Content="Test Alarm (10s)" Background="#2B2B2B" Padding="14,6"/>
<TextBlock x:Name="TestStatusText" Grid.Column="1" Text="Ready" Foreground="#AAAAAA" VerticalAlignment="Center" Margin="12,0,0,0"/>
</Grid>
<ProgressBar x:Name="TestProgressBar" Height="6" Maximum="10" Value="0" Background="#161616" Foreground="#0078D4" BorderThickness="0" Margin="0,4,0,0" Visibility="Collapsed"/>
</StackPanel>
</Border>
<Border Style="{StaticResource Card}" Margin="0">
<StackPanel>
<Grid Margin="0,0,0,6">
<Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
<TextBlock Text="Activity History Log" FontSize="14" FontWeight="Bold" Foreground="#FFFFFF" VerticalAlignment="Center"/>
<StackPanel Grid.Column="1" Orientation="Horizontal">
<Button x:Name="BtnRefreshLog" Content="Refresh" Margin="0,0,6,0" Padding="8,3" FontSize="11"/>
<Button x:Name="BtnClearLog" Content="Clear" Padding="8,3" FontSize="11"/>
</StackPanel>
</Grid>
<TextBox x:Name="LogViewer" Height="100" Background="#141414" Foreground="#B0B0B0" BorderBrush="#2F2F2F" BorderThickness="1" FontFamily="Consolas" FontSize="11" IsReadOnly="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Padding="6"/>
</StackPanel>
</Border>
</StackPanel>
</ScrollViewer>
</Window>
"@

$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Apply Windows 11 DWM Mica material & Immersive Dark Title bar
$window.Add_SourceInitialized({
    try {
        $hwnd = ([System.Windows.Interop.WindowInteropHelper]::new($window)).Handle
        $dark = 1
        [Win32.DwmBackdrop]::DwmSetWindowAttribute($hwnd, [Win32.DwmBackdrop]::DWMWA_USE_IMMERSIVE_DARK_MODE, [ref]$dark, 4) | Out-Null
        $mica = [Win32.DwmBackdrop]::DWMSBT_MAINWINDOW
        [Win32.DwmBackdrop]::DwmSetWindowAttribute($hwnd, [Win32.DwmBackdrop]::DWMWA_SYSTEMBACKDROP_TYPE, [ref]$mica, 4) | Out-Null
    } catch {}
})

$statusDot=$window.FindName("StatusDot"); $statusText=$window.FindName("StatusText")
$btnStart=$window.FindName("BtnStart"); $btnStop=$window.FindName("BtnStop"); $btnRestart=$window.FindName("BtnRestart")
$btnPreset1m=$window.FindName("BtnPreset1m"); $btnPreset2m=$window.FindName("BtnPreset2m"); $btnPreset3m=$window.FindName("BtnPreset3m"); $btnPreset5m=$window.FindName("BtnPreset5m"); $btnPreset10m=$window.FindName("BtnPreset10m")
$timeoutSlider=$window.FindName("TimeoutSlider"); $timeoutDisplay=$window.FindName("TimeoutDisplay")
$btnTimer30s=$window.FindName("BtnTimer30s"); $btnTimer1m=$window.FindName("BtnTimer1m"); $btnTimer2m=$window.FindName("BtnTimer2m"); $btnTimer5m=$window.FindName("BtnTimer5m")
$timerSlider=$window.FindName("TimerSlider"); $timerDisplay=$window.FindName("TimerDisplay")
$chkSmartIdle=$window.FindName("ChkSmartIdle"); $chkNotify=$window.FindName("ChkNotify"); $chkStartup=$window.FindName("ChkStartup")
$btnSave=$window.FindName("BtnSave"); $saveFeedback=$window.FindName("SaveFeedback")
$btnTestAlarm=$window.FindName("BtnTestAlarm"); $testStatusText=$window.FindName("TestStatusText"); $testProgressBar=$window.FindName("TestProgressBar")
$logViewer=$window.FindName("LogViewer"); $btnRefreshLog=$window.FindName("BtnRefreshLog"); $btnClearLog=$window.FindName("BtnClearLog")

$cfgData = Load-ConfigSettings
$timeoutSlider.Value = $cfgData.timeout
$timerSlider.Value = $cfgData.timerTimeout
$chkSmartIdle.IsChecked = $cfgData.smartIdle
$chkNotify.IsChecked = $cfgData.notify
$chkStartup.IsChecked = Get-StartupEnabled

function Format-SecDisplay([double]$val) {
    $s = [int]$val
    $m = [math]::Floor($s / 60)
    $r = $s % 60
    return "${s}s (${m}m ${r}s)"
}

$timeoutDisplay.Text = Format-SecDisplay $cfgData.timeout
$timerDisplay.Text = Format-SecDisplay $cfgData.timerTimeout

function Br($r,$g,$b){ [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($r,$g,$b)) }
$brGreen = Br 16 124 65; $brRed = Br 209 52 56; $brWhite = Br 240 240 240; $brGray = Br 200 200 200
$bDark = Br 43 43 43; $bDarkBorder = Br 56 56 56; $bActive = Br 0 90 158; $bActiveBorder = Br 0 120 212

function Update-ServiceStatusUI {
    $r = Get-DaemonStatus
    $statusDot.Fill = if ($r) { $brGreen } else { $brRed }
    $statusText.Text = if ($r) { "Running" } else { "Stopped" }
    $statusText.Foreground = if ($r) { $brWhite } else { $brGray }
    $btnStart.IsEnabled = -not $r
    $btnStop.IsEnabled  = $r
    $btnRestart.IsEnabled = $r
}
Update-ServiceStatusUI

function Refresh-LogViewer {
    if (Test-Path $logPath) {
        try {
            $lines = Get-Content -Path $logPath -Tail 60 -ErrorAction SilentlyContinue
            $logViewer.Text = ($lines -join [Environment]::NewLine)
            $logViewer.ScrollToEnd()
        } catch {}
    } else {
        $logViewer.Text = "No activity logged yet."
    }
}
Refresh-LogViewer

function Set-AlarmPreset([int]$sec, $btn) {
    $timeoutSlider.Value = $sec
    $timeoutDisplay.Text = Format-SecDisplay $sec
    @($btnPreset1m, $btnPreset2m, $btnPreset3m, $btnPreset5m, $btnPreset10m) | ForEach-Object {
        $_.Background = $bDark; $_.BorderBrush = $bDarkBorder
    }
    if ($btn) { $btn.Background = $bActive; $btn.BorderBrush = $bActiveBorder }
}

function Set-TimerPreset([int]$sec, $btn) {
    $timerSlider.Value = $sec
    $timerDisplay.Text = Format-SecDisplay $sec
    @($btnTimer30s, $btnTimer1m, $btnTimer2m, $btnTimer5m) | ForEach-Object {
        $_.Background = $bDark; $_.BorderBrush = $bDarkBorder
    }
    if ($btn) { $btn.Background = $bActive; $btn.BorderBrush = $bActiveBorder }
}

@(@($btnPreset1m,60),@($btnPreset2m,120),@($btnPreset3m,180),@($btnPreset5m,300),@($btnPreset10m,600)) | ForEach-Object {
    $b,$s = $_; $b.Add_Click({ Set-AlarmPreset $s $b }.GetNewClosure())
}

@(@($btnTimer30s,30),@($btnTimer1m,60),@($btnTimer2m,120),@($btnTimer5m,300)) | ForEach-Object {
    $b,$s = $_; $b.Add_Click({ Set-TimerPreset $s $b }.GetNewClosure())
}

$timeoutSlider.Add_ValueChanged({ $timeoutDisplay.Text = Format-SecDisplay $timeoutSlider.Value })
$timerSlider.Add_ValueChanged({ $timerDisplay.Text = Format-SecDisplay $timerSlider.Value })

$btnStart.Add_Click({ Start-DaemonService; Start-Sleep -Milliseconds 600; Update-ServiceStatusUI; Refresh-LogViewer })
$btnStop.Add_Click({ Stop-DaemonService; Start-Sleep -Milliseconds 600; Update-ServiceStatusUI; Refresh-LogViewer })
$btnRestart.Add_Click({ Stop-DaemonService; Start-Sleep -Milliseconds 400; Start-DaemonService; Start-Sleep -Milliseconds 600; Update-ServiceStatusUI; Refresh-LogViewer })

$btnSave.Add_Click({
    Save-ConfigSettings ([int]$timeoutSlider.Value) ([int]$timerSlider.Value) ([bool]$chkSmartIdle.IsChecked) ([bool]$chkNotify.IsChecked)
    Set-StartupEnabled ([bool]$chkStartup.IsChecked)
    $saveFeedback.Text = "[OK] Settings saved! Dynamically reloaded by service."
    $saveFeedback.Foreground = $brGreen
    $t = [System.Windows.Threading.DispatcherTimer]::new()
    $t.Interval = [TimeSpan]::FromSeconds(3)
    $t.Add_Tick({ $saveFeedback.Text = ""; $t.Stop() })
    $t.Start()
    Refresh-LogViewer
})

$script:testTimer = $null
$script:testStartTime = [DateTime]::MinValue
$script:testDurationSec = 10
$script:soundPlayer = $null
if (Test-Path $alarmWavPath) {
    try { $script:soundPlayer = [System.Media.SoundPlayer]::new($alarmWavPath) } catch {}
}

$btnTestAlarm.Add_Click({
    $btnTestAlarm.IsEnabled = $false
    $testStatusText.Text = "Starting test alarm..."
    $testStatusText.Foreground = Br 77 163 255
    $testProgressBar.Visibility = [System.Windows.Visibility]::Visible
    $testProgressBar.Value = 0

    if (-not (Get-DaemonStatus)) {
        Start-DaemonService
        Start-Sleep -Milliseconds 600
        Update-ServiceStatusUI
    }

    if ($script:soundPlayer) { try { $script:soundPlayer.PlayLooping() } catch {} }

    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        $xml = '<toast scenario="alarm"><visual><binding template="ToastGeneric"><text>AlarmAutoDismiss-Test: Ringing</text><text>Live GUI auto-shutoff test. Audio will halt in 10s.</text></binding></visual><audio src="ms-winsoundevent:Notification.Looping.Alarm" loop="true"/><actions><action content="Dismiss" arguments="dismiss" activationType="background"/></actions></toast>'
        $doc = [Windows.Data.Xml.Dom.XmlDocument]::new()
        $doc.LoadXml($xml)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($doc)
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Microsoft.WindowsAlarms_8wekyb3d8bbwe")
        $notifier.Show($toast)
    } catch {}

    $script:testStartTime = [DateTime]::UtcNow
    $script:testTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $script:testTimer.Interval = [TimeSpan]::FromMilliseconds(250)
    
    $script:testTimer.Add_Tick({
        $elapsed = ([DateTime]::UtcNow - $script:testStartTime).TotalSeconds
        $rem = [Math]::Max(0, [Math]::Ceiling($script:testDurationSec - $elapsed))
        $testProgressBar.Value = [Math]::Min($script:testDurationSec, $elapsed)

        if ($rem -gt 0) {
            $testStatusText.Text = "Audio ringing... Auto-shutoff in ${rem}s"
        } else {
            $script:testTimer.Stop()
            if ($script:soundPlayer) { try { $script:soundPlayer.Stop() } catch {} }
            $testProgressBar.Value = $script:testDurationSec
            $testStatusText.Text = "[OK] Auto-shutoff triggered! Audio silenced."
            $testStatusText.Foreground = $brGreen
            $btnTestAlarm.IsEnabled = $true

            try {
                $listener = [Windows.UI.Notifications.Management.UserNotificationListener]::Current
                $op = $listener.GetNotificationsAsync([Windows.UI.Notifications.NotificationKinds]::Toast)
                $asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } | Select-Object -First 1
                $task = $asTask.MakeGenericMethod([System.Collections.Generic.IReadOnlyList[Windows.UI.Notifications.UserNotification]]).Invoke($null, @($op))
                $null = $task.Wait(1500)
                foreach ($n in $task.Result) {
                    try {
                        $b = $n.Notification.Visual.GetBinding("ToastGeneric")
                        if ($b -and ($b.GetTextElements()[0].Text -like "*AlarmAutoDismiss-Test*")) { $listener.RemoveNotification($n.Id) }
                    } catch {}
                }
            } catch {}

            $ht = [System.Windows.Threading.DispatcherTimer]::new()
            $ht.Interval = [TimeSpan]::FromSeconds(3)
            $ht.Add_Tick({
                $testProgressBar.Visibility = [System.Windows.Visibility]::Collapsed
                $testStatusText.Text = "Ready"
                $testStatusText.Foreground = $brGray
                $ht.Stop()
            })
            $ht.Start()
            Refresh-LogViewer
        }
    })
    $script:testTimer.Start()
})

$window.Add_Closing({
    if ($script:soundPlayer) { try { $script:soundPlayer.Stop() } catch {} }
    if ($script:testTimer) { try { $script:testTimer.Stop() } catch {} }
    if ($pollTimer) { try { $pollTimer.Stop() } catch {} }
})

$btnRefreshLog.Add_Click({ Refresh-LogViewer })
$btnClearLog.Add_Click({ if (Test-Path $logPath) { Clear-Content -Path $logPath -ErrorAction SilentlyContinue }; Refresh-LogViewer })

$lastLogSize = 0
$pollTimer = [System.Windows.Threading.DispatcherTimer]::new()
$pollTimer.Interval = [TimeSpan]::FromSeconds(2)
$pollTimer.Add_Tick({
    Update-ServiceStatusUI
    if (Test-Path $logPath) {
        try {
            $currSize = (Get-Item $logPath).Length
            if ($currSize -ne $lastLogSize) { $lastLogSize = $currSize; Refresh-LogViewer }
        } catch {}
    }
})
$pollTimer.Start()

$window.ShowDialog() | Out-Null
