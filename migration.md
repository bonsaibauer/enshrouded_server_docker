# Migration Plan - Reorganisation Server Manager

## Ziel

Die Reorganisation hat zwei harte Ziele:

1. Code-Reduktion (Duplikate raus, kleinere Skripte, weniger Mischlogik).
2. Klare Verantwortlichkeit pro Skript (Job-Wrapper vs. Fach-Command).
3. Keine Abwaertskompatibilitaet: verwaiste/alte Pfade, Wrapper und Legacy-Code werden entfernt.

## Leitprinzipien

1. `jobs/*` enthalten nur Orchestrierung.
2. `commands/*` enthalten nur Fachlogik.
3. `logs/log` ist der zentrale Log-Sink.
4. Kein generisches `run`-Command.
5. Kein `common.sh` als zentrale Sammel-Library.
6. Jeder Command muss eigenstaendig direkt aufrufbar sein.
7. Checks werden vom Job bei Bedarf vor/nach Aktionen aufgerufen (wenn deaktiviert: Command nicht aufrufen).
8. Keine Ablaufsteuerung ueber CLI-Args; Steuerung erfolgt ueber eindeutige Script-Aufrufe + Config.
9. Keine Legacy-Aliase fuer alte Befehlsnamen; nur neue Struktur gilt.
10. JSON-only Datenmodell: keine CSV-Regeln in der Runtime.
11. `jq` ist das einzige Werkzeug fuer JSON lesen, validieren und schreiben.
12. Gleichheit ist erlaubt: Runtime-Wert kann identisch zu Profile-Default oder ENV-Default sein.
13. UI ist zentral in `server_manager/ui/*`; `jobs/menu` orchestriert nur.
14. `jobs/bootstrap` orchestriert nur und ruft bestehende Commands auf; keine doppelte `bootstrap-*` Fachlogik.

## Zielstruktur

```text
server_manager/
  jobs/
    server
    bootstrap
    cron
    rsyslogd
    restart
    update
    backup
    profile
    env
    menu                          # Menu-Orchestrierung

  commands/
    check/
      check-player
      check-update
      check-password
      check-cron
      check-env
      check-all-env
      check-backup-list
      check-backup-inspect

    force/
      force-restart
      force-update

    scheduled/
      scheduled-restart
      scheduled-update
      scheduled-backup
      scheduled-backup-all
      scheduled-backup-config

    manual/
      restart
      update
      backup
      backup-all
      backup-config
      env-init-runtime
      apply-profile-manager
      apply-profile-enshrouded

    restore/
      reset-profile-manager
      reset-profile-enshrouded
      restore-backup-all
      restore-backup-config
      restore-backup-savegame
      restore-backup-enshrouded
      restore-backup-manager

  logs/
    log

  ui/
    startup_banner
    menu_ui

  profiles/
    enshrouded/
      default_enshrouded_server.json
    manager/
      default_server_manager.json
    env/
      env.json
    menu/
      menu.json
```

## Verantwortlichkeit je Gruppe

### Jobs (Supervisor/Wrapper)

| Datei | Rolle | Darf enthalten | Darf nicht enthalten |
|---|---|---|---|
| `jobs/server` | Prozesssteuerung Server | supervisor/start/stop/status, guard | Backup-/Update-/Profile-Fachlogik |
| `jobs/bootstrap` | Initiale Reihenfolge | bestehende Commands in fester Reihenfolge aufrufen | Eigene doppelte `bootstrap-*` Fachlogik |
| `jobs/cron` | Cron-Orchestrierung | start/stop/restart im Job, Check via `check-cron` | Eigene Cron-Businesslogik doppeln |
| `jobs/rsyslogd` | Logging-Prozess | rsyslogd start/health | Fachlogik |
| `jobs/restart` | Restart-Flow Dispatch | config lesen + `check/force/manual/scheduled` aufrufen | Restart-Implementierung im Job |
| `jobs/update` | Update-Flow Dispatch | config lesen + `check/force/manual/scheduled` aufrufen | Update-Implementierung im Job |
| `jobs/backup` | Backup/Restore Dispatch | config lesen + eindeutigen Command-Pfad aufrufen | Zip/restore Details im Job |
| `jobs/profile` | Profil-Dispatch | apply/reset/check-password Commands aufrufen (text view only) | Profil-Merge-Details im Job |
| `jobs/env` | ENV-Dispatch | `check-env`, `check-all-env`, `env-init-runtime` | Vollstaendige Validator-Engine im Job |
| `jobs/menu` | Menu-Orchestrierung | `profiles/menu/menu.json` lesen, `ui/*` nutzen, Commands aufrufen | Fachlogik von backup/update/profile im Job |

### Commands (Fachlogik)

