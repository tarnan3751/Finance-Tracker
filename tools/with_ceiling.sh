#!/usr/bin/env bash
# Runs a command with a ceiling, as timeout(1) would; macOS has none.
#   tools/with_ceiling.sh <seconds> <command...>
# The command runs in a process group of its own, with standard input from /dev/null (a
# background group reading the terminal would stop), and is executed directly, never through
# a shell. When it is still running after <seconds>, the whole group gets TERM, then KILL
# once the command has exited or 10 s have passed, so no descendant (a flutter_tester, a dart
# test isolate host) is left behind, and the script exits 124. INT, TERM and HUP sent to the
# script stop the group the same way and exit 130, 143 or 129; the handlers are in place
# before the fork, so a signal at any moment stops the group. A command that cannot be run
# exits 127; otherwise the command's own exit status is returned. Used by tools/gates.sh and
# tools/run_tests.sh for each package's tests (FT_TEST_TIMEOUT). Writes nothing.
set -uo pipefail
[ $# -ge 2 ] && [[ "$1" =~ ^[0-9]+$ ]] || { echo "usage: tools/with_ceiling.sh <seconds> <command...>" >&2; exit 2; }
exec perl -MPOSIX=setpgid,WNOHANG,_exit -e '
  my $limit = shift @ARGV;
  my $pid;
  sub stop_group {
    return unless $pid;
    kill "TERM", -$pid, $pid;
    for (1 .. 20) {
      last if waitpid($pid, WNOHANG) > 0;
      select undef, undef, undef, 0.5;
    }
    kill "KILL", -$pid, $pid;
    waitpid $pid, 0;
  }
  my %code = (INT => 130, TERM => 143, HUP => 129, ALRM => 124);
  for my $signal (keys %code) {
    $SIG{$signal} = sub { stop_group(); exit $code{$signal} };
  }
  $pid = fork;
  die "with_ceiling: fork: $!\n" unless defined $pid;
  if ($pid == 0) {
    $SIG{$_} = "DEFAULT" for keys %code;
    setpgid(0, 0);
    open STDIN, "<", "/dev/null";
    exec { $ARGV[0] } @ARGV;
    print STDERR "with_ceiling: cannot run $ARGV[0]: $!\n";
    _exit(127);
  }
  setpgid($pid, $pid);
  alarm $limit;
  waitpid $pid, 0;
  my $status = $?;
  exit($status & 127 ? 128 + ($status & 127) : $status >> 8);
' "$@"
