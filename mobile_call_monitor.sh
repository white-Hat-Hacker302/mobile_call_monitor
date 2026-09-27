#!/usr/bin/env bash

# ============================================================
# Mobile Call Monitor - Android ADB Call-State Monitor
# Coded by Cyber Security Engineer Mr Sabaz Ali Khan
# Use only on devices you own or are authorized to monitor.
# ============================================================

set -u

BANNER='
▄▀▀▄    ▄▀▀▄  ▄▀▀▄ ▄▄   ▄▀▀▀▀▄       ▄▀▀█▄   ▄▀▀▄ ▄▀▄      ▄▀▀█▀▄
█   █    ▐  █ █  █   ▄▀ █      █     ▐ ▄▀ ▀▄ █  █ ▀  █     █   █  █
▐  █        █ ▐  █▄▄▄█  █      █       █▄▄▄█ ▐  █    █     ▐   █  ▐
  █   ▄    █     █   █  ▀▄    ▄▀      ▄▀   █   █    █          █
   ▀▄▀ ▀▄ ▄▀    ▄▀  ▄▀    ▀▀▀▀       █   ▄▀  ▄▀   ▄▀        ▄▀▀▀▀▀▄
         ▀     █   █                 ▐   ▐   █    █        █       █
               ▐   ▐                         ▐    ▐        ▐       ▐
 ▄▀▀▀▀▄    ▄▀▀▄▀▀▀▄  ▄▀▀▀▀▄   ▄▀▀▄ ▄▀▀▄  ▄▀▀▄▀▀▀▄
█         █   █   █ █      █ █   █    █ █   █   █
█    ▀▄▄  ▐  █▀▀█▀  █      █ ▐  █    █  ▐  █▀▀▀▀
█     █ █  ▄▀    █  ▀▄    ▄▀   █    █      █
▐▀▄▄▄▄▀ ▐ █     █     ▀▀▀▀      ▀▄▄▄▄▀   ▄▀
▐         ▐     ▐                       █
                                        ▐
'

AUTHOR="Coded by Cyber Security Engineer Mr Sabaz Ali Khan"
LOG_DIR="$HOME/mobile_call_monitor"
LOG_FILE="$LOG_DIR/call_events.log"
INTERVAL=1

GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

cleanup() {
    echo
    echo -e "${YELLOW}[!] Monitor stopped.${RESET}"
    echo -e "${CYAN}[*] Log file: $LOG_FILE${RESET}"
    exit 0
}
trap cleanup INT TERM

print_banner() {
    clear 2>/dev/null || true
    echo -e "${GREEN}${BANNER}${RESET}"
    echo -e "${CYAN}${AUTHOR}${RESET}"
    echo
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo -e "${RED}[X] Missing dependency: $1${RESET}"
        echo "Install Android Platform Tools (adb) and try again."
        exit 1
    }
}

check_device() {
    adb start-server >/dev/null 2>&1 || true

    local count
    count="$(adb devices | awk 'NR>1 && $2=="device"{c++} END{print c+0}')"

    if [ "$count" -eq 0 ]; then
        echo -e "${RED}[X] No authorized Android device detected.${RESET}"
        echo
        echo "1. Enable Developer Options on your Android phone."
        echo "2. Enable USB Debugging."
        echo "3. Connect the phone with USB."
        echo "4. Accept the RSA debugging prompt on the phone."
        echo "5. Run this script again."
        exit 1
    elif [ "$count" -gt 1 ]; then
        echo -e "${YELLOW}[!] More than one Android device is connected.${RESET}"
        echo "Disconnect extra devices or set ANDROID_SERIAL before running."
        exit 1
    fi
}

device_name() {
    local manufacturer model android
    manufacturer="$(adb shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r')"
    model="$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
    android="$(adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')"

    echo -e "${CYAN}[*] Device : ${manufacturer:-Unknown} ${model:-Unknown}${RESET}"
    echo -e "${CYAN}[*] Android: ${android:-Unknown}${RESET}"
}

get_call_state() {
    local out state

    # Try modern telecom output first.
    out="$(adb shell dumpsys telecom 2>/dev/null | tr -d '\r')"

    if echo "$out" | grep -qiE 'RINGING|DIALING|ACTIVE|HOLDING|CONNECTING'; then
        if echo "$out" | grep -qi 'RINGING'; then
            echo "RINGING"
            return
        elif echo "$out" | grep -qi 'DIALING'; then
            echo "DIALING"
            return
        elif echo "$out" | grep -qi 'CONNECTING'; then
            echo "CONNECTING"
            return
        elif echo "$out" | grep -qi 'ACTIVE'; then
            echo "ACTIVE"
            return
        elif echo "$out" | grep -qi 'HOLDING'; then
            echo "HOLDING"
            return
        fi
    fi

    # Fallback to telephony registry. Values commonly map:
    # 0 = IDLE, 1 = RINGING, 2 = OFFHOOK
    out="$(adb shell dumpsys telephony.registry 2>/dev/null | tr -d '\r')"
    state="$(echo "$out" | grep -m1 -E 'mCallState=|mCallState ' | grep -oE '[0-2]' | head -n1)"

    case "$state" in
        0) echo "IDLE" ;;
        1) echo "RINGING" ;;
        2) echo "OFFHOOK" ;;
        *) echo "UNKNOWN" ;;
    esac
}

get_call_direction_hint() {
    local out
    out="$(adb shell dumpsys telecom 2>/dev/null | tr -d '\r')"

    if echo "$out" | grep -qiE 'isIncoming: true|incoming'; then
        echo "INCOMING"
    elif echo "$out" | grep -qiE 'isIncoming: false|outgoing'; then
        echo "OUTGOING"
    else
        echo "UNKNOWN"
    fi
}

log_event() {
    local state="$1"
    local direction="$2"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"

    printf '%s | state=%s | direction=%s\n' "$ts" "$state" "$direction" >> "$LOG_FILE"
    echo -e "${GREEN}[+] $ts${RESET} | ${YELLOW}$state${RESET} | direction=$direction"
}

main() {
    print_banner
    need_cmd adb
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"

    check_device
    device_name

    echo
    echo -e "${GREEN}[+] Monitoring call-state changes...${RESET}"
    echo -e "${CYAN}[*] Press Ctrl+C to stop.${RESET}"
    echo -e "${CYAN}[*] Logs: $LOG_FILE${RESET}"
    echo

    local previous_state=""
    local current_state=""
    local direction="UNKNOWN"

    while true; do
        if ! adb get-state >/dev/null 2>&1; then
            echo -e "${RED}[X] Device disconnected. Waiting...${RESET}"
            sleep 2
            continue
        fi

        current_state="$(get_call_state)"

        if [ "$current_state" != "$previous_state" ]; then
            if [ "$current_state" = "RINGING" ] || \
               [ "$current_state" = "DIALING" ] || \
               [ "$current_state" = "CONNECTING" ] || \
               [ "$current_state" = "ACTIVE" ] || \
               [ "$current_state" = "OFFHOOK" ]; then
                direction="$(get_call_direction_hint)"
            elif [ "$current_state" = "IDLE" ]; then
                direction="NONE"
            fi

            log_event "$current_state" "$direction"
            previous_state="$current_state"
        fi

        sleep "$INTERVAL"
    done
}

main "$@"