| Gruppe | Zweck |
|---|---|
| `commands/check/*` | Reine Pruefkommandos, keine dauerhafte Zustandsaenderung |
| `commands/force/*` | Erzwungene Aktionen, Schutzlogik bewusst reduziert |
| `commands/scheduled/*` | Scheduler-spezifische Defaults/Verhalten |
| `commands/manual/*` | Benutzergetriggerte manuelle Aktionen |
| `commands/restore/*` | Vorzustand/Backup wiederherstellen |

### Logs

| Pfad | Zweck |
|---|---|
| `logs/log` | Zentraler Log-Ausgabepunkt fuer Jobs und Commands |

### UI

| Pfad | Zweck |
|---|---|
| `ui/startup_banner` | Zentrale Banner-/Startausgabe (auch fuer server/menu wiederverwendbar) |
| `ui/menu_ui` | Einheitliche Menu-UI-Funktionen (`ui_warn`, `ui_info`, `ui_error`, Input/Prompt), mit zentralem Logging auf `logs/log` |

### Profiles / ENV-Spec

| Pfad | Zweck |
|---|---|
| `profiles/enshrouded/default_enshrouded_server.json` | Default-Profil fuer Enshrouded-Konfiguration |
| `profiles/manager/default_server_manager.json` | Default-Profil fuer Server-Manager-Konfiguration |
| `profiles/env/env.json` | Zentrale ENV-Spezifikation: alle verwalteten Variablen inkl. Typ, Regeln und JSON-Zielpfad; Grundlage fuer `check-env`, `check-all-env` und `env-init-runtime` |
| `profiles/menu/menu.json` | Zentrale Menu-Definition (Screens, Actions, Command-Mapping, Confirm-Texte) |

## JSON-only Modell (jq-only)

| Datei | Rolle |
|---|---|
| `profiles/env/env.json` | ENV-Spec (Typen, Regeln, Defaults, Zielpfade) |
| `profiles/manager/default_server_manager.json` | Manager-Profil-Default |
| `profiles/enshrouded/default_enshrouded_server.json` | Enshrouded-Profil-Default |
| `server_manager.json` | Runtime-Zielzustand (persistiert) |
| `enshrouded_server.json` | Runtime-Zielzustand (persistiert) |

Regel:

1. `env-init-runtime` arbeitet nur mit JSON-Dateien.
2. Validierung laeuft nur gegen `profiles/env/env.json`.
3. Lesen/Schreiben/Transformation erfolgt nur mit `jq`.
4. Wenn Werte identisch sind (ENV-Default = Profile-Default = Runtime), wird nichts speziell behandelt; das ist ein gueltiger Normalfall.

## Job -> Command Aufrufmodell

Standardablauf in Jobs:

1. Config lesen (`server_manager.json`, `enshrouded_server.json`).
2. Eindeutigen Command festlegen (Datei-Pfad, kein Args-Multiplexing).
3. Check-Commands aufrufen (nur wenn aktiv).
4. Genau einen Aktions-Command direkt aufrufen (`manual`, `scheduled`, `force`, `restore`).
5. Exit-Code unverfaelscht nach oben geben.

Bootstrap-Sonderregel:

1. `jobs/bootstrap` ruft nur bereits vorhandene Commands auf (z. B. `check-all-env`, `env-init-runtime`, `update`, `apply-profile-*`).
2. Keine zweite Implementierung derselben Logik unter eigenen `bootstrap-*` Skripten.
3. Nur wenn eine Faehigkeit noch nirgends existiert, wird ein neuer dedizierter Command erstellt.

Beispiel `jobs/restart`:

1. Wenn `restartCheckPlayers=true`: `commands/check/check-player`.
2. Wenn Force-Modus: `commands/force/force-restart`.
3. Wenn Scheduled-Modus: `commands/scheduled/scheduled-restart`.
4. Sonst: `commands/manual/restart`.

## Mapping Alt -> Neu

| Legacy (Ist-Code) | Neu aufgeteilt nach Commands |
|---|---|
| `jobs/restart` | `check-player`, `restart`, `force-restart`, `scheduled-restart` |
| `jobs/updater` | `check-update`, `update`, `force-update`, `scheduled-update` |
| `jobs/backup` | `backup-all`, `backup`, `backup-config`, `scheduled-backup-all`, `scheduled-backup`, `scheduled-backup-config`, `check-backup-*`, `restore-backup-all`, `restore-backup-*` |
| `jobs/profile` | `apply-profile-manager`, `apply-profile-enshrouded`, `reset-profile-*`, `check-password*` |
| `jobs/env-validation` | `check-env`, `check-all-env`, `env-init-runtime` |
| `jobs/cron` | `check-cron` + start/stop/restart im Job + Trigger auf `scheduled-*` |
| `jobs/menu` | liest `profiles/menu/menu.json`, nutzt `ui/*` und ruft Commands auf |

