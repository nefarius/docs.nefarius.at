#!/bin/sh
# Offline only: replace every hardware/API/time boundary before calling run.
set -eu
controller="$(dirname "$0")/bedee-photocell.sh"
set -- library
. "$controller"
set --
fixture=$(mktemp -d "${TMPDIR:-/tmp}/bedee-photocell-test.XXXXXX")
scenario() (
    LOCK="$fixture/lock"
    echo 0 > "$fixture/clock"
    echo "$2" > "$fixture/state"
    : > "$fixture/calls"
    : > "$fixture/registers"
    test_case=$1
    duration=$3
    id() { echo 0; }
    log() { :; }
    devmem() {
        if [ "$#" -eq 2 ]; then echo 0x00000000
        else printf '%s\n' "$*" >> "$fixture/registers"
        fi
    }
    now_seconds() { cat "$fixture/clock"; }
    adc_read() {
        tick=$(cat "$fixture/clock")
        case "$test_case" in
            day|api-down) echo 0;;
            night|reject|foreign) echo 255;;
            shadow) if [ "$tick" -lt 5 ]; then echo 255; else echo 0; fi;;
            hysteresis)
                if [ "$tick" -lt 8 ]; then echo 255
                elif [ "$tick" -lt 12 ]; then echo 50
                else echo 255
                fi;;
            adc-fail) return 1;;
        esac
    }
    http() {
        tick=$(cat "$fixture/clock")
        case "$1" in
            /metrics/night)
                [ "$test_case" != api-down ] || [ "$tick" -ge 10 ] || return 1
                printf 'night_enabled %s\n' "$(cat "$fixture/state")"
                if [ "$test_case" = foreign ]; then echo 'night_mode_source 4'
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
if scenario foreign 0 40; then echo 'FAIL competing controller accepted'; exit 1; fi
assert_calls 'competing controller stops' ''
if scenario adc-fail 0 40; then echo 'FAIL failed ADC accepted'; exit 1; fi
assert_calls 'ADC failure stops' ''
rm "$fixture/clock" "$fixture/state" "$fixture/calls" "$fixture/registers" "$fixture/restored" "$fixture/expected"
rmdir "$fixture"
