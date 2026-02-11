#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
SPEC_FILE = REPO_ROOT / "server_manager" / "shared" / "validation" / "vars.json"
OUT_FILE = REPO_ROOT / "docs" / "vars.md"


def _bool(v: Any, default: bool = False) -> bool:
    if isinstance(v, bool):
        return v
    return default


def _s(v: Any) -> str:
    if v is None:
        return ""
    if isinstance(v, str):
        return v
    return str(v)


def _allowed_hint(rule: dict[str, Any]) -> str:
    # Mirrors `validation_var_allowed_hint` behavior (docs-only).
    allowed = _s(rule.get("allowed")).strip()
    if allowed:
        return allowed

    if isinstance(rule.get("list"), dict) and rule.get("list"):
        lst = rule["list"]
        parts: list[str] = ["CSV list"]
        sep = _s(lst.get("separator") or ",")
        if sep != ",":
            parts.append(f"separator: {sep}")
        if _bool(lst.get("trim"), False):
            parts.append("trim: true")
        if _bool(lst.get("itemNoEmpty"), False):
            parts.append("itemNoEmpty: true")
        item_re = _s(lst.get("itemRegex")).strip()
        if item_re:
            parts.append(f"itemRegex: {item_re}")
        return "Allowed: " + ", ".join(parts)

    enum = rule.get("enum")
    if isinstance(enum, list) and enum:
        return "Allowed: " + " | ".join(str(x) for x in enum)

    t = _s(rule.get("type") or "string")
    if t == "bool":
        return "Allowed: true | false"
    if t in ("int", "number"):
        mn = rule.get("min")
        mx = rule.get("max")
        kind = "integer" if t == "int" else "number"
        if mn is not None and mx is not None:
            return f"Allowed: {kind} {mn}..{mx}"
        if mn is not None:
            return f"Allowed: {kind} >= {mn}"
        if mx is not None:
            return f"Allowed: {kind} <= {mx}"
        return f"Allowed: {kind}"

    regex = _s(rule.get("regex")).strip()
    if regex:
        if regex == r"^[^\r\n]*$":
            return "Allowed: single-line string"
        return f"Allowed format: {regex}"

    return "String"


