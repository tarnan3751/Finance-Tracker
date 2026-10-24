#!/usr/bin/env bash
# The emulator harness: runs the app on the harness's own headless Android Virtual Device,
# `ft-lane`, under a machine-wide lock, so only one emulator run happens on the machine at a
# time (CLAUDE.md, **Seeing the app**, **Lanes**). Commands:
#   integration [-- <flutter test args>]   (the default) boot, then `flutter test
#                         integration_test --flavor demo -d <serial>` from app/; the in-app
#                         fakes only, never the dev server or Plaid Sandbox
#   demo [<screenshot>]   boot, build and install the demo flavor's debug APK, launch it, wait
#                         for its activity to take focus, and save a screenshot (default
#                         app/build/emulator/demo.png); prints the path
#   run <command...>      boot, then run the command with FT_EMULATOR_SERIAL exported
#   stop                  shut down the ft-lane emulator; refuses while a live run holds the lock
#   status                who holds the lock, and whether ft-lane is running and on which serial
# The script runs from the repository root: a relative screenshot path is relative to it, and
# `run` runs its command in it.
# integration, demo and run hold the lock for their whole run and release it on exit (normal,
# failure or signal) through a trap; the emulator is left running so the next run reuses it.
# Their long steps (flutter, sdkmanager, the run command) run as a background child that the
# script waits on, so SIGTERM or SIGINT takes effect at once: the trap stops the child and its
# descendants, then releases the lock, and exits 143 or 130.
# The lock is the directory ${TMPDIR:-/tmp}/finance-tracker-emulator.lock holding `pid`,
# `started` and `command`. It is built in a private directory beside it and taken with one
# rename, so it is never seen half-written (macOS has no flock). A waiter polls every 5 s for
# up to FT_EMULATOR_LOCK_TIMEOUT seconds (default 1800) and prints the holder every 60 s. A lock
# whose pid is dead, or one with no pid older than 30 s, is stale; a waiter reclaims it by
# renaming it away, so only one waiter wins.
# The AVD is created on first use from FT_AVD_IMAGE (default
# system-images;android-36;google_apis;arm64-v8a, installed with sdkmanager when missing) and
# lives in ~/.android/avd/ft-lane.avd. The script talks to an emulator only after
# `adb emu avd name` has confirmed it is ft-lane, so the owner's Pixel_* and Nexus_* emulators
# and any physical device are never touched. The SDK comes from ANDROID_HOME, else
# ANDROID_SDK_ROOT, else ~/Library/Android/sdk. Writes the AVD, the lock directory and
# app/build/ (the APK, the emulator log, the screenshot).
set -uo pipefail

cd "$(dirname "$0")/.."
root="$(pwd)"

AVD_NAME="ft-lane"
AVD_IMAGE="${FT_AVD_IMAGE:-system-images;android-36;google_apis;arm64-v8a}"
LOCK_DIR="${TMPDIR:-/tmp}"
LOCK_DIR="${LOCK_DIR%/}/finance-tracker-emulator.lock"
LOCK_TIMEOUT="${FT_EMULATOR_LOCK_TIMEOUT:-1800}"
BOOT_TIMEOUT=240
DEMO_PACKAGE="dev.tarnan.financetracker.demo"
OUT_DIR="$root/app/build/emulator"

die() { echo "emulator_tests: $*" >&2; exit 1; }
say() { echo "emulator_tests: $*"; }

if [ -f .fvmrc ] && command -v fvm >/dev/null 2>&1; then
  FLUTTER="fvm flutter"
else
  FLUTTER="flutter"
fi

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
ADB="$SDK/platform-tools/adb"
EMULATOR="$SDK/emulator/emulator"
AVDMANAGER="$SDK/cmdline-tools/latest/bin/avdmanager"
SDKMANAGER="$SDK/cmdline-tools/latest/bin/sdkmanager"

