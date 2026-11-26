#!/bin/sh
# Isolated process tests: every launched controller is a temporary dummy script.
set -eu
source="$(dirname "$0")/S96bedee-photocell"
fixture=$(mktemp -d "${TMPDIR:-/tmp}/bedee-service-test.XXXXXX")
ctl() { /bin/sh "$fixture/init.sh" "$@"; }
cleanup() {
    ctl stop >/dev/null 2>&1 || :
    rm -f "$fixture/lock/pid" "$fixture/supervisor/pid" "$fixture/supervisor/last-exit"
    rmdir "$fixture/lock" "$fixture/supervisor" 2>/dev/null || :
    rm -f "$fixture/init.sh" "$fixture/daemon.sh" "$fixture/bin/logger" \
        "$fixture/mode" "$fixture/count" "$fixture/child" "$fixture/output" \
        "$fixture/service.log" "$fixture/service.log.1" "$fixture/disabled" \
        "$fixture/init-original.sh" "$fixture/stopping" "$fixture/stopped"
    rmdir "$fixture/bin" "$fixture"
}
trap cleanup EXIT
mkdir "$fixture/bin"
printf '#!/bin/sh\nexit 0\n' > "$fixture/bin/logger"
chmod 755 "$fixture/bin/logger"
PATH="$fixture/bin:$PATH"
export PATH
sed -e "s|^DAEMON=.*|DAEMON=$fixture/daemon.sh|" \
    -e "s|^LOCK=.*|LOCK=$fixture/lock|" \
    -e "s|^SUPERVISOR=.*|SUPERVISOR=$fixture/supervisor|" \
    -e "s|^LOG=.*|LOG=$fixture/service.log|" \
    -e "s|^DISABLED=.*|DISABLED=$fixture/disabled|" "$source" > "$fixture/init.sh"