## Migrationsphasen mit Prompt-Vorlagen

| Phase | Ziel | Prompt-Vorlage (direkt nutzbar) | Abnahme |
|---|---|---|---|
| 1 | Zielstruktur aufbauen | `Lege die Zielstruktur aus migration.md unter server_manager an (jobs/commands/check|force|scheduled|manual|restore/logs/ui/profiles inkl. profiles/menu/menu.json). Erstelle fehlende Dateien als Platzhalter, ohne Fachlogik zu aendern.` | Alle Zielpfade existieren. |
| 2 | ENV-Spec zentralisieren | `Migriere die ENV-Regeln nach server_manager/profiles/env/env.json. Entferne CSV-Regelpfade aus der Runtime und ersetze sie durch env.json-basierte Validierung.` | `profiles/env/env.json` ist einzige Regelquelle. |
| 3 | Check-Commands extrahieren | `Extrahiere reine Pruefungen in commands/check/* (check-player, check-update, check-password, check-cron, check-env, check-all-env, check-backup-list, check-backup-inspect). Keine Seiteneffekte in diesen Skripten.` | Checks laufen isoliert und schreiben keinen Zustand. |
| 4 | Aktions-Commands extrahieren | `Extrahiere die Aktionslogik in commands/manual/*, commands/force/*, commands/scheduled/* und commands/restore/*. Jeder Command ist direkt aufrufbar und hat genau eine Verantwortung.` | Actions laufen ohne alte Job-Internlogik. |
| 5 | Jobs auf Wrapper reduzieren | `Reduziere jobs/* auf Orchestrierung: JSON lesen, Check optional ausfuehren, genau einen Command-Pfad starten, Exit-Code durchreichen. Entferne Args-Multiplexing. Fuer bootstrap: nur bestehende Commands aufrufen, keine doppelte bootstrap-Fachlogik.` | Jobs enthalten keine Fachlogik mehr. |
| 6 | Supervisor/Docker an neue Pfade binden | `Passe Supervisor-Programme und Docker-Symlinks/Entry-Aufrufe auf die neue Struktur an. Keine Legacy-Aliase behalten.` | Runtime nutzt nur neue Namen/Pfade. |
| 7 | Menu + UI modularisieren | `Stelle jobs/menu auf Menu-Orchestrierung um: Menuestruktur aus profiles/menu/menu.json lesen, UI aus ui/menu_ui und ui/startup_banner nutzen, Actions direkt auf neue Commands mappen. Entferne doppelte Fachlogik aus dem Menu-Code.` | Menu ist nur Orchestrierung + UI-Dispatch. |
| 8 | Legacy entfernen (Breaking Change) | `Entferne alte Skripte, alte Namen, alte CSV-Parser und alle Abwaertskompatibilitaets-Wrapper vollstaendig.` | Kein verwaister Legacy-Code mehr vorhanden. |
| 9 | Abschluss-Validierung | `Fuehre Smoke-Tests fuer alle Jobs/Commands aus und dokumentiere Ergebnis + offene Punkte in migration.md.` | Alle Kernpfade getestet, Ergebnis dokumentiert. |
| 10 | Sprach- und Naming-Standardisierung | `Pruefe alle Code-Dateien auf englische Code-Sprache (Funktionsnamen, Variablennamen, Kommentare, Log-Meldungen im Code) und vereinheitliche die Funktionsnamen nach einem koharenten Schema. Verwende durchgaengig snake_case; fuer wiederkehrende Aufgaben funktionsuebergreifend gleiche Verb-Praefixe wie check_, apply_, reset_, restore_, start_, stop_; und pro Datei entweder Dateiname-gebundenes Prefix oder klares Domain-Prefix (z. B. backup_*, profile_*, env_*).` | Code ist sprachlich einheitlich (Englisch) und Funktionsnamen sind ueber Dateien hinweg konsistent nachvollziehbar. |

## Definition of Done

1. Jeder Eintrag unter `commands/*` ist direkt aufrufbar.
2. `jobs/*` enthalten keine Fachlogik mehr, nur Dispatch.
3. Keine Ablaufsteuerung ueber CLI-Args.
4. Kein `common.sh`-Monolith.
5. Menue ruft Commands statt Altlogik.
6. `logs/log` wird von Jobs/Commands konsistent benutzt.
7. Keine Abwaertskompatibilitaets-Schicht fuer alte Befehle/Pfade vorhanden.
8. `jobs/bootstrap` enthaelt keine doppelte Fachlogik; nur Orchestrierung vorhandener Commands.
9. Code ist in Englisch verfasst und Funktionsnamen folgen einem einheitlichen, datei- oder domainbasierten Namensschema.

