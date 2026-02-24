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
    crond
    rsyslogd
    restart
    update
    backup
    profile
    env
    menu                          # run (Menu-Orchestrierung)

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
| `jobs/crond` | Cron-Orchestrierung | start/stop/restart im Job, Check via `check-cron` | Eigene Cron-Businesslogik doppeln |
| `jobs/rsyslogd` | Logging-Prozess | rsyslogd start/health | Fachlogik |
| `jobs/restart` | Restart-Flow Dispatch | config lesen + `check/force/manual/scheduled` aufrufen | Restart-Implementierung im Job |
| `jobs/update` | Update-Flow Dispatch | config lesen + `check/force/manual/scheduled` aufrufen | Update-Implementierung im Job |
| `jobs/backup` | Backup/Restore Dispatch | config lesen + eindeutigen Command-Pfad aufrufen | Zip/restore Details im Job |
| `jobs/profile` | Profil-Dispatch | apply/reset/check-password Commands aufrufen (text view only) | Profil-Merge-Details im Job |
| `jobs/env` | ENV-Dispatch | `check-env`, `check-all-env`, `env-init-runtime` | Vollstaendige Validator-Engine im Job |
| `jobs/menu` | Menu-Orchestrierung (`run`) | `profiles/menu/menu.json` lesen, `ui/*` nutzen, Commands aufrufen | Fachlogik von backup/update/profile im Job |

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

| Aktuell | Neu aufgeteilt nach Commands |
|---|---|
| `jobs/restart` | `check-player`, `restart`, `force-restart`, `scheduled-restart` |
| `jobs/updater` | `check-update`, `update`, `force-update`, `scheduled-update` |
| `jobs/backup` | `backup-all`, `backup`, `backup-config`, `scheduled-backup-all`, `scheduled-backup`, `scheduled-backup-config`, `check-backup-*`, `restore-backup-all`, `restore-backup-*` |
| `jobs/profile` | `apply-profile-manager`, `apply-profile-enshrouded`, `reset-profile-*`, `check-password*` |
| `jobs/env-validation` | `check-env`, `check-all-env`, `env-init-runtime` |
| `jobs/cron` | `check-cron` + start/stop/restart im Job + Trigger auf `scheduled-*` |
| `jobs/menu` | `run` liest `profiles/menu/menu.json`, nutzt `ui/*` und ruft Commands auf |

## Migrationsphasen mit Prompt-Vorlagen

| Phase | Ziel | Prompt-Vorlage (direkt nutzbar) | Abnahme |
|---|---|---|---|
| 1 | Zielstruktur aufbauen | `Lege die Zielstruktur aus migration.md unter server_manager an (jobs/commands/check|force|scheduled|manual|restore/logs/ui/profiles inkl. profiles/menu/menu.json). Erstelle fehlende Dateien als Platzhalter, ohne Fachlogik zu aendern.` | Alle Zielpfade existieren. |
| 2 | ENV-Spec zentralisieren | `Migriere die ENV-Regeln nach server_manager/profiles/env/env.json. Entferne CSV-Regelpfade aus der Runtime und ersetze sie durch env.json-basierte Validierung.` | `profiles/env/env.json` ist einzige Regelquelle. |
| 3 | Check-Commands extrahieren | `Extrahiere reine Pruefungen in commands/check/* (check-player, check-update, check-password, check-cron, check-env, check-all-env, check-backup-list, check-backup-inspect). Keine Seiteneffekte in diesen Skripten.` | Checks laufen isoliert und schreiben keinen Zustand. |
| 4 | Aktions-Commands extrahieren | `Extrahiere die Aktionslogik in commands/manual/*, commands/force/*, commands/scheduled/* und commands/restore/*. Jeder Command ist direkt aufrufbar und hat genau eine Verantwortung.` | Actions laufen ohne alte Job-Internlogik. |
| 5 | Jobs auf Wrapper reduzieren | `Reduziere jobs/* auf Orchestrierung: JSON lesen, Check optional ausfuehren, genau einen Command-Pfad starten, Exit-Code durchreichen. Entferne Args-Multiplexing. Fuer bootstrap: nur bestehende Commands aufrufen, keine doppelte bootstrap-Fachlogik.` | Jobs enthalten keine Fachlogik mehr. |
| 6 | Supervisor/Docker an neue Pfade binden | `Passe Supervisor-Programme und Docker-Symlinks/Entry-Aufrufe auf die neue Struktur an. Keine Legacy-Aliase behalten.` | Runtime nutzt nur neue Namen/Pfade. |
| 7 | Menu + UI modularisieren | `Stelle jobs/menu auf run-Orchestrierung um: Menuestruktur aus profiles/menu/menu.json lesen, UI aus ui/menu_ui und ui/startup_banner nutzen, Actions direkt auf neue Commands mappen. Entferne doppelte Fachlogik aus dem Menu-Code.` | Menu ist nur Orchestrierung + UI-Dispatch. |
| 8 | Legacy entfernen (Breaking Change) | `Entferne alte Skripte, alte Namen, alte CSV-Parser und alle Abwaertskompatibilitaets-Wrapper vollstaendig.` | Kein verwaister Legacy-Code mehr vorhanden. |
| 9 | Abschluss-Validierung | `Fuehre Smoke-Tests fuer alle Jobs/Commands aus und dokumentiere Ergebnis + offene Punkte in migration.md.` | Alle Kernpfade getestet, Ergebnis dokumentiert. |

## Definition of Done

1. Jeder Eintrag unter `commands/*` ist direkt aufrufbar.
2. `jobs/*` enthalten keine Fachlogik mehr, nur Dispatch.
3. Keine Ablaufsteuerung ueber CLI-Args.
4. Kein `common.sh`-Monolith.
5. Menue ruft Commands statt Altlogik.
6. `logs/log` wird von Jobs/Commands konsistent benutzt.
7. Keine Abwaertskompatibilitaets-Schicht fuer alte Befehle/Pfade vorhanden.
8. `jobs/bootstrap` enthaelt keine doppelte Fachlogik; nur Orchestrierung vorhandener Commands.

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
