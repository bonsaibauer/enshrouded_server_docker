#!/usr/bin/env bash

EN_PROFILE="${EN_PROFILE:-}"
MANAGER_PROFILE="${MANAGER_PROFILE:-}"

EN_PROFILE_DEFAULT="default"
EN_PROFILE_DIR="${MANAGER_ROOT:-/opt/enshrouded/manager}/profiles_enshrouded"
EN_CONFIG_CREATED="false"

MANAGER_PROFILE_DEFAULT="default"
MANAGER_DATA_DIR="${MANAGER_DATA_DIR:-/server_manager}"
MANAGER_PROFILE_ROOT="${MANAGER_PROFILE_ROOT:-/profile}"
MANAGER_PROFILE_DIR="$MANAGER_PROFILE_ROOT"
MANAGER_PROFILE_TEMPLATE_DIR="${MANAGER_PROFILE_TEMPLATE_DIR:-${MANAGER_ROOT:-/opt/enshrouded/manager}/profiles}"

manager_config_path() {
  printf "%s/server_manager.json" "$MANAGER_DATA_DIR"
}

enshrouded_profile_path() {
  local name
  name="${1:-$EN_PROFILE_DEFAULT}"
  printf "%s/%s/enshrouded_server.json" "$EN_PROFILE_DIR" "$name"
}

enshrouded_profile_resolve() {
  local name
  name="${EN_PROFILE:-}"
  if [[ -z "$name" ]]; then
    echo "$EN_PROFILE_DEFAULT"
    return 0
  fi
  if [[ -f "$(enshrouded_profile_path "$name")" ]]; then
    echo "$name"
    return 0
  fi
  warn "Enshrouded profile not found: $name (fallback: $EN_PROFILE_DEFAULT)" >&2
  echo "$EN_PROFILE_DEFAULT"
}

manager_profile_path() {
  local name
  name="${1:-$MANAGER_PROFILE_DEFAULT}"
  printf "%s/%s/server_manager.json" "$MANAGER_PROFILE_DIR" "$name"
}

manager_profile_template_path() {
  local name
  name="${1:-$MANAGER_PROFILE_DEFAULT}"
  printf "%s/%s.json" "$MANAGER_PROFILE_TEMPLATE_DIR" "$name"
}

manager_profile_resolve() {
  local name
  name="${MANAGER_PROFILE:-}"
  if [[ -z "$name" ]]; then
    echo "$MANAGER_PROFILE_DEFAULT"
    return 0
  fi
  if [[ -f "$(manager_profile_path "$name")" || -f "$(manager_profile_template_path "$name")" ]]; then
    echo "$name"
    return 0
  fi
  warn "Profile not found: $name (fallback: $MANAGER_PROFILE_DEFAULT)" >&2
  echo "$MANAGER_PROFILE_DEFAULT"
}

