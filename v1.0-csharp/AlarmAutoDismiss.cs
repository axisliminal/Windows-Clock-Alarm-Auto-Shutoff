using System;
using System.IO;
using System.Text;
using System.Threading;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using Windows.Foundation;
using Windows.UI.Notifications;
using Windows.UI.Notifications.Management;
using Windows.Data.Xml.Dom;

public static class Program
{
    private const string MutexName = @"Local\AlarmAutoDismiss_SingleInstance";
    private const string StopEventName = @"Local\AlarmAutoDismiss_StopEvent";
    private const string TargetPackageFamily = "Microsoft.WindowsAlarms_8wekyb3d8bbwe";
    private const string TestAlarmTag = "AlarmAutoDismiss-Test";

    private static string _appDir;
    private static string _logPath;
    private static string _configPath;
    private static int _timeoutSeconds = 300; // 5 minutes default
    private static int _checkIntervalMs = 2500; // 2.5 seconds
    private static bool _loggingEnabled = true;

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool AttachConsole(int dwProcessId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool AllocConsole();

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool FreeConsole();

    // Zero-dependency WinRT Async Synchronizer for C# 5 / .NET 4.8
    public static T AwaitWinRT<T>(IAsyncOperation<T> asyncOp, int timeoutMs)
    {
        if (asyncOp.Status == AsyncStatus.Completed)
        {
            return asyncOp.GetResults();
        }

        var mres = new ManualResetEvent(false);
        asyncOp.Completed = new AsyncOperationCompletedHandler<T>((info, status) =>
        {
            mres.Set();
        });

        if (!mres.WaitOne(timeoutMs))
        {
            try { asyncOp.Cancel(); } catch { }
            throw new TimeoutException("WinRT async operation timed out after " + timeoutMs + "ms");
        }

        return asyncOp.GetResults();
    }

    [STAThread]
    public static int Main(string[] args)
    {
        _appDir = AppDomain.CurrentDomain.BaseDirectory;
        _logPath = Path.Combine(_appDir, "alarm_history.log");
        _configPath = Path.Combine(_appDir, "config.json");

        LoadConfiguration();

        if (args != null && args.Length > 0)
        {
            string flag = args[0].ToLowerInvariant().TrimStart('-', '/');

            if (flag == "status")
            {
                AttachConsoleOutput();
                bool isRunning = CheckIfRunning();
                Console.WriteLine(string.Format("AlarmAutoDismiss Status: {0}", isRunning ? "RUNNING (Active)" : "STOPPED (Not running)"));
                return isRunning ? 0 : 1;
            }

            if (flag == "stop")
            {
                AttachConsoleOutput();
                Console.WriteLine("Sending stop signal to AlarmAutoDismiss...");
                bool stopped = SignalStop();
                Console.WriteLine(stopped ? "Stop signal delivered successfully." : "AlarmAutoDismiss was not running.");
                return stopped ? 0 : 1;
            }

            if (flag == "test")
            {
                AttachConsoleOutput();
                int testDuration = 10;
                if (args.Length > 1)
                {
                    int parsed;
                    if (int.TryParse(args[1], out parsed) && parsed > 0)
                    {
                        testDuration = parsed;
                    }
                }
                RunTestAlarm(testDuration);
                return 0;
            }

            if (flag == "help" || flag == "?")
            {
                AttachConsoleOutput();
                Console.WriteLine("AlarmAutoDismiss - Windows Clock 5-Minute Auto-Shutoff Utility");
                Console.WriteLine("Usage:");
                Console.WriteLine("  AlarmAutoDismiss.exe          Start headless background monitor");
                Console.WriteLine("  AlarmAutoDismiss.exe -status  Check if background monitor is running");
                Console.WriteLine("  AlarmAutoDismiss.exe -test    Trigger a 10s test alarm to verify audio cutoff");
                Console.WriteLine("  AlarmAutoDismiss.exe -stop    Gracefully stop the background monitor");
                return 0;
            }
        }

        // Default mode: Run as headless background daemon
        return RunDaemon();
    }

    private static int RunDaemon()
    {
        bool createdNew = false;
        Mutex singleInstanceMutex = null;

        try
        {
            singleInstanceMutex = new Mutex(true, MutexName, out createdNew);
        }
        catch (AbandonedMutexException)
        {
            createdNew = true;
        }
        catch (Exception ex)
        {
            Log("Failed to create single-instance mutex: " + ex.Message);
            return 1;
        }

        if (!createdNew)
        {
            Log("Another instance is already running. Exiting silently.");
            if (singleInstanceMutex != null)
            {
                singleInstanceMutex.Close();
            }
            return 0;
        }

        EventWaitHandle stopSignal = null;
        try
        {
            stopSignal = new EventWaitHandle(false, EventResetMode.ManualReset, StopEventName);
            stopSignal.Reset(); // Reset in case a previous run left it signaled
        }
        catch (Exception ex)
        {
            Log("Failed to create stop event: " + ex.Message);
            try { singleInstanceMutex.ReleaseMutex(); } catch { }
            singleInstanceMutex.Close();
            return 1;
        }

        Log(string.Format("=== Daemon started (PID: {0}, Timeout: {1}s, Interval: {2}ms) ===",
            System.Diagnostics.Process.GetCurrentProcess().Id, _timeoutSeconds, _checkIntervalMs));

        AppDomain.CurrentDomain.ProcessExit += (sender, e) =>
        {
            Log("Process received exit signal. Shutting down.");
        };

        UserNotificationListener listener = null;
        try
        {
            listener = UserNotificationListener.Current;
            UserNotificationListenerAccessStatus status = listener.GetAccessStatus();
            if (status != UserNotificationListenerAccessStatus.Allowed)
            {
                Log("WARNING: UserNotificationListener access status is " + status + ". Waiting for permissions.");
            }
        }
        catch (Exception ex)
        {
            Log("ERROR initializing UserNotificationListener: " + ex.Message);
        }

        var firstSeenMap = new Dictionary<uint, DateTime>();

        try
        {
            while (!stopSignal.WaitOne(_checkIntervalMs))
            {
                try
                {
                    ProcessNotifications(listener, firstSeenMap);
                }
                catch (Exception ex)
                {
                    Log("Warning in notification loop: " + ex.Message);
                }
            }
        }
        finally
        {
            Log("=== Daemon stopped gracefully ===");
            if (stopSignal != null)
            {
                stopSignal.Close();
            }
            if (singleInstanceMutex != null)
            {
                try { singleInstanceMutex.ReleaseMutex(); } catch { }
                singleInstanceMutex.Close();
            }
        }

        return 0;
    }

    private static void ProcessNotifications(UserNotificationListener listener, Dictionary<uint, DateTime> firstSeenMap)
    {
        if (listener == null) return;

        IReadOnlyList<UserNotification> notifications = null;
        try
        {
            notifications = AwaitWinRT(listener.GetNotificationsAsync(NotificationKinds.Toast), 4000);
        }
        catch (Exception ex)
        {
            Log("GetNotificationsAsync query error: " + ex.Message);
            return;
        }

        if (notifications == null) return;

        var currentNotificationIds = new HashSet<uint>();

        for (int i = 0; i < notifications.Count; i++)
        {
            UserNotification n = notifications[i];
            if (n == null) continue;

            uint id = 0;
            try { id = n.Id; } catch { continue; }
            currentNotificationIds.Add(id);

            // Strict Filter: Only Windows Clock alarms/timers or synthetic test toasts
            bool isClockAlarm = false;
            bool isTestToast = false;

            try
            {
                if (n.AppInfo != null)
                {
                    string pfn = n.AppInfo.PackageFamilyName;
                    if (!string.IsNullOrEmpty(pfn) && string.Equals(pfn, TargetPackageFamily, StringComparison.OrdinalIgnoreCase))
                    {
                        isClockAlarm = true;
                    }
                    else
                    {
                        string aumid = n.AppInfo.AppUserModelId;
                        if (!string.IsNullOrEmpty(aumid) && aumid.IndexOf("WindowsAlarms", StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            isClockAlarm = true;
                        }
                    }
                }
            }
            catch { }

            // Check if it's our synthetic test toast or Clock alarm
            if (!isClockAlarm)
            {
                try
                {
                    if (n.Notification != null && n.Notification.Visual != null)
                    {
                        var b = n.Notification.Visual.GetBinding("ToastGeneric");
                        if (b != null)
                        {
                            var texts = b.GetTextElements();
                            for (int t = 0; t < texts.Count; t++)
                            {
                                string textVal = texts[t].Text;
                                if (!string.IsNullOrEmpty(textVal) && textVal.IndexOf(TestAlarmTag, StringComparison.OrdinalIgnoreCase) >= 0)
                                {
                                    isTestToast = true;
                                    break;
                                }
                            }
                        }
                    }
                }
                catch { }
            }

            // Strictly ignore all unrelated notifications (Outlook, Teams, browsers, Antigravity, etc.)
            if (!isClockAlarm && !isTestToast)
            {
                continue;
            }

            // Track active ringing start time
            DateTime nowUtc = DateTime.UtcNow;
            if (!firstSeenMap.ContainsKey(id))
            {
                firstSeenMap[id] = nowUtc;
                string label = ExtractNotificationLabel(n);
                Log(string.Format("ACTIVE: Ringing {0} detected (ID: {1}) - '{2}'. Starting auto-shutoff countdown.",
                    isTestToast ? "Test Alarm" : "Clock Alarm/Timer", id, label));
            }

            // Resilient duration calculation: use whichever elapsed time is higher
            double localElapsed = (nowUtc - firstSeenMap[id]).TotalSeconds;
            double creationElapsed = 0;
            try
            {
                creationElapsed = (DateTimeOffset.Now - n.CreationTime).TotalSeconds;
            }
            catch { }

            double elapsedSeconds = Math.Max(localElapsed, creationElapsed);
            int effectiveThreshold = isTestToast ? 10 : _timeoutSeconds;

            if (elapsedSeconds >= effectiveThreshold)
            {
                string label = ExtractNotificationLabel(n);
                Log(string.Format("TIMEOUT: {0} (ID: {1}, '{2}') reached {3:F0}s (threshold: {4}s). AUTO-DISMISSING NOW...",
                    isTestToast ? "Test Alarm" : "Clock Alarm/Timer", id, label, elapsedSeconds, effectiveThreshold));

                try
                {
                    listener.RemoveNotification(id);
                    Log(string.Format("SUCCESS: Notification ID {0} removed. Audio terminated and toast dismissed.", id));
                }
                catch (Exception ex)
                {
                    Log(string.Format("ERROR dismissing notification ID {0}: {1}", id, ex.Message));
                }

                firstSeenMap.Remove(id);
            }
        }

        // Clean up tracking if user manually dismissed or snoozed the alarm before timeout
        var toRemove = new List<uint>();
        foreach (uint trackedId in firstSeenMap.Keys)
        {
            if (!currentNotificationIds.Contains(trackedId))
            {
                toRemove.Add(trackedId);
            }
        }

        for (int k = 0; k < toRemove.Count; k++)
        {
            Log(string.Format("RESET: Notification ID {0} was manually dismissed/snoozed by user. Resetting countdown.", toRemove[k]));
            firstSeenMap.Remove(toRemove[k]);
        }
    }

    private static string ExtractNotificationLabel(UserNotification n)
    {
        try
        {
            if (n.Notification != null && n.Notification.Visual != null)
            {
                var sb = new StringBuilder();
                var b = n.Notification.Visual.GetBinding("ToastGeneric");
                if (b != null)
                {
                    var texts = b.GetTextElements();
                    for (int t = 0; t < texts.Count; t++)
                    {
                        if (!string.IsNullOrEmpty(texts[t].Text))
                        {
                            if (sb.Length > 0) sb.Append(" - ");
                            sb.Append(texts[t].Text.Trim());
                        }
                    }
                }
                if (sb.Length > 0) return sb.ToString();
            }
        }
        catch { }
        return "Unknown Alarm";
    }

    private static bool CheckIfRunning()
    {
        try
        {
            using (var m = Mutex.OpenExisting(MutexName))
            {
                return true;
            }
        }
        catch
        {
            return false;
        }
    }

    private static bool SignalStop()
    {
        try
        {
            using (var ev = EventWaitHandle.OpenExisting(StopEventName))
            {
                ev.Set();
                return true;
            }
        }
        catch
        {
            return false;
        }
    }

    private static void RunTestAlarm(int durationSeconds)
    {
        Console.WriteLine("==================================================");
        Console.WriteLine("  AlarmAutoDismiss - Test Verification");
        Console.WriteLine(string.Format("  Target Duration: {0} seconds", durationSeconds));
        Console.WriteLine("==================================================");

        string xml = string.Format(
            "<toast scenario=\"alarm\">" +
            "  <visual>" +
            "    <binding template=\"ToastGeneric\">" +
            "      <text>{0}: Active</text>" +
            "      <text>Testing auto-shutoff. Audio will stop in {1} seconds.</text>" +
            "    </binding>" +
            "  </visual>" +
            "  <audio src=\"ms-winsoundevent:Notification.Looping.Alarm\" loop=\"true\"/>" +
            "  <actions>" +
            "    <action content=\"Dismiss\" arguments=\"dismiss\" activationType=\"background\"/>" +
            "  </actions>" +
            "</toast>", TestAlarmTag, durationSeconds);

        var doc = new XmlDocument();
        doc.LoadXml(xml);
        var toast = new ToastNotification(doc);
        var notifier = ToastNotificationManager.CreateToastNotifier(TargetPackageFamily);

        Console.WriteLine("[1/3] Playing alarm toast with looping audio...");
        notifier.Show(toast);

        Console.WriteLine(string.Format("[2/3] Waiting {0} seconds...", durationSeconds));
        Thread.Sleep(durationSeconds * 1000);

        Console.WriteLine("[3/3] Dismissing alarm notification and halting audio...");
        var listener = UserNotificationListener.Current;
        var notifs = AwaitWinRT(listener.GetNotificationsAsync(NotificationKinds.Toast), 4000);

        bool dismissed = false;
        if (notifs != null)
        {
            for (int i = 0; i < notifs.Count; i++)
            {
                UserNotification n = notifs[i];
                string label = ExtractNotificationLabel(n);
                if (label.IndexOf(TestAlarmTag, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    listener.RemoveNotification(n.Id);
                    Console.WriteLine(string.Format("  -> Dismissed notification ID: {0}", n.Id));
                    dismissed = true;
                }
            }
        }

        if (dismissed)
        {
            Console.WriteLine("\n[SUCCESS] Test completed! Alarm audio cut off immediately and toast was removed.");
        }
        else
        {
            Console.WriteLine("\n[INFO] Notification was already dismissed (likely handled by the background daemon).");
        }
    }

    private static void LoadConfiguration()
    {
        try
        {
            if (File.Exists(_configPath))
            {
                string text = File.ReadAllText(_configPath);
                // Parse simple JSON properties without third-party dependencies
                int t = ParseIntProperty(text, "timeoutSeconds");
                if (t > 0) _timeoutSeconds = t;

                int interval = ParseIntProperty(text, "checkIntervalSeconds");
                if (interval > 0) _checkIntervalMs = interval * 1000;

                string logVal = ParseStringProperty(text, "loggingEnabled");
                if (!string.IsNullOrEmpty(logVal) && logVal.ToLowerInvariant() == "false")
                {
                    _loggingEnabled = false;
                }
            }
        }
        catch (Exception ex)
        {
            Log("Error reading config.json: " + ex.Message + ". Using defaults.");
        }
    }

    private static int ParseIntProperty(string json, string key)
    {
        string pattern = "\"" + key + "\"";
        int idx = json.IndexOf(pattern, StringComparison.OrdinalIgnoreCase);
        if (idx < 0) return -1;
        int colon = json.IndexOf(':', idx + pattern.Length);
        if (colon < 0) return -1;
        int end = json.IndexOfAny(new char[] { ',', '}', '\r', '\n' }, colon + 1);
        if (end < 0) end = json.Length;
        string val = json.Substring(colon + 1, end - colon - 1).Trim().Trim('"', ' ');
        int result;
        if (int.TryParse(val, out result)) return result;
        return -1;
    }

    private static string ParseStringProperty(string json, string key)
    {
        string pattern = "\"" + key + "\"";
        int idx = json.IndexOf(pattern, StringComparison.OrdinalIgnoreCase);
        if (idx < 0) return null;
        int colon = json.IndexOf(':', idx + pattern.Length);
        if (colon < 0) return null;
        int end = json.IndexOfAny(new char[] { ',', '}', '\r', '\n' }, colon + 1);
        if (end < 0) end = json.Length;
        return json.Substring(colon + 1, end - colon - 1).Trim().Trim('"', ' ');
    }

    private static void Log(string message)
    {
        if (!_loggingEnabled) return;
        try
        {
            string line = string.Format("[{0:yyyy-MM-dd HH:mm:ss}] {1}", DateTime.Now, message);
            File.AppendAllText(_logPath, line + Environment.NewLine, Encoding.UTF8);
        }
        catch { }
    }

    private static void AttachConsoleOutput()
    {
        // Try attaching to the parent console (command prompt or powershell)
        if (AttachConsole(-1))
        {
            var stdOut = new StreamWriter(Console.OpenStandardOutput(), Encoding.Default);
            stdOut.AutoFlush = true;
            Console.SetOut(stdOut);
            Console.SetError(stdOut);
        }
        else
        {
            AllocConsole();
            var stdOut = new StreamWriter(Console.OpenStandardOutput(), Encoding.Default);
            stdOut.AutoFlush = true;
            Console.SetOut(stdOut);
            Console.SetError(stdOut);
        }
    }
}
