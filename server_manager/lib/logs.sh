#!/usr/bin/env bash

# Log streaming helpers.

LOG_STREAM_PID_FILE="$RUN_DIR/enshrouded-logstream.pid"
LOG_STREAM_TAIL_PID_FILE="$RUN_DIR/enshrouded-logtail.pid"

get_log_dir() {
  if [[ -n "${ENSHROUDED_LOG_DIR:-}" ]]; then
    abs_path "$ENSHROUDED_LOG_DIR"
    return
  fi
  if command -v jq >/dev/null 2>&1 && [[ -f "$CONFIG_FILE" ]]; then
    local ld
    ld="$(jq -r '.logDirectory // "./logs"' "$CONFIG_FILE" 2>/dev/null || echo "./logs")"
    abs_path "$ld"
    return
  fi
  abs_path "./logs"
}

latest_log_file() {
  local log_dir
  log_dir="$(get_log_dir)"
  if [[ ! -d "$log_dir" ]]; then
    echo ""
    return
  fi
  find "$log_dir" -maxdepth 1 -type f -name "$LOG_FILE_PATTERN" -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr | head -n1 | cut -d' ' -f2-
}

log_streamer_loop() {
  local current_file tail_pid latest
  current_file=""
  tail_pid=""

  while true; do
    latest="$(latest_log_file)"
    if [[ -n "$latest" && "$latest" != "$current_file" ]]; then
      if pid_alive "$tail_pid"; then
        kill "$tail_pid" 2>/dev/null || true
      fi
      info "Streaming logs: $latest"
      tail -n "$LOG_TAIL_LINES" -F "$latest" &
      tail_pid=$!
      echo "$tail_pid" >"$LOG_STREAM_TAIL_PID_FILE"
      current_file="$latest"
    fi
    sleep "$LOG_POLL_INTERVAL"
  done
}

start_log_streamer() {
  if ! is_true "$LOG_TO_STDOUT"; then
    return 0
  fi
  if [[ -f "$LOG_STREAM_PID_FILE" ]]; then
    local pid
    pid="$(cat "$LOG_STREAM_PID_FILE" 2>/dev/null || true)"
    if pid_alive "$pid"; then
      return 0
    fi
  fi

  log_context_push "logs"
  log_streamer_loop &
  local pid=$!
  log_context_pop
  echo "$pid" >"$LOG_STREAM_PID_FILE"
}

stop_log_streamer() {
  if [[ -f "$LOG_STREAM_PID_FILE" ]]; then
    local pid
    pid="$(cat "$LOG_STREAM_PID_FILE" 2>/dev/null || true)"
    if pid_alive "$pid"; then
      kill "$pid" 2>/dev/null || true
    fi
  fi
  if [[ -f "$LOG_STREAM_TAIL_PID_FILE" ]]; then
    local tpid
    tpid="$(cat "$LOG_STREAM_TAIL_PID_FILE" 2>/dev/null || true)"
    if pid_alive "$tpid"; then
      kill "$tpid" 2>/dev/null || true
    fi
  fi
  rm -f "$LOG_STREAM_PID_FILE" "$LOG_STREAM_TAIL_PID_FILE" 2>/dev/null || true
}