ensure_manager_paths() {
  local data_link profile_link data_target profile_target data_real target_real profile_real profile_target_real
  data_link="$MANAGER_DATA_DIR"
  profile_link="$MANAGER_PROFILE_ROOT"
  data_target="${INSTALL_PATH}/server_manager"
  profile_target="${INSTALL_PATH}/profile"

  mkdir -p "$data_target" "$profile_target" 2>/dev/null || true

  ensure_volume_link() {
    local link target label real target_real
    link="$1"
    target="$2"
    label="$3"

    migrate_dir_contents() {
      local from to now dest
      from="$1"
      to="$2"
      now="$(date -u +%Y%m%dT%H%M%SZ 2>/dev/null || echo "unknown")"
      dest="$to"
      mkdir -p "$to" 2>/dev/null || true

      shopt -s dotglob nullglob
      local -a items=("$from"/*)
      shopt -u dotglob nullglob
      if [[ "${#items[@]}" -eq 0 ]]; then
        return 0
      fi

      shopt -s dotglob nullglob
      local -a target_items=("$to"/*)
      shopt -u dotglob nullglob
      if [[ "${#target_items[@]}" -ne 0 ]]; then
        dest="$to/migrated-${label}-${now}"
        mkdir -p "$dest" 2>/dev/null || true
      fi

      if ! mv "${items[@]}" "$dest/" 2>/dev/null; then
        warn "Failed to migrate $label data from $from to $dest"
        return 1
      fi
      rmdir "$from" 2>/dev/null || true
      info "Migrated $label data from $from to $dest"
    }

    if [[ -L "$link" ]]; then
      real="$(readlink -f "$link" 2>/dev/null || true)"
      target_real="$(readlink -f "$target" 2>/dev/null || true)"
      if [[ -n "$real" && -n "$target_real" && "$real" == "$target_real" ]]; then
        return 0
      fi
      if [[ -n "$real" && -d "$real" && "$real" != "$target_real" ]]; then
        migrate_dir_contents "$real" "$target" || true
      fi
      rm -f "$link" 2>/dev/null || true
    fi

    if [[ -e "$link" && ! -L "$link" ]]; then
      if command -v mountpoint >/dev/null 2>&1 && mountpoint -q "$link"; then
        warn "$label dir is a mountpoint; leaving as-is: $link"
        return 0
      fi
      if [[ -d "$link" ]]; then
        migrate_dir_contents "$link" "$target" || true
        rm -rf "$link" 2>/dev/null || true
      else
        rm -f "$link" 2>/dev/null || true
      fi
    fi

    if [[ ! -e "$link" ]]; then
      ln -s "$target" "$link" 2>/dev/null || true
    fi
    if [[ ! -e "$link" ]]; then
      mkdir -p "$link" 2>/dev/null || true
    fi
  }

  ensure_volume_link "$data_link" "$data_target" "server_manager"
  ensure_volume_link "$profile_link" "$profile_target" "profile"

  data_real="$(readlink -f "$data_link" 2>/dev/null || true)"
  target_real="$(readlink -f "$data_target" 2>/dev/null || true)"
  if [[ -n "$data_real" && -n "$target_real" && "$data_real" != "$target_real" ]]; then
    warn "Manager data dir is not in mounted volume: $data_link -> $data_real (expected $target_real)"
  fi

  profile_real="$(readlink -f "$profile_link" 2>/dev/null || true)"
  profile_target_real="$(readlink -f "$profile_target" 2>/dev/null || true)"
  if [[ -n "$profile_real" && -n "$profile_target_real" && "$profile_real" != "$profile_target_real" ]]; then
    warn "Manager profile dir is not in mounted volume: $profile_link -> $profile_real (expected $profile_target_real)"
  fi

  mkdir -p "$data_link/run" 2>/dev/null || true
}

ensure_manager_profile_file() {
  local profile profile_file template_file
  profile="$1"
  profile_file="$(manager_profile_path "$profile")"
  template_file="$(manager_profile_template_path "$profile")"

  if [[ -f "$profile_file" ]]; then
    return 0
  fi
  if [[ ! -f "$template_file" ]]; then
    fatal "Server Manager profile template not found: $template_file"
  fi
  mkdir -p "$(dirname "$profile_file")" 2>/dev/null || true
  if ! jq -e '.' "$template_file" >/dev/null 2>&1; then
    fatal "Invalid JSON in server manager profile template: $template_file"
  fi
  cp "$template_file" "$profile_file"
  ok "Server Manager profile created: $profile_file"
}

manager_config_is_stub() {
  local file
  file="$1"
  if [[ ! -f "$file" ]]; then
    return 0
  fi
  if ! jq -e 'type == "object"' "$file" >/dev/null 2>&1; then
    return 1
  fi
  jq -e 'keys | all(. == "profile" or . == "profileApplied")' "$file" >/dev/null 2>&1
}

copy_manager_profile_to_config() {
  local profile_file config_file
  profile_file="$1"
  config_file="$2"
  if [[ ! -f "$profile_file" ]]; then
    fatal "Server Manager profile not found: $profile_file"
  fi
  if ! jq -e '.' "$profile_file" >/dev/null 2>&1; then
    fatal "Invalid JSON in server manager profile: $profile_file"
  fi
  mkdir -p "$(dirname "$config_file")" 2>/dev/null || true
  cp "$profile_file" "$config_file"
  ok "Server Manager config created from profile: $profile_file"
}

manager_profile_key_exists() {
  local file path key
  file="$1"
  path="$2"
  key="${path#.}"
  if [[ -z "$key" ]] || [[ ! -f "$file" ]]; then
    return 1
  fi
  jq -e --arg key "$key" 'has($key)' "$file" >/dev/null 2>&1
}

manager_profile_raw_value() {
  local file path
  file="$1"
  path="$2"
  jq -r "$path" "$file" 2>/dev/null || echo "null"
}

manager_profile_value_for_var() {
  local profile var path profile_file default_file raw
  profile="$1"
  var="$2"
  path="${MANAGER_JSON_PATH[$var]-}"
  if [[ -z "$path" ]]; then
    echo ""
    return 0
  fi
  profile_file="$(manager_profile_path "$profile")"
  if manager_profile_key_exists "$profile_file" "$path"; then
    raw="$(manager_profile_raw_value "$profile_file" "$path")"
    echo "$raw"
    return 0
  fi
  default_file="$(manager_profile_path "$MANAGER_PROFILE_DEFAULT")"
  if [[ "$profile" != "$MANAGER_PROFILE_DEFAULT" ]] && manager_profile_key_exists "$default_file" "$path"; then
    raw="$(manager_profile_raw_value "$default_file" "$path")"
    echo "$raw"
    return 0
  fi
  echo ""
}

apply_manager_profile_defaults() {
  local file profile var raw value normalized path
  file="$1"
  profile="$2"

  for var in "${MANAGER_VARS[@]}"; do
    value=""
    raw="$(manager_profile_value_for_var "$profile" "$var")"
    if [[ -z "$raw" ]]; then
      continue
    fi

    path="${MANAGER_JSON_PATH[$var]-}"
    if [[ -z "$path" ]]; then
      continue
    fi

    if [[ "$raw" == "null" ]]; then
      manager_config_set "$file" "$path = null"
      printf -v "$var" '%s' ""
      continue
    fi

    if ! validate_manager_value "$var" "$raw" "soft"; then
      if [[ "$profile" != "$MANAGER_PROFILE_DEFAULT" ]]; then
        raw="$(manager_profile_value_for_var "$MANAGER_PROFILE_DEFAULT" "$var")"
        if [[ -n "$raw" && "$raw" != "null" ]] && validate_manager_value "$var" "$raw" "soft"; then
          value="$raw"
        else
          warn "Profile $profile: $var invalid, skipping"
          continue
        fi
      else
        warn "Profile $profile: $var invalid, skipping"
        continue
      fi
    fi

    value="${value:-$raw}"
    if [[ "$var" == "LOG_LEVEL" ]]; then
      normalized="$(normalize_log_level "$raw")"
      value="$normalized"
      LOG_LEVEL="$normalized"
    fi

    manager_config_set_value "$file" "$var" "$value"
    printf -v "$var" '%s' "$value"
  done
}

create_default_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    return 0
  fi

  require_cmd jq
  local profile profile_file temp_file
  profile="$(enshrouded_profile_resolve)"
  profile_file="$(enshrouded_profile_path "$profile")"

  if [[ ! -f "$profile_file" ]]; then
    fatal "Enshrouded profile not found: $profile_file"
  fi
  if ! jq -e '.' "$profile_file" >/dev/null 2>&1; then
    fatal "Invalid JSON in enshrouded profile: $profile_file"
  fi

  info "Creating initial enshrouded_server.json (profile: $profile)"
  temp_file="$(mktemp)"
  if jq 'if has("bans") then . else . + {bans: []} end' "$profile_file" >"$temp_file"; then
    mv "$temp_file" "$CONFIG_FILE"
  else
    rm -f "$temp_file"
    fatal "Failed to create $CONFIG_FILE (jq error)"
  fi

  chmod 600 "$CONFIG_FILE" 2>/dev/null || true
  ok "enshrouded_server.json created"
  EN_CONFIG_CREATED="true"
}
