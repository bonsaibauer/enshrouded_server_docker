#!/usr/bin/env bash

# Scheduling helpers (cron + requests).

start_cron_daemon() {
  if ! is_true "$ENABLE_CRON"; then
    return 0
  fi
  if [[ -n "${UPDATE_CRON:-}" || -n "${BACKUP_CRON:-}" || -n "${RESTART_CRON:-}" ]]; then
    if command -v cron >/dev/null 2>&1; then
      if pgrep -x cron >/dev/null 2>&1; then
        return 0
      fi
      info "Starting cron daemon"
      cron
    elif command -v crond >/dev/null 2>&1; then
      if pgrep -x crond >/dev/null 2>&1; then
        return 0
      fi
      info "Starting crond daemon"
      crond
    else
      warn "Cron not available, skipping scheduled jobs"
    fi
  fi
}

init_crontab() {
  if ! is_true "$ENABLE_CRON"; then
    return 0
  fi
  if [[ -z "${UPDATE_CRON:-}" && -z "${BACKUP_CRON:-}" && -z "${RESTART_CRON:-}" ]]; then
    return 0
  fi

  require_cmd crontab

  local cron_file
  cron_file="$(mktemp)"
  {
    echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    if [[ -n "${UPDATE_CRON:-}" ]]; then
      echo "$UPDATE_CRON $MANAGER_BIN update >>/proc/1/fd/1 2>>/proc/1/fd/2"
    fi
    if [[ -n "${BACKUP_CRON:-}" ]]; then
      echo "$BACKUP_CRON $MANAGER_BIN backup >>/proc/1/fd/1 2>>/proc/1/fd/2"
    fi
    if [[ -n "${RESTART_CRON:-}" ]]; then
      echo "$RESTART_CRON $MANAGER_BIN restart >>/proc/1/fd/1 2>>/proc/1/fd/2"
    fi
  } >"$cron_file"

  crontab "$cron_file"
  rm -f "$cron_file"
  info "Crontab updated"
}

handle_requests() {
  if [[ -f "$RUN_DIR/update" ]]; then
    rm -f "$RUN_DIR/update"
    info "Processing update request"
    update_now || true
  fi

  if [[ -f "$RUN_DIR/backup" ]]; then
    rm -f "$RUN_DIR/backup"
    info "Processing backup request"
    backup_now || true
  fi

  if [[ -f "$RUN_DIR/restart" ]]; then
    rm -f "$RUN_DIR/restart"
    info "Processing restart request"
    restart_server || true
  fi
}
