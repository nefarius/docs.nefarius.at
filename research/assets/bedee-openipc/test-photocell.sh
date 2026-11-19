#!/bin/sh
# Offline only: replace every hardware/API/time boundary before calling run.
set -eu
controller="$(dirname "$0")/bedee-photocell.sh"
set -- library
. "$controller"
set --
fixture=$(mktemp -d "${TMPDIR:-/tmp}/bedee-photocell-test.XXXXXX")
# Exercise the actual startup code with TERM on either side of lock creation.
for boundary in before-mkdir before-pid; do
    /bin/sh -s "$controller" "$fixture" "$boundary" <<'STARTUP'
controller=$1
fixture=$2
boundary=$3
set -- library
. "$controller"
LOCK="$fixture/startup-lock"
id() { echo 0; }
log() { :; }
devmem() { echo 'FAIL startup stop reached hardware access' >&2; return 1; }
mkdir() {
    if [ "$boundary" = before-mkdir ]; then kill -TERM "$$"; fi
    command mkdir "$@" || return 1
    if [ "$boundary" = before-pid ]; then kill -TERM "$$"; fi
}
run
echo 'FAIL pending startup stop was not honored' >&2
exit 1
STARTUP
    [ ! -d "$fixture/startup-lock" ] || { echo "FAIL $boundary leaked a lock"; exit 1; }
    echo "PASS TERM $boundary is deferred and owned lock removed"
done
scenario() (
    LOCK="$fixture/lock"
    echo 0 > "$fixture/clock"
    echo "$2" > "$fixture/state"
    : > "$fixture/calls"
    : > "$fixture/registers"
    : > "$fixture/log"
    test_case=$1
    duration=$3
    id() { echo 0; }
    log() { printf '%s\n' "$*" >> "$fixture/log"; }
    devmem() {
        if [ "$#" -eq 2 ]; then echo 0x00000000
        else printf '%s\n' "$*" >> "$fixture/registers"
        fi
    }
    now_seconds() {
        tick=$(cat "$fixture/clock")
        [ "$test_case" != clock-fail ] || [ "$tick" -ge 5 ] || return 1
        echo "$tick"
    }
    adc_read() {
        tick=$(cat "$fixture/clock")
        case "$test_case" in
            day|api-down) echo 0;;
            night|reject|foreign|foreign-recover|missing-source|invalid-state|clock-fail) echo 255;;
            shadow) if [ "$tick" -lt 5 ]; then echo 255; else echo 0; fi;;
            hysteresis)
                if [ "$tick" -lt 8 ]; then echo 255
                elif [ "$tick" -lt 12 ]; then echo 50
                else echo 255
                fi;;
            adc-fail) return 1;;
            adc-transient)
                [ "$tick" -ne 5 ] || return 1
                echo 255;;
            adc-transient-day)
                [ "$tick" -ne 5 ] || return 1
                echo 0;;
            adc-recover)
                [ "$tick" -ge 10 ] || return 1
                echo 255;;
        esac
    }
    http() {
        tick=$(cat "$fixture/clock")
        case "$1" in
            /metrics/night)
                [ "$test_case" != api-down ] || [ "$tick" -ge 10 ] || return 1
                if [ "$test_case" = invalid-state ] && [ "$tick" -lt 10 ]; then echo 'night_enabled invalid'
                else printf 'night_enabled %s\n' "$(cat "$fixture/state")"
                fi
                if [ "$test_case" = missing-source ] && [ "$tick" -lt 10 ]; then :
                elif [ "$test_case" = foreign ] || { [ "$test_case" = foreign-recover ] && [ "$tick" -lt 10 ]; }; then echo 'night_mode_source 4'
                else echo 'night_mode_source 0'
                fi;;
            /night/on|/night/off)
                printf '%s %s\n' "$tick" "$1" >> "$fixture/calls"
                [ "$test_case" != reject ] || { echo 0; return 0; }
                case "$1" in /night/on) echo 1;; /night/off) echo 0;; esac > "$fixture/state"
                cat "$fixture/state";;
            *) return 1;;
        esac
    }
    sleep() {
        tick=$(cat "$fixture/clock")
        tick=$((tick + $1))
        echo "$tick" > "$fixture/clock"
        [ "$tick" -lt "$duration" ] || exit 0
    }
    run
)
assert_calls() {
    actual=$(cat "$fixture/calls")
    [ "$actual" = "$2" ] || { echo "FAIL $1: actual [$actual], expected [$2]" >&2; exit 1; }
    [ ! -d "$fixture/lock" ] || { echo "FAIL $1: lock leaked" >&2; exit 1; }
    tail -n 3 "$fixture/registers" > "$fixture/restored"
    printf '%s\n' '0x200b0010 32 0' '0x200b0000 32 0x00000000' '0x200b0010 32 0x00000000' > "$fixture/expected"
    cmp "$fixture/restored" "$fixture/expected" || { echo "FAIL $1: ADC restore" >&2; exit 1; }
    echo "PASS $1"
}
scenario day 1 75
assert_calls day '60 /night/off'
scenario night 0 40
assert_calls night '15 /night/on'
scenario shadow 0 40
assert_calls 'brief shadow' ''
scenario hysteresis 0 40
assert_calls 'hysteresis resets delay' '27 /night/on'
scenario api-down 1 85
assert_calls 'API outage resets delay' '70 /night/off'
scenario reject 0 40
assert_calls 'rejected request is retried with delay' "15 /night/on
36 /night/on"
scenario foreign 0 30
assert_calls 'competing controller pauses switching' ''
scenario adc-fail 0 28
assert_calls 'persistent ADC failure holds mode without stopping' ''
[ "$(grep -c 'ADC reads failed' "$fixture/log")" -eq 1 ] || { echo 'FAIL ADC failure log spam'; exit 1; }
scenario adc-transient 0 25
assert_calls 'transient ADC failure resets night delay' '21 /night/on'
grep -q 'ADC reads recovered' "$fixture/log"
scenario missing-source 0 30
assert_calls 'missing API source recovers without exiting' '25 /night/on'
scenario invalid-state 0 30
assert_calls 'invalid API state recovers without exiting' '25 /night/on'
scenario foreign-recover 0 30
assert_calls 'manual source resumes after native switching' '25 /night/on'
scenario clock-fail 0 25
assert_calls 'clock read failure recovers with a fresh delay' '20 /night/on'
( read() { uptime=invalid; }; if now_seconds >/dev/null; then echo 'FAIL invalid uptime accepted'; exit 1; fi )
echo 'PASS invalid uptime rejected'
(
    LOG="$fixture/service.log"
    logger() { return 1; }
    awk 'BEGIN { for (i=0; i<17000; i++) printf "x" }' > "$LOG"
    log 'Retained event despite failed syslog.' >/dev/null
    [ -f "$LOG.1" ] && [ "$(wc -c < "$LOG")" -lt 16384 ]
    grep -q 'Retained event' "$LOG"
)
echo 'PASS bounded service log survives syslog failure'
rm -f "$fixture/service.log" "$fixture/service.log.1"
scenario adc-transient-day 1 70
assert_calls 'transient ADC failure resets day delay' '66 /night/off'
scenario adc-recover 0 35
assert_calls 'ADC recovery resumes automatic switching' '29 /night/on'
grep -q 'ADC reads failed' "$fixture/log"
grep -q 'ADC reads recovered' "$fixture/log"
rm "$fixture/clock" "$fixture/state" "$fixture/calls" "$fixture/registers" "$fixture/restored" "$fixture/expected" "$fixture/log"
rmdir "$fixture"