require_tools() {
  [ -d "$SDK" ] || die "no Android SDK at $SDK; set ANDROID_HOME to the SDK directory"
  [ -x "$ADB" ] || die "no adb at $ADB; install it with: $SDKMANAGER platform-tools"
  [ -x "$EMULATOR" ] || die "no emulator at $EMULATOR; install it with: $SDKMANAGER emulator"
  [ -x "$AVDMANAGER" ] || die "no avdmanager at $AVDMANAGER; install Android SDK Command-line Tools (latest) from Android Studio's SDK Manager"
  [ -x "$SDKMANAGER" ] || die "no sdkmanager at $SDKMANAGER; install Android SDK Command-line Tools (latest) from Android Studio's SDK Manager"
}

# The lock -------------------------------------------------------------------------------

CANDIDATE=""
CHILD=""

lock_holder() {
  echo "pid $(cat "$LOCK_DIR/pid" 2>/dev/null || echo '?'), since $(cat "$LOCK_DIR/started" 2>/dev/null || echo '?'), running: $(cat "$LOCK_DIR/command" 2>/dev/null || echo '?')"
}

# Seconds since the path was last modified.
age_of() {
  local mtime
  mtime="$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || date +%s)"
  echo $(($(date +%s) - mtime))
}

# A lock is stale when its process is gone, or when it has no pid and is older than 30 s: a lock
# is never half-written, so only a crash of an earlier version of this script leaves one.
lock_is_stale() {
  local pid
  pid="$(cat "$LOCK_DIR/pid" 2>/dev/null)"
  if [ -n "$pid" ]; then
    ! kill -0 "$pid" 2>/dev/null
  else
    [ -d "$LOCK_DIR" ] && [ "$(age_of "$LOCK_DIR")" -gt 30 ]
  fi
}

# Renames directory $1 to $2 only when $2 does not exist. macOS mv has no flag against moving
# into an existing directory, so a move that landed inside $2 is undone and reported as failed;
# rename(2) itself refuses to replace a non-empty directory, which every lock is.
rename_dir() {
  local src="$1" dst="$2" inside
  inside="$2/$(basename "$1")"
  [ -e "$dst" ] && return 1
  mv "$src" "$dst" 2>/dev/null || return 1
  if [ -d "$inside" ]; then
    mv "$inside" "$src" 2>/dev/null
    return 1
  fi
  return 0
}

# Builds the lock's contents in a private directory beside it and prints its path.
make_candidate() {
  local dir
  dir="$(mktemp -d "$LOCK_DIR.new.XXXXXX")" || die "cannot create a directory beside $LOCK_DIR"
  echo "$$" >"$dir/pid"
  date -u +%Y-%m-%dT%H:%M:%SZ >"$dir/started"
  echo "tools/emulator_tests.sh $*" >"$dir/command"
  echo "$dir"
}

# Renames a stale lock away and removes it. Of several waiters judging the same lock stale,
# only one wins the rename. A waiter that judged it just before another reclaimed it and took
# a fresh lock finds a different pid in what it renamed, and puts that lock back.
reclaim_stale() {
  local judged holder away="$LOCK_DIR.stale.$$"
  judged="$(cat "$LOCK_DIR/pid" 2>/dev/null)"
  holder="$(lock_holder)"
  rm -rf "$away"
  rename_dir "$LOCK_DIR" "$away" || return 0
  if [ "$(cat "$away/pid" 2>/dev/null)" != "$judged" ]; then
    rename_dir "$away" "$LOCK_DIR" || rm -rf "$away"
    return 0
  fi
  rm -rf "$away"
  say "reclaimed a stale lock ($holder)"
}

release_lock() {
  [ -n "$CANDIDATE" ] && rm -rf "$CANDIDATE"
  if [ "$(cat "$LOCK_DIR/pid" 2>/dev/null)" = "$$" ]; then
    rm -rf "$LOCK_DIR"
  fi
}

# Prints the pids of the descendants of $1, deepest first.
descendants() {
  local child
  for child in $(pgrep -P "$1"); do
    descendants "$child"
    echo "$child"
  done
}

alive() {
  local state
  state="$(ps -o stat= -p "$1" 2>/dev/null)"
  [ -n "$state" ] && [[ "$state" != Z* ]]
}

# Stops the running child and everything under it: TERM, up to 10 s, then KILL.
stop_child() {
  [ -n "$CHILD" ] || return 0
  local pids n=0
  pids="$(descendants "$CHILD") $CHILD"
  kill -TERM $pids 2>/dev/null
  while alive "$CHILD" && [ $n -lt 20 ]; do
    sleep 0.5
    n=$((n + 1))
  done
  kill -KILL $pids 2>/dev/null
  CHILD=""
}

