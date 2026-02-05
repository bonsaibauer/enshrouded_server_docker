#!/usr/bin/env bash

# Backup helpers.

backup_pre_hook() {
  if [[ -n "${BACKUP_PRE_HOOK:-}" ]]; then
    info "Running backup pre hook: $BACKUP_PRE_HOOK"
    eval "$BACKUP_PRE_HOOK"
  fi
}

backup_post_hook() {
  if [[ -n "${BACKUP_POST_HOOK:-}" ]]; then
    info "Running backup post hook: $BACKUP_POST_HOOK"
    eval "$BACKUP_POST_HOOK"
  fi
}

get_save_dir() {
  if [[ -n "${ENSHROUDED_SAVE_DIR:-}" ]]; then
    abs_path "$ENSHROUDED_SAVE_DIR"
    return
  fi
  if command -v jq >/dev/null 2>&1 && [[ -f "$CONFIG_FILE" ]]; then
    local sd
    sd="$(jq -r '.saveDirectory // "./savegame"' "$CONFIG_FILE" 2>/dev/null || echo "./savegame")"
    abs_path "$sd"
    return
  fi
  abs_path "./savegame"
}

get_backup_dir() {
  abs_path "$BACKUP_DIR"
}

backup_cleanup() {
  if [[ -z "$BACKUP_MAX_COUNT" || "$BACKUP_MAX_COUNT" -eq 0 ]]; then
    warn "Skipping cleanup, BACKUP_MAX_COUNT is 0"
    return
  fi
  local backup_dir
  backup_dir="$(get_backup_dir)"
  find "$backup_dir" -type f -printf '%T@ %p\n' | sort -n | cut -d' ' -f 2- | head -n -"$BACKUP_MAX_COUNT" | xargs rm -fv 2>/dev/null || true
}

backup_now() {
  if [[ -f "$PID_BACKUP_FILE" ]]; then
    warn "Backup already in progress"
    return 0
  fi

  echo "$$" >"$PID_BACKUP_FILE"
  require_cmd jq
  require_cmd zip
  require_cmd zipnote

  local save_dir backup_dir latest_save_index latest_savefile_name backup_file_name
  save_dir="$(get_save_dir)"
  backup_dir="$(get_backup_dir)"

  if [[ ! -f "$save_dir/$SAVEFILE_NAME-index" ]]; then
    warn "Save index not found, skipping backup"
    clear_pid "$PID_BACKUP_FILE"
    return 0
  fi

  latest_save_index="$(jq -r '.latest' "$save_dir/$SAVEFILE_NAME-index")"
  if [[ "$latest_save_index" -eq 0 ]]; then
    latest_savefile_name="$SAVEFILE_NAME"
  else
    latest_savefile_name="$SAVEFILE_NAME-$latest_save_index"
  fi

  if [[ ! -f "$save_dir/$latest_savefile_name" ]]; then
    warn "Latest save file missing, skipping backup"
    clear_pid "$PID_BACKUP_FILE"
    return 0
  fi

  backup_pre_hook

  cat >"/tmp/$SAVEFILE_NAME-index" <<EOF
{
  "latest": 0,
  "time": $(jq -r '.time' "$save_dir/$SAVEFILE_NAME-index"),
  "deleted": false
}
EOF

  backup_file_name="$(date +%Y-%m-%d_%H-%M-%S)-$SAVEFILE_NAME.zip"
  info "Backing up to $backup_dir/$backup_file_name"
  set +e
  zip -j "$backup_dir/$backup_file_name" "$save_dir/$latest_savefile_name" "/tmp/$SAVEFILE_NAME-index" >/dev/null
  local zip_rc=$?
  echo -ne "@ $latest_savefile_name\n@=$SAVEFILE_NAME\n" | zipnote -w "$backup_dir/$backup_file_name" >/dev/null
  local note_rc=$?
  set -e
  if [[ "$zip_rc" -ne 0 || "$note_rc" -ne 0 ]]; then
    warn "Backup zip failed"
  fi

  backup_cleanup
  backup_post_hook

  clear_pid "$PID_BACKUP_FILE"
  info "Backup complete"
}
