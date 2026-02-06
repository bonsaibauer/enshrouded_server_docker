#!/usr/bin/env bash

# Update helpers.

LATEST_VERSION="-1"

verify_cpu_mhz() {
  local float_regex cpu_mhz
  float_regex="^([0-9]+\\.?[0-9]*)$"
  cpu_mhz="$(grep "^cpu MHz" /proc/cpuinfo | head -1 | cut -d : -f 2 | xargs)"
  if [[ -n "$cpu_mhz" ]] && [[ "$cpu_mhz" =~ $float_regex ]] && [[ "${cpu_mhz%.*}" -gt 0 ]]; then
    debug "CPU MHz detected: $cpu_mhz"
    unset CPU_MHZ
  else
    debug "Unable to detect CPU MHz, setting CPU_MHZ=1500.000"
    export CPU_MHZ="1500.000"
  fi
}

check_proton_files_available() {
  if [[ ! -d "$STEAM_COMPAT_DATA_PATH" ]]; then
    warn "Update required: proton files missing"
    return 0
  fi
  return 1
}

check_for_updates() {
  local current_version

  if check_proton_files_available; then
    return 0
  fi

  if [[ -f "$VERSION_FILE_PATH" ]]; then
    current_version="$(cat "$VERSION_FILE_PATH" 2>/dev/null || echo 0)"
  else
    current_version="0"
  fi

  require_cmd curl
  require_cmd jq

  LATEST_VERSION="$(curl -sX GET "https://api.steamcmd.net/v1/info/$STEAM_APP_ID" 2>/dev/null | jq -r ".data.\"$STEAM_APP_ID\".depots.branches.$GAME_BRANCH.buildid" 2>/dev/null || echo -1)"

  if [[ "$LATEST_VERSION" == "null" || "$LATEST_VERSION" == "-1" ]]; then
    if [[ "$current_version" == "0" ]]; then
      warn "Update forced: latest version unknown, no version installed"
      return 0
    fi
    warn "Update skipped: latest version unknown"
    return 1
  fi

  if [[ "$current_version" != "$LATEST_VERSION" ]]; then
    info "Update available: $current_version -> $LATEST_VERSION"
    return 0
  fi

  info "Update: already on latest version ($current_version)"
  return 1
}

set_current_version() {
  if [[ "$LATEST_VERSION" == "null" || "$LATEST_VERSION" == "-1" ]]; then
    warn "Update: cannot set current version, latest unknown"
    return 1
  fi
  echo "$LATEST_VERSION" >"$VERSION_FILE_PATH"
}

download_enshrouded() {
  if [[ ! -x "$STEAMCMD_PATH" ]]; then
    fatal "steamcmd not found or not executable at $STEAMCMD_PATH"
  fi

  mkdir -p "$STEAM_COMPAT_DATA_PATH"
  export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH"
  export STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH"
  export STEAM_DIR="$STEAM_COMPAT_CLIENT_INSTALL_PATH"
  export WINETRICKS="${WINETRICKS:-/usr/local/bin/winetricks}"

  info "Update: downloading server via SteamCMD"
  set +e
  "$STEAMCMD_PATH" +@sSteamCmdForcePlatformType windows +force_install_dir "$INSTALL_PATH" +login anonymous +app_update "$STEAM_APP_ID" "$GAME_BRANCH $STEAMCMD_ARGS" +quit
  local rc=$?
  set -e
  return $rc
}

update_pre_hook() {
  if [[ -n "${UPDATE_PRE_HOOK:-}" ]]; then
    info "Update pre hook: $UPDATE_PRE_HOOK"
    eval "$UPDATE_PRE_HOOK"
  fi
}

update_post_hook() {
  if [[ -n "${UPDATE_POST_HOOK:-}" ]]; then
    info "Update post hook: $UPDATE_POST_HOOK"
    eval "$UPDATE_POST_HOOK"
  fi
}

update_now() {
  log_context_push "update"
  if [[ -f "$PID_UPDATE_FILE" ]]; then
    local prev_pid
    prev_pid="$(cat "$PID_UPDATE_FILE" 2>/dev/null || true)"
    if pid_alive "$prev_pid"; then
      warn "Update already in progress (pid: $prev_pid)"
      log_context_pop
      return 0
    fi
    warn "Update: stale pid file found, clearing"
    rm -f "$PID_UPDATE_FILE"
  fi

  echo "$$" >"$PID_UPDATE_FILE"

  local was_running="false"
  if is_server_running; then
    was_running="true"
  fi

  if ! check_for_updates; then
    if [[ "$was_running" == "false" ]] && is_true "$AUTO_RESTART_ON_UPDATE"; then
      info "Start server (update)"
      start_server
    fi
    clear_pid "$PID_UPDATE_FILE"
    log_context_pop
    return 0
  fi

  if ! check_server_empty update; then
    warn "Update skipped: server not empty"
    clear_pid "$PID_UPDATE_FILE"
    log_context_pop
    return 0
  fi

  update_pre_hook
  if [[ "$was_running" == "true" ]]; then
    stop_server
  fi

  verify_cpu_mhz
  if ! download_enshrouded; then
    warn "Update: download failed, retrying after cleanup"
    rm -rf "$INSTALL_PATH/steamapps"
    if ! download_enshrouded; then
      warn "Update aborted: download failed"
      if [[ "$was_running" == "true" ]]; then
        start_server
      fi
      clear_pid "$PID_UPDATE_FILE"
      log_context_pop
      return 1
    fi
  fi

  set_current_version || true

  if is_true "$AUTO_RESTART_ON_UPDATE"; then
    start_server
    start_log_streamer || true
  fi

  update_post_hook
  clear_pid "$PID_UPDATE_FILE"
  log_context_pop
}