on_signal() {
  stop_child
  exit "$1"
}

# Runs a command (or a function) as a background child and waits for it. bash runs a trap only
# after its foreground command ends; a signal interrupts `wait` at once, so the trap can stop
# the child before the lock is released. Standard input is passed through.
run_child() {
  "$@" <&0 &
  CHILD=$!
  wait "$CHILD"
  local status=$?
  CHILD=""
  return $status
}

acquire_lock() {
  local waited=0
  trap 'release_lock' EXIT
  trap 'on_signal 130' INT
  trap 'on_signal 143' TERM
  CANDIDATE="$(make_candidate "$@")"
  until rename_dir "$CANDIDATE" "$LOCK_DIR"; do
    # A holder that released with our candidate moved inside its lock took the candidate along.
    [ -d "$CANDIDATE" ] || CANDIDATE="$(make_candidate "$@")"
    if [ -d "$LOCK_DIR" ] && lock_is_stale; then
      reclaim_stale
      continue
    fi
    if [ $((waited % 60)) -eq 0 ]; then
      say "waiting for the emulator lock, held by $(lock_holder) (${waited}s of ${LOCK_TIMEOUT}s)"
    fi
    [ "$waited" -ge "$LOCK_TIMEOUT" ] && die "gave up after ${LOCK_TIMEOUT}s waiting for the lock held by $(lock_holder)"
    sleep 5
    waited=$((waited + 5))
  done
  CANDIDATE=""
}

# The AVD and the emulator ---------------------------------------------------------------

avd_name_of() {
  "$ADB" -s "$1" emu avd name 2>/dev/null | head -1 | tr -d '\r'
}

# Prints the serial of the running ft-lane emulator, if adb sees one.
our_serial() {
  local serial
  for serial in $("$ADB" devices | awk '$1 ~ /^emulator-[0-9]+$/ { print $1 }'); do
    if [ "$(avd_name_of "$serial")" = "$AVD_NAME" ]; then
      echo "$serial"
      return 0
    fi
  done
  return 1
}

assert_ours() {
  local name
  name="$(avd_name_of "$1")"
  [ "$name" = "$AVD_NAME" ] || die "refusing to use $1: it is AVD '${name:-unknown}', not $AVD_NAME"
}

install_image() {
  yes | "$SDKMANAGER" --install "$AVD_IMAGE" >"$OUT_DIR/sdkmanager.log" 2>&1
}

ensure_avd() {
  if "$EMULATOR" -list-avds 2>/dev/null | grep -qx "$AVD_NAME"; then
    return 0
  fi
  local image_dir="$SDK/${AVD_IMAGE//;//}"
  if [ ! -d "$image_dir" ]; then
    say "installing the system image $AVD_IMAGE"
    local started=$SECONDS
    run_child install_image
    [ -d "$image_dir" ] || { tail -20 "$OUT_DIR/sdkmanager.log" >&2; die "sdkmanager could not install $AVD_IMAGE (log: $OUT_DIR/sdkmanager.log)"; }
    say "installed $AVD_IMAGE in $((SECONDS - started))s ($(du -sh "$image_dir" | cut -f1) on disk)"
  fi
  say "creating the AVD $AVD_NAME from $AVD_IMAGE"
  echo no | "$AVDMANAGER" create avd -n "$AVD_NAME" -k "$AVD_IMAGE" -d pixel_6 --force >"$OUT_DIR/avdmanager.log" 2>&1 \
    || { cat "$OUT_DIR/avdmanager.log" >&2; die "avdmanager could not create $AVD_NAME"; }
  local config="$HOME/.android/avd/$AVD_NAME.avd/config.ini"
  [ -f "$config" ] || die "avdmanager created no $config"
  # Replace avdmanager's values rather than append duplicates (pixel_6 brings a 6 GB data
  # partition, for one).
  local settings="hw.keyboard=yes disk.dataPartition.size=2G hw.lcd.density=420 hw.gpu.enabled=yes hw.gpu.mode=swiftshader_indirect"
  local setting
  for setting in $settings; do
    grep -v "^${setting%%=*}[[:space:]]*=" "$config" >"$config.tmp" && mv "$config.tmp" "$config"
  done
  for setting in $settings; do echo "$setting" >>"$config"; done
}

