#!/usr/bin/env bash
# Proves, on the harness's emulator, that WorkManager keeps the background sync's job, that
# Doze defers it while the device is idle, and that it runs the dispatcher's engine in
# Doze's maintenance window (docs/reference/background.md, **Testing**). It does not prove
# a sync under Doze: in the demo flavor the cycle returns at its first step ("background:
# demo, nothing to sync"), and a real sync against the dev server under Doze is the
# coordinator's dev-flavor acceptance. Run it only through the harness, which boots
# ft-lane under the machine-wide lock and exports its serial:
#   tools/emulator_tests.sh run tools/scripts/background_doze_check.sh
# 1. unplugs the battery and sets it low, then runs
#    app/integration_test/background_sync_test.dart in the demo flavor with
#    `--no-uninstall`, so the periodic sync it schedules afresh with the real plugin stays,
#    its first run (no initial delay) held back by its battery-not-low constraint and so
#    still due later; the test's end stops the app, which drops its jobs, so WorkManager's
#    diagnostics broadcast (a debug build's) starts the app's process in the background,
#    where WorkManager registers them again;
# 2. checks the sync has not run, and finds the registered WorkManager job's id (and, on
#    Android 14 and later, its namespace) in `dumpsys jobscheduler` (assigned per device,
#    so looked up each time);
# 3. ends the app's background process (`am kill`, which keeps its jobs: Doze holds no
#    running app's jobs back while it serves a receiver), waits until `dumpsys
#    deviceidle tempwhitelist` no longer lists the app (the shell's broadcast puts it on
#    Doze's temporary allowlist, where its jobs run even while idle) and refuses an app
#    on the permanent one, forces the device idle (`dumpsys deviceidle force-idle`) and
#    lets the battery be no longer low;
# 4. reads, from `dumpsys jobscheduler`, the job's implicit `readyNotDozing: false`: Doze
#    defers it, as JobScheduler says, not as a timed absence suggests. That line alone is
#    the evidence; the job's CONNECTIVITY constraint may read satisfied or not meanwhile;
# 5. steps Doze to its maintenance window (`dumpsys deviceidle step deep`) and waits for
#    the task's line in the log. Nothing forces the job (`cmd jobscheduler run -f` would
#    override its constraints), so only the maintenance window's run counts;
# 6. on exit, whatever happened, lets the device out of idle, resets the battery and
#    uninstalls the demo app.
# Exits 0 only on the maintenance window's run; otherwise it says which step failed and
# prints the job's constraint lines (and the log when the task never ran). Talks only to
# the serial the harness gives it; installs only the demo flavor.
set -uo pipefail

cd "$(dirname "$0")/../.."

: "${FT_EMULATOR_SERIAL:?run through tools/emulator_tests.sh run}"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
adb() { "$SDK/platform-tools/adb" -s "$FT_EMULATOR_SERIAL" "$@"; }
if [ -f .fvmrc ] && command -v fvm >/dev/null 2>&1; then
  FLUTTER="fvm flutter"
else
  FLUTTER="flutter"
fi
PACKAGE="dev.tarnan.financetracker.demo"
say() { echo "doze_check: $*"; }

restore() {
  adb shell dumpsys deviceidle unforce >/dev/null 2>&1
  adb shell dumpsys battery reset >/dev/null 2>&1
  adb uninstall "$PACKAGE" >/dev/null 2>&1
}
trap restore EXIT

adb logcat -c
# A low battery holds the newly scheduled sync back (its constraint is a battery not low),
# so its first run is still due when the device is idle.
adb shell dumpsys battery unplug
adb shell dumpsys battery set level 5
say "scheduling the periodic sync (integration_test/background_sync_test.dart)"
# Kept installed after the test, so its scheduled work stays; the app's process ends with
# the test, as when the user has left the app.
(cd app && $FLUTTER test integration_test/background_sync_test.dart \
  --flavor demo -d "$FT_EMULATOR_SERIAL" --no-uninstall) || { say "the test failed"; exit 1; }
# The test's end stops the app, and Android drops a stopped app's jobs. WorkManager puts
# them back when the app's process next starts: its diagnostics receiver starts it in the
# background (a debug build's).
# (0x20, FLAG_INCLUDE_STOPPED_PACKAGES: a stopped app gets no broadcast otherwise)
adb shell am broadcast -f 0x20 -a androidx.work.diagnostics.REQUEST_DIAGNOSTICS \
  -p "$PACKAGE" >/dev/null

# Held back by the battery, the first run must not have happened.
sleep 10
if adb logcat -d | grep -q "background: demo, nothing to sync"; then
  say "the sync ran before the device was idle; the battery did not hold it back"
  exit 1
fi

