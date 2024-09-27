#!/bin/bash

selected=$(ls /usr/bin /usr/local/bin | fzf --layout=reverse 2>/dev/null)

if [ -n "$selected" ]; then
  nohup "$selected" >/dev/null 2>&1 &
  sleep 0.1
fi