def _md_escape(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ").strip()


def _row(*cols: str) -> str:
    return "| " + " | ".join(_md_escape(c) if c else "" for c in cols) + " |"


def _var_sort_key(name: str, rule: dict[str, Any]) -> tuple[int, str]:
    order = rule.get("meta", {}).get("menuOrder")
    if isinstance(order, int):
        return (order, name)
    return (999999999, name)


def _write_section(
    out: list[str],
    title: str,
    rows: list[tuple[str, dict[str, Any], str]],
    path_field: str | None,
) -> None:
    out.append(f"## {title}")
    out.append("")
    if not rows:
        out.append("_None._")
        out.append("")
        return

    # Group by menuGroup for consistency with the menu.
    by_group: dict[str, list[tuple[str, dict[str, Any], str]]] = {}
    for name, rule, json_path in rows:
        group = _s(rule.get("meta", {}).get("menuGroup") or "Settings")
        by_group.setdefault(group, []).append((name, rule, json_path))

    for group in sorted(by_group.keys()):
        out.append(f"### {group}")
        out.append("")
        out.append(
            _row(
                "Variable",
                "Type",
                "Required",
                "AllowEmpty",
                "EnvMode",
                (path_field or "JSON Path"),
                "Allowed",
                "Description",
            )
        )
        out.append(_row("---", "---", "---", "---", "---", "---", "---", "---"))

        items = sorted(by_group[group], key=lambda x: _var_sort_key(x[0], x[1]))
        for name, rule, json_path in items:
            out.append(
                _row(
                    name,
                    _s(rule.get("type") or "string"),
                    "true" if _bool(rule.get("required"), False) else "false",
                    "true" if _bool(rule.get("allowEmpty"), True) else "false",
                    _s(rule.get("envMode") or ""),
                    json_path if path_field else "",
                    _allowed_hint(rule),
                    _s(rule.get("description")),
                )
            )
        out.append("")


def main() -> int:
    spec = json.loads(SPEC_FILE.read_text(encoding="utf-8"))
    vars_spec: dict[str, dict[str, Any]] = spec.get("vars", {})
    templates: dict[str, Any] = spec.get("templates", {})

    profile_selectors: list[tuple[str, dict[str, Any]]] = []
    manager_vars: list[tuple[str, dict[str, Any], str]] = []
    enshrouded_top_level: list[tuple[str, dict[str, Any], str]] = []
    game_settings: list[tuple[str, dict[str, Any], str]] = []

    for name, rule in vars_spec.items():
        meta = rule.get("meta") or {}
        m_path = meta.get("managerJsonPath")
        em_path = meta.get("enshroudedMenuJsonPath")
        e_path = meta.get("enshroudedJsonPath")

        if name in ("EN_PROFILE", "MANAGER_PROFILE") and not (m_path or em_path or e_path):
            profile_selectors.append((name, rule))
            continue

        if isinstance(m_path, str) and m_path:
            manager_vars.append((name, rule, m_path))
        if isinstance(em_path, str) and em_path:
            enshrouded_top_level.append((name, rule, em_path))
        if isinstance(e_path, str) and e_path.startswith(".gameSettings."):
            game_settings.append((name, rule, e_path))

    out: list[str] = []
    out.append("# Variable Spec (Generated)")
    out.append("")
    spec_rel = SPEC_FILE.relative_to(REPO_ROOT).as_posix()
    out.append(f"Source of truth: `{spec_rel}`. Do not edit this file by hand.")
    out.append("")
    out.append("Regenerate:")
    out.append("")
    out.append("```bash")
    out.append("python scripts/gen_vars_md.py")
    out.append("```")
    out.append("")

    out.append("## Profile Selectors")
    out.append("")
    out.append(_row("Variable", "Type", "Allowed", "Description"))
    out.append(_row("---", "---", "---", "---"))
    for name, rule in sorted(profile_selectors, key=lambda x: x[0]):
        out.append(
            _row(
                name,
                _s(rule.get("type") or "string"),
                _allowed_hint(rule),
                _s(rule.get("description")),
            )
        )
    out.append("")

    _write_section(out, "Server Manager (server_manager.json)", manager_vars, "JSON Path")
    _write_section(
        out, "Enshrouded Top-Level (enshrouded_server.json)", enshrouded_top_level, "JSON Path"
    )
    _write_section(
        out, "Enshrouded Game Settings (enshrouded_server.json)", game_settings, "JSON Path"
    )

    # Templates: ENSHROUDED_ROLE
    role = templates.get("ENSHROUDED_ROLE") or {}
    fields: dict[str, dict[str, Any]] = (role.get("fields") or {}) if isinstance(role, dict) else {}
    out.append("## Role Template: ENSHROUDED_ROLE")
    out.append("")
    out.append("ENV schema: `ENSHROUDED_ROLE_<index>_<FIELD>`")
    out.append("")
    if not fields:
        out.append("_No fields defined._")
        out.append("")
    else:
        out.append(_row("Field", "JSON Key", "Type", "Required", "AllowEmpty", "EnvMode", "Allowed", "Description"))
        out.append(_row("---", "---", "---", "---", "---", "---", "---", "---"))
        for field_name, rule in sorted(
            fields.items(),
            key=lambda kv: _var_sort_key(kv[0], kv[1]),
        ):
            # Mirrors validation_snake_to_lower_camel for this specific template.
            parts = field_name.lower().split("_")
            json_key = parts[0] + "".join(p[:1].upper() + p[1:] for p in parts[1:])
            out.append(
                _row(
                    field_name,
                    json_key,
                    _s(rule.get("type") or "string"),
                    "true" if _bool(rule.get("required"), False) else "false",
                    "true" if _bool(rule.get("allowEmpty"), True) else "false",
                    _s(rule.get("envMode") or ""),
                    _allowed_hint(rule),
                    _s(rule.get("description")),
                )
            )
        out.append("")

    OUT_FILE.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