# The registered jobs are listed, indented, under "Registered <n> jobs:", as
# `JOB [<namespace>:]u0a<app id>/<job id>: <hash> [@<namespace>@]<package>/...` (WorkManager
# puts its jobs in a namespace on Android 14 and later); the app's uid picks this app's.
uid="$(adb shell pm list packages -U "$PACKAGE" | tr -d '\r' |
  sed -nE "s/^package:$PACKAGE uid:([0-9]+).*/\1/p" | head -1)"
[ -n "$uid" ] || { say "$PACKAGE is not installed"; exit 1; }
user="u0a$((uid - 10000))"
registered="$(adb shell dumpsys jobscheduler | tr -d '\r' |
  awk '/^Registered [0-9]+ jobs:/ {on=1; next} on && /^[^ ]/ {on=0} on')"
job="$(echo "$registered" |
  grep -E "[#: ]$user/[0-9]+.*$PACKAGE/androidx\.work\.impl\.background\.systemjob\.SystemJobService" |
  head -1)"
if [ -z "$job" ]; then
  say "no registered WorkManager job for $PACKAGE ($user); WorkManager's log:"
  adb logcat -d | grep -E "WM-" | tail -20
  exit 1
fi
id="$(echo "$job" | sed -E "s/.*[#: ]$user\/([0-9]+).*/\1/")"
namespace="$(echo "$job" | sed -nE "s/.*@([^@ ]+)@$PACKAGE\/.*/\1/p")"
say "job: ${job# }"
say "job id: $id${namespace:+, namespace $namespace}"

# Nothing of the app runs: the process the broadcast started goes (`am kill` ends only a
# process in the background and keeps its jobs), since Doze holds no running app's jobs
# while it serves a receiver.
adb shell am kill "$PACKAGE"
# The shell's broadcast puts the app on Doze's temporary allowlist for a while, and an app
# on an allowlist runs its jobs even while the device is idle: wait until deviceidle no
# longer lists it, and refuse an app on the permanent one.
if adb shell dumpsys deviceidle whitelist | tr -d '\r' | grep -q ",$PACKAGE,"; then
  say "$PACKAGE is on Doze's permanent allowlist: Doze would not hold its jobs"
  exit 1
fi
allowlisted() { adb shell dumpsys deviceidle tempwhitelist | tr -d '\r' | grep -q "$PACKAGE"; }
for _ in $(seq 1 180); do
  allowlisted || break
  sleep 1
done
if allowlisted; then
  say "$PACKAGE stayed on Doze's temporary allowlist for three minutes"
  exit 1
fi
say "off Doze's allowlists"

adb shell dumpsys deviceidle force-idle
state="$(adb shell dumpsys deviceidle get deep | tr -d '\r')"
say "idle state: $state"
[ "$state" = "IDLE" ] || { say "the device did not go idle"; exit 1; }
# Idle, with the battery no longer low: the sync is due and its own constraints are met,
# so only Doze can hold it now.
adb shell dumpsys battery set level 100
adb logcat -c

ran() { adb logcat -d | grep -m1 "background: demo, nothing to sync" | tr -d '\r'; }
# This job's entry among the registered jobs: its constraint lines and whether it is
# ready.
constraints() {
  adb shell dumpsys jobscheduler | tr -d '\r' |
    awk -v key="$user/$id:" '/^[^ ]/ {on = 0} /^ *JOB / {on = index($0, key) > 0} on' |
    grep -E "(Required|Satisfied|Unsatisfied) constraints:|readyNotDozing|Ready:" |
    sed -E 's/^ +//'
}
# Doze holds the job: its implicit not-dozing constraint is not met.
deferred() { constraints | grep -E "^readyNotDozing: false"; }

# JobScheduler must report the job held by Doze: readyNotDozing false, whatever its
# network constraint reads meanwhile.
for _ in $(seq 1 30); do
  [ -n "$(ran)" ] && break
  [ -n "$(deferred)" ] && break
  sleep 1
done
if [ -n "$(ran)" ]; then
  say "the sync ran while the device was idle, so Doze did not defer it: $(ran)"
  constraints | sed 's/^/doze_check:   /'
  exit 1
fi
if [ -z "$(deferred)" ]; then
  say "JobScheduler never reported the job deferred by Doze; its constraints:"
  constraints | sed 's/^/doze_check:   /'
  exit 1
fi
say "deferred by Doze: $(deferred)"

# Doze's maintenance window runs what it deferred; nothing forces the job.
say "stepping to the maintenance window: $(adb shell dumpsys deviceidle step deep | tr -d '\r')"
for _ in $(seq 1 90); do
  if [ -n "$(ran)" ]; then
    say "the task ran in Doze's maintenance window: $(ran)"
    exit 0
  fi
  sleep 1
done
say "the task did not run in the maintenance window; its constraints, then the log:"
constraints | sed 's/^/doze_check:   /'
adb logcat -d | grep -E "WM-|flutter|orkmanager|BackgroundWorker|AndroidRuntime" | tail -40
exit 1