cat > "$fixture/daemon.sh" <<'DUMMY'
#!/bin/sh
fixture=${0%/*}
count=$(cat "$fixture/count")
count=$((count + 1))
echo "$count" > "$fixture/count"
echo $$ > "$fixture/child"
cleanup() {
    if [ "$(cat "$fixture/lock/pid" 2>/dev/null)" = "$$" ]; then
        rm -f "$fixture/lock/pid"
        rmdir "$fixture/lock"
    fi
}
# Match production startup: publish the lock before installing cleanup traps.
case "$(cat "$fixture/mode")" in
    startup-stop)
        mkdir "$fixture/lock" || exit 2
        echo $$ > "$fixture/lock/pid"
        # Hold this trap-free window until the test stops the worker.
        while :; do sleep 0.1; done;;
esac
trap cleanup EXIT
trap 'exit 0' TERM INT
case "$(cat "$fixture/mode")" in
    early-zero) exit 0;;
    early-error) exit 7;;
    crash-once) [ "$count" -ne 1 ] || exit 7;;
    delayed) sleep 2;;
    never) while :; do sleep 0.1; done;;
    stop-before-wait|stop-during-wait)
        trap 'touch "$fixture/stopping"; sleep 2; touch "$fixture/stopped"; exit 0' TERM INT;;
esac
mkdir "$fixture/lock" || exit 2
echo $$ > "$fixture/lock/pid"
while :; do sleep 0.1; done
DUMMY
reset() {
    ctl stop >/dev/null 2>&1 || :
    rm -f "$fixture/lock/pid"
    rmdir "$fixture/lock" 2>/dev/null || :
    rm -f "$fixture/disabled"
    echo "$1" > "$fixture/mode"
    echo 0 > "$fixture/count"
}
ready() {
    for attempt in 1 2 3 4 5 6 7 8 9 10 11 12; do
        if ctl status > "$fixture/output"; then
            grep -q ', supervised)' "$fixture/output"
            return 0
        fi
        sleep 1
    done
    echo 'FAIL: supervised controller did not recover' >&2
    return 1
}

reset ready
awk 'BEGIN { for (i=0; i<17000; i++) printf "x" }' > "$fixture/service.log"
ctl start
ready
[ -f "$fixture/service.log.1" ]
[ "$(wc -c < "$fixture/service.log")" -lt 16384 ]
first_supervisor=$(cat "$fixture/supervisor/pid")
( cd "$fixture"; /bin/sh ./init.sh status | grep -q ', supervised)' )
ctl start
[ "$(cat "$fixture/count")" -eq 1 ]
[ "$(cat "$fixture/supervisor/pid")" = "$first_supervisor" ]
ctl stop
sleep 6
[ "$(cat "$fixture/count")" -eq 1 ]
[ ! -d "$fixture/lock" ] && [ ! -d "$fixture/supervisor" ]
echo 'PASS ready, duplicate start, bounded logs, and deliberate stop'

reset delayed
ctl start
ready
echo 'PASS delayed PID readiness'

for mode in early-zero early-error; do
    reset "$mode"
    started=$(date +%s)
    rc=0
    ctl start > "$fixture/output" 2>&1 || rc=$?
    [ "$rc" -eq 1 ] && [ "$(($(date +%s) - started))" -le 4 ]
    grep -q 'exited before becoming ready' "$fixture/output"
    ctl stop
    echo "PASS $mode fails promptly and stop cancels restart"
done

# TERM before the worker installs its traps must not prevent a later start.
for ownership in own foreign; do
    reset startup-stop
    ctl start
    startup_child=$(cat "$fixture/child")
    if [ "$ownership" = foreign ]; then echo 1 > "$fixture/lock/pid"; fi
    ctl stop
    if kill -0 "$startup_child" 2>/dev/null; then
        echo 'FAIL startup worker survived stop' >&2
        exit 1
    fi
    [ ! -d "$fixture/supervisor" ]
    if [ "$ownership" = own ]; then
        [ ! -d "$fixture/lock" ]
        reset ready
        ctl start
        ctl stop
        echo 'PASS startup stop reclaims own lock and permits restart'
    else
        [ "$(cat "$fixture/lock/pid")" = 1 ]
        echo 'PASS startup stop preserves a foreign lock'
    fi
done

reset never
started=$(date +%s)
rc=0
timeout 14 /bin/sh "$fixture/init.sh" start > "$fixture/output" 2>&1 || rc=$?
[ "$rc" -eq 1 ] && [ "$(($(date +%s) - started))" -le 13 ]
grep -q 'startup timed out' "$fixture/output"
kill -0 "$(cat "$fixture/child")"
ctl stop
echo 'PASS live child without PID times out without blocking wait'

reset crash-once
ctl start > "$fixture/output" 2>&1 || :
ready
[ "$(cat "$fixture/count")" -eq 2 ]
grep -q 'exited with status 7' "$fixture/service.log"
echo 'PASS unexpected early exit automatically recovers'

reset ready
ctl start
first_child=$(cat "$fixture/child")
kill -KILL "$first_child"
sleep 1
ready
[ "$(cat "$fixture/count")" -eq 2 ]
[ "$(cat "$fixture/child")" != "$first_child" ]
echo 'PASS killed child recovers and its own stale lock is reclaimed'

reset ready
mkdir "$fixture/lock"
echo 1 > "$fixture/lock/pid"
if ctl start >/dev/null 2>&1; then echo 'FAIL unverified lock accepted'; exit 1; fi
[ "$(cat "$fixture/lock/pid")" = 1 ] && [ "$(cat "$fixture/count")" -eq 0 ]
echo 'PASS unverified lock is preserved'

reset ready
touch "$fixture/disabled"
ctl start
[ "$(cat "$fixture/count")" -eq 0 ] && [ ! -d "$fixture/supervisor" ]
echo 'PASS disable marker prevents startup'

# Inject signals at the two supervisor wait boundaries without touching hardware.
cp "$fixture/init.sh" "$fixture/init-original.sh"
for mode in stop-before-wait stop-during-wait; do
    reset "$mode"
    rm -f "$fixture/stopping" "$fixture/stopped"
    awk -v mode="$mode" '
        /        waiting=\$child/ {
            print "        while [ ! -f \"$LOCK/pid\" ]; do sleep 0.1; done"
            if (mode == "stop-before-wait") print "        kill -TERM \"$$\""
        }
        { print }
        /        waiting=\$child/ {
            if (mode == "stop-during-wait") print "        (sleep 0.2; kill -TERM \"$$\") &"
        }
    ' "$fixture/init-original.sh" > "$fixture/init.sh"
    /bin/sh "$fixture/init.sh" supervise &
    test_supervisor=$!
    for attempt in 1 2 3 4 5; do
        [ ! -f "$fixture/stopping" ] || break
        sleep 0.2
    done
    [ -f "$fixture/stopping" ]
    kill -0 "$test_supervisor"
    [ -f "$fixture/supervisor/pid" ]
    for attempt in 1 2 3 4 5; do
        [ ! -f "$fixture/stopped" ] || break
        sleep 1
    done
    [ -f "$fixture/stopped" ]
    wait "$test_supervisor"
    [ ! -d "$fixture/lock" ] && [ ! -d "$fixture/supervisor" ]
    [ "$(cat "$fixture/count")" -eq 1 ]
    echo "PASS $mode signals worker and waits for cleanup"
done
