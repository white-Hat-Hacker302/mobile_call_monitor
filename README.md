# Mobile Call Monitor

**Coded by Cyber Security Engineer Mr Sabaz Ali Khan**

A Bash-based Android ADB utility that monitors call-state changes on an Android device you own or are authorized to test.

## Features

- Detects Android device through ADB
- Watches call-state changes such as IDLE, RINGING, OFFHOOK/ACTIVE, DIALING
- Attempts to identify incoming/outgoing direction when Android exposes it
- Saves timestamped events to:
  `~/mobile_call_monitor/call_events.log`
- Does **not** record call audio
- Does **not** bypass Android permissions or carrier security

## Requirements

- Linux, Kali Linux, Ubuntu, Termux environment with ADB support, or WSL with USB/ADB configured
- Android Platform Tools (`adb`)
- USB Debugging enabled on your own Android phone

### Kali / Debian / Ubuntu

```bash
sudo apt update
sudo apt install adb
```

## Run

```bash
chmod +x mobile_call_monitor.sh
./mobile_call_monitor.sh
```

Connect your Android phone by USB and approve the RSA debugging prompt.

## Important Android limitation

Modern Android versions restrict phone-number and call information. This project monitors call **state** using diagnostic information exposed through ADB. Phone numbers may not be available, and the script intentionally does not attempt to bypass those protections.

## Authorized use only

Use this project only on devices you own or have explicit permission to monitor.
