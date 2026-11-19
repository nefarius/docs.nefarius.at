#!/bin/sh
# Bedee Hi3518EV200/SC2235 only. ADC sequence recovered from its stock saradc.ko.
# Requires Majestic lightMonitor=false, irCut=auto, backlight=auto.
# No YAML or flash writes. Run in foreground until the hardware trial passes.

DAY_LIMIT=30
NIGHT_LIMIT=90
DAY_DELAY=60
NIGHT_DELAY=15
LOCK=/tmp/bedee-photocell.lock
API=http://127.0.0.1
LOG=/tmp/bedee-photocell.log

log() {
    umask 077
    if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -ge 16384 ]; then
        mv -f "$LOG" "$LOG.1"
    fi
    log_uptime=unknown
    read -r log_uptime log_rest < /proc/uptime || log_uptime=unknown
    printf 'uptime=%s %s\n' "${log_uptime%%.*}" "$*" >> "$LOG" || :
    printf '%s\n' "$*"
    logger -t bedee-photocell "$*" || :
}
http() { curl -fsS --connect-timeout 2 --max-time 4 "$API$1"; }
word() {
    case "$1" in
        0x????????) case "${1#0x}" in *[!0-9a-fA-F]*) return 1;; esac;;
        *) return 1;;
    esac
}
now_seconds() {
    read -r uptime remainder < /proc/uptime || return 1
    uptime=${uptime%%.*}
    case "$uptime" in ''|*[!0-9]*) return 1;; esac
    printf '%s\n' "$uptime"
}
adc_read() {
    devmem 0x200b001c 32 15 >/dev/null || return 1
    sleep 0.1
    raw=$(devmem 0x200b000c 32) || return 1
    devmem 0x200b0018 32 1 >/dev/null || return 1
    word "$raw" || return 1
    printf '%s\n' "$((raw & 255))"
}
classify() {
    if [ "$1" -le "$DAY_LIMIT" ]; then echo 0
    elif [ "$1" -ge "$NIGHT_LIMIT" ]; then echo 1
    else echo hold
    fi
}
cleanup() {
    exit_status=$?
    trap - EXIT INT TERM
    log "Controller exiting with status $exit_status."
    if [ "$adc_started" = 1 ]; then
        devmem 0x200b0010 32 0 >/dev/null
        devmem 0x200b0000 32 "$saved_ctrl" >/dev/null
        devmem 0x200b0010 32 "$saved_enable" >/dev/null
    fi
    if [ "$(cat "$LOCK/pid" 2>/dev/null)" = "$$" ]; then
        rm -f "$LOCK/pid"
        rmdir "$LOCK"
    fi
}
run() {
    umask 077
    [ "$(id -u)" = 0 ] || { echo 'Run as root.' >&2; return 1; }
    stop_pending=0
    trap 'stop_pending=1' INT TERM
    trap '' HUP
    mkdir "$LOCK" 2>/dev/null || {
        trap - INT TERM HUP
        echo "Lock exists: $LOCK. Check for a running controller before removing it." >&2
        return 1
    }
    echo $$ > "$LOCK/pid"
    adc_started=0
    trap cleanup EXIT
    trap 'exit 0' INT TERM
    [ "$stop_pending" = 0 ] || exit 0
    for addr in 0x200f015c 0x200f0160; do
        mux=$(devmem "$addr" 32) || return 1
        word "$mux" || return 1
        [ "$((mux & 1))" = 0 ] || {
            log "Unexpected ADC pin mux at $addr; stopping without changing it."
            return 1
        }
    done
    saved_ctrl=$(devmem 0x200b0000 32) || return 1
    saved_enable=$(devmem 0x200b0010 32) || return 1
    word "$saved_ctrl" && word "$saved_enable" || return 1
    adc_started=1
    devmem 0x200b0000 32 0xff0201ff >/dev/null || return 1
    devmem 0x200b0010 32 1 >/dev/null || return 1
    pending=hold
    since=0
    unavailable=0
    adc_failures=0
    paused=
    clock_failed=0
    log "Photocell controller started: day <=$DAY_LIMIT for ${DAY_DELAY}s; night >=$NIGHT_LIMIT for ${NIGHT_DELAY}s."
    while :; do
        if ! metrics=$(http /metrics/night); then
            [ "$unavailable" = 1 ] || log 'Majestic unavailable; holding the current filter position.'
            unavailable=1
            pending=hold
            sleep 5
            continue
        fi
        [ "$unavailable" = 0 ] || log 'Majestic is responding again.'
        unavailable=0
        source=$(printf '%s\n' "$metrics" | awk '$1=="night_mode_source" {print $2; exit}')
        state=$(printf '%s\n' "$metrics" | awk '$1=="night_enabled" {print $2; exit}')
        if [ "$source" != 0 ]; then
            if [ "$paused" != source ]; then
                log "Night-mode source is '$source'; pausing until the manual source returns."
            fi
            paused=source
            pending=hold
            sleep 5
            continue
        fi
        case "$state" in
            0|1) ;;
            *)
                [ "$paused" = status ] || log 'Invalid night-mode status; holding and retrying.'
                paused=status
                pending=hold
                sleep 5
                continue;;
        esac
        [ -z "$paused" ] || log 'Night-mode status recovered; restarting the switching delay.'
        paused=
        # A failed conversion must not end monitoring or count toward a switch.
        value=
        for attempt in 1 2 3; do
            if value=$(adc_read); then break; fi
            pending=hold
            value=
            [ "$attempt" = 3 ] || sleep 1
        done
        if [ -z "$value" ]; then
            if [ "$((adc_failures % 12))" = 0 ]; then
                log 'ADC reads failed after three attempts; holding the current mode and retrying after 5 seconds.'
            fi
            adc_failures=$((adc_failures + 1))
            sleep 5
            continue
        fi
        if [ "$adc_failures" != 0 ] || [ "$attempt" != 1 ]; then
            log 'ADC reads recovered; restarting the switching delay.'
        fi
        adc_failures=0
        target=$(classify "$value")
        if ! now=$(now_seconds); then
            [ "$clock_failed" = 1 ] || log 'Uptime read failed; holding and retrying.'
            clock_failed=1
            pending=hold
            sleep 5
            continue
        fi
        [ "$clock_failed" = 0 ] || log 'Uptime reads recovered; restarting the switching delay.'
        clock_failed=0
        if [ "$target" = hold ] || [ "$target" = "$state" ]; then
            pending=hold
        elif [ "$pending" != "$target" ]; then
            pending=$target
            since=$now
        else
            if [ "$target" = 1 ]; then delay=$NIGHT_DELAY; mode=on
            else delay=$DAY_DELAY; mode=off
            fi
            if [ "$((now - since))" -ge "$delay" ]; then
                if reply=$(http "/night/$mode") && [ "$reply" = "$target" ]; then
                    log "Majestic accepted night=$target (ADC=$value)."
                else
                    log 'Majestic did not accept the mode request; holding and restarting the delay.'
                    sleep 5
                fi
                pending=hold
            fi
        fi
        sleep 1
    done
}

# A library mode lets an offline harness exercise the actual functions safely.
case "${1:-run}" in
    run) run;;
    library) :;;
    *) echo "Usage: $0 [run]" >&2; exit 2;;
esac
