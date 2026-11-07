#!/usr/bin/env bash

# Claude Code の Notification・Stop フック
# Claude Code が動いている端末にベル（BEL）を送り、WezTerm のタブを目立たせる

set -u

# フックの標準出力は端末につながっていないので、端末を直接探して書き込む
if { printf '\a' > /dev/tty; } 2>/dev/null; then
  exit 0
fi

# /dev/tty が使えないときは、親プロセスをたどって端末を探す
pid=$PPID
# Windows の Git Bash の ps は -o を受け付けず pid が空になるので、そこで諦める
while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
  tty=$(ps -o tty= -p "$pid" | tr -d ' ')
  if [ -n "$tty" ] && [ "$tty" != "?" ]; then
    printf '\a' > "/dev/$tty" 2>/dev/null
    exit 0
  fi
  pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
done

exit 0