## Risikoabsicherung

| Risiko | Absicherung |
|---|---|
| Verhaltensabweichung bei Update/Restart | Vorher/Nachher Smoke-Tests pro Command |
| Backup/Restore Regression | Testmatrix fuer savegame/config/all restore |
| Supervisor-Startprobleme | Stepwise rollout: erst neue Commands, dann Job-Umbau |
| Menue-Brueche | Menu-Funktionen nur umverdrahten, nicht gleichzeitig neu designen |

## Kurzfazit

Dieses Zielbild trennt strikt:

- `jobs` = Entscheidung und Reihenfolge
- `commands` = echte Ausfuehrung
- `logs` = zentrale Ausgabe

Dadurch sinken Duplikate, Skripte werden kuerzer, und jede Datei hat eine klar definierte Verantwortung.

## Phase 9 Abschluss-Validierung (2026-02-25)

### Durchgefuehrte Smoke-Tests

1. Syntax-Pruefung (`bash -n`) fuer alle aktiven Skripte:
   - `server_manager/jobs/*` (10 Dateien)
   - `server_manager/commands/**/*` (30 Dateien)
   - `server_manager/jobs_core/*` (6 Dateien)
2. Direktaufruf-Pruefung (`--help`) fuer alle oben genannten Skripte.
3. Legacy-Entfernungspruefung auf nicht mehr erlaubte Pfade:
   - `server_manager/jobs/updater`
   - `server_manager/jobs/env-validation`
   - `server_manager/env/menu.csv`
   - `server_manager/env/env_server_manager.csv`
   - `server_manager/env/env_enshrouded_server.csv`
   - `server_manager/jobs_legacy`
4. Breaking-Change-Check:
   - `server_manager/jobs/server restart` muss fehlschlagen (Alias entfernt).

### Ergebnis

1. Gepruefte Skripte gesamt: `46`
2. Syntax: `46/46` erfolgreich
3. `--help`-Smoke: `46/46` erfolgreich
4. Legacy-Pfade vorhanden: `0/6`
5. Breaking-Change-Check: `server restart` liefert wie erwartet `FATAL: Unknown server command: restart` (Exit-Code `1`)

### Offene Punkte

1. Container-Runtime-Smokes (Supervisor/Docker-in-Container) konnten lokal nicht ausgefuehrt werden, da die Docker-Engine in der aktuellen Umgebung nicht verfuegbar war.
2. Dokumentationsdateien (`README.md`, `docs/*`) enthalten noch alte Legacy-Begriffe/Befehle und muessen separat auf die neue Struktur aktualisiert werden.

## Phase 10 Sprach- und Naming-Standardisierung (2026-02-25)

### Durchgefuehrte Anpassungen

1. Funktionsnamen in `server_manager/jobs_core/update` auf ein konsistentes Domain-Schema umgestellt:
   - `update_debug`, `update_check_lock`, `update_check_running`, `update_clear_lock`
   - `update_check_for_updates`, `update_download_enshrouded`, `update_run`, `update_run_flow`
2. Funktionsnamen in `server_manager/jobs_core/server` fuer wiederkehrende Hilfsfunktionen vereinheitlicht:
   - `server_debug`, `server_check_running`, `server_check_lock`, `server_clear_lock`, `server_shutdown`
3. Veraltete `shellcheck source`-Kommentare auf die aktuelle Struktur korrigiert:
   - von `server_manager/jobs/profile` auf `server_manager/jobs_core/profile`
4. `--shutdown-timeout` CLI-Flag in `jobs_core/server` nach der Umbenennung explizit auf den stabilen Namen rueckgefuehrt.

### Validierung

1. Funktionsnamen-Audit (alle Skripte in `jobs`, `commands`, `jobs_core`, `ui`, `lib`):
   - Gepruefte Skripte: `49`
   - Nicht konforme Funktionsnamen (nicht `snake_case`): `0`
2. Sprach-Audit auf deutsche Tokens in Code-Kommentaren/Strings:
   - Treffer: `0`
3. Smoke-Tests:
   - `bash -n`: `46/46` erfolgreich
   - `--help`: `46/46` erfolgreich
4. Breaking-Change-Check:
   - `server_manager/jobs/server restart` liefert weiterhin wie erwartet `FATAL: Unknown server command: restart` (Exit-Code `1`).

### Ergebnis

1. Code-Sprache in den geprueften Runtime-Skripten ist konsistent Englisch.
2. Funktionsnamen sind durchgaengig in `snake_case` und fuer die geaenderten Kerndateien domain-praefixiert.
3. Phase 10 ist fuer den Runtime-Code (`server_manager/*`) umgesetzt.
