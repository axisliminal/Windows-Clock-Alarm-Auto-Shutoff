---
title: Testing and Verification Protocols
description: Protocols for verifying alarm detection, audio termination, countdown timers, idle gating, and missed alarm retention.
trigger: always_on
---

# Testing and Verification Protocols

## 1. Non-Disruptive Verification
- Verification must not require waiting 5 real minutes during iterative development.
- Implement and use accelerated test modes (e.g., 5-second or 10-second auto-shutoff presets) to validate the complete loop:
  1. Triggering an alarm-scenario toast.
  2. Detecting active ringing status.
  3. Reaching timeout threshold.
  4. Programmatically executing `RemoveNotification()`.
  5. Confirming audio cut-off and UI removal.

## 2. Audio Cut-Off Validation
- A successful dismissal requires both visual clearing of the toast AND immediate cessation of the looping alarm audio.
- Ensure audio stops within 500ms of calling `RemoveNotification()`.

## 3. User Intervention Verification
- Explicitly test manual dismissal: If the alarm is dismissed or snoozed manually before the timeout expires, verify that the utility resets its state cleanly and does not attempt redundant dismissal calls.

## 4. Smart Idle & Missed Alarm Retention Verification
- Verify that `smartIdleGating` is disabled by default (`smartIdleGating: false`) so alarms shut off deterministically out-of-the-box.
- When `smartIdleGating` is enabled, verify that active keyboard/mouse interaction (`GetIdleTimeSeconds() < 30`) defers alarm shutoff, but strictly enforces auto-dismissal once the 60-second hard grace ceiling (`effectiveThreshold + 60`) is reached.
- Ensure synthetic test alarms bypass idle gating to allow instant interactive verification.
- Verify that `Send-SilentMissedToast` posts a quiet notification to Windows Action Center with `silent="true"` and no looping audio when `notifyOnDismiss` is enabled.