port_free() {
  local port="$1"
  ! "$ADB" devices | grep -q "^emulator-$port[[:space:]]" \
    && ! lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 \
    && ! lsof -nP -iTCP:"$((port + 1))" -sTCP:LISTEN >/dev/null 2>&1
}

emulator_alive() {
  if [ -n "$1" ]; then kill -0 "$1" 2>/dev/null; else pgrep -f -- "-avd $AVD_NAME( |$)" >/dev/null; fi
}

# Waits until SERIAL is booted and its package manager answers, then turns animations off.
# $1 is the emulator's pid when this run started it, else empty; $2 the start time.
wait_for_boot() {
  local emulator_pid="$1" started="$2" setting
  # adb wait-for-device has no timeout, so poll the state instead, watching the process.
  until [ "$("$ADB" -s "$SERIAL" get-state 2>/dev/null)" = "device" ]; do
    emulator_alive "$emulator_pid" || { tail -20 "$OUT_DIR/emulator.log" >&2; die "the emulator exited during boot"; }
    [ $((SECONDS - started)) -ge "$BOOT_TIMEOUT" ] && die "$SERIAL did not come up within ${BOOT_TIMEOUT}s"
    sleep 2
  done
  assert_ours "$SERIAL"
  until [ "$("$ADB" -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] \
    && "$ADB" -s "$SERIAL" shell pm path android 2>/dev/null | grep -q '^package:'; do
    emulator_alive "$emulator_pid" || { tail -20 "$OUT_DIR/emulator.log" >&2; die "the emulator exited during boot"; }
    [ $((SECONDS - started)) -ge "$BOOT_TIMEOUT" ] && die "$SERIAL did not finish booting within ${BOOT_TIMEOUT}s"
    sleep 2
  done
  for setting in window_animation_scale transition_animation_scale animator_duration_scale; do
    "$ADB" -s "$SERIAL" shell settings put global "$setting" 0
  done
}

# Boots ft-lane unless it is already running, waits until it is booted (a running one too: an
# interrupted run can leave it offline or still booting), then sets SERIAL.
boot() {
  mkdir -p "$OUT_DIR"
  "$ADB" start-server >/dev/null 2>&1
  local emulator_pid="" started=$SECONDS
  if SERIAL="$(our_serial)"; then
    say "reusing the running $AVD_NAME emulator on $SERIAL"
  elif emulator_alive ""; then
    say "waiting for adb to see the $AVD_NAME emulator that is starting"
    until SERIAL="$(our_serial)"; do
      emulator_alive "" || die "the $AVD_NAME emulator exited during boot"
      [ $((SECONDS - started)) -ge "$BOOT_TIMEOUT" ] && die "adb did not see $AVD_NAME within ${BOOT_TIMEOUT}s; run tools/emulator_tests.sh stop"
      sleep 2
    done
    say "found $AVD_NAME on $SERIAL"
  else
    ensure_avd
    local port="" p
    for p in $(seq 5554 2 5584); do
      if port_free "$p"; then port="$p"; break; fi
    done
    [ -n "$port" ] || die "no free emulator port in 5554-5584"
    SERIAL="emulator-$port"
    say "booting $AVD_NAME on $SERIAL (log: $OUT_DIR/emulator.log)"
    nohup "$EMULATOR" -avd "$AVD_NAME" -no-window -no-audio -no-boot-anim -no-snapshot \
      -gpu swiftshader_indirect -port "$port" >"$OUT_DIR/emulator.log" 2>&1 &
    emulator_pid=$!
    started=$SECONDS
  fi
  wait_for_boot "$emulator_pid" "$started"
  say "$SERIAL is ready ($((SECONDS - started))s)"
}

# Commands -------------------------------------------------------------------------------

flutter_in_app() {
  cd app && $FLUTTER "$@"
}

cmd_integration() {
  [ "${1:-}" = "--" ] && shift
  boot
  say "running the integration tests on $SERIAL"
  run_child flutter_in_app test integration_test --flavor demo -d "$SERIAL" "$@"
  local status=$?
  if [ $status -eq 0 ]; then say "integration: passed"; else say "integration: FAILED"; fi
  return $status
}

cmd_demo() {
  local shot="${1:-$OUT_DIR/demo.png}"
  boot
  run_child flutter_in_app build apk --debug --flavor demo -t lib/main_demo.dart || die "the demo build failed"
  assert_ours "$SERIAL"
  "$ADB" -s "$SERIAL" install -r app/build/app/outputs/flutter-apk/app-demo-debug.apk || die "the install failed"
  local activity
  activity="$("$ADB" -s "$SERIAL" shell cmd package resolve-activity --brief -c android.intent.category.LAUNCHER "$DEMO_PACKAGE" | tr -d '\r' | tail -1)"
  [[ "$activity" == "$DEMO_PACKAGE"/* ]] || die "no launcher activity for $DEMO_PACKAGE (got '$activity')"
  "$ADB" -s "$SERIAL" shell am start -W -n "$activity" >/dev/null || die "could not launch $activity"
  local started=$SECONDS
  until "$ADB" -s "$SERIAL" shell dumpsys window | grep -E 'mCurrentFocus|mFocusedApp' | grep -q "$DEMO_PACKAGE"; do
    [ $((SECONDS - started)) -ge 60 ] && die "$DEMO_PACKAGE did not take focus within 60s"
    sleep 1
  done
  # Focus comes with the launch screen; give the debug build a moment to draw its first frame.
  sleep 3
  mkdir -p "$(dirname "$shot")"
  "$ADB" -s "$SERIAL" exec-out screencap -p >"$shot" || die "screencap failed"
  [ -s "$shot" ] || die "screencap wrote nothing"
  say "screenshot: $(cd "$(dirname "$shot")" && pwd)/$(basename "$shot")"
}

cmd_run() {
  [ $# -gt 0 ] || die "usage: tools/emulator_tests.sh run <command...>"
  boot
  export FT_EMULATOR_SERIAL="$SERIAL"
  run_child "$@"
}

cmd_stop() {
  if [ -d "$LOCK_DIR" ]; then
    lock_is_stale || die "a run holds the lock ($(lock_holder)); stop it first, or wait for it to finish"
    reclaim_stale
  fi
  local serial
  if serial="$(our_serial)"; then
    say "stopping $AVD_NAME on $serial"
    "$ADB" -s "$serial" emu kill >/dev/null 2>&1
    local started=$SECONDS
    while pgrep -f -- "-avd $AVD_NAME( |$)" >/dev/null && [ $((SECONDS - started)) -lt 30 ]; do sleep 1; done
  fi
  if pgrep -f -- "-avd $AVD_NAME( |$)" >/dev/null; then
    say "killing the remaining $AVD_NAME emulator process"
    pkill -f -- "-avd $AVD_NAME( |$)"
  fi
  say "stopped"
}

cmd_status() {
  if [ -d "$LOCK_DIR" ]; then
    if lock_is_stale; then say "lock: stale, held by $(lock_holder)"; else say "lock: held by $(lock_holder)"; fi
  else
    say "lock: free"
  fi
  local serial
  if serial="$(our_serial)"; then
    say "$AVD_NAME: running on $serial ($("$ADB" -s "$serial" get-state 2>/dev/null || echo offline))"
  elif pgrep -f -- "-avd $AVD_NAME( |$)" >/dev/null; then
    say "$AVD_NAME: starting (the process is up, adb does not see it yet)"
  else
    say "$AVD_NAME: not running"
  fi
}

command="${1:-integration}"
[ $# -gt 0 ] && shift
require_tools
case "$command" in
  integration | demo | run)
    acquire_lock "$command" "$@"
    "cmd_$command" "$@"
    ;;
  stop | status) "cmd_$command" ;;
  -h | --help | help) sed -n '2,/^set -uo/p' "$0" | sed '$d; s/^# \{0,1\}//' ;;
  *) die "unknown command '$command'; one of integration, demo, run, stop, status" ;;
esac
