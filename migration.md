# Migration Plan - Reorganisation Server Manager

## Ziel

Die Reorganisation hat zwei harte Ziele:

1. Code-Reduktion (Duplikate raus, kleinere Skripte, weniger Mischlogik).
2. Klare Verantwortlichkeit pro Skript (Job-Wrapper vs. Fach-Command).

## Leitprinzipien

1. `jobs/*` enthalten nur Orchestrierung.
2. `commands/*` enthalten nur Fachlogik.
3. `logs/log` ist der zentrale Log-Sink.
4. Kein generisches `run`-Command.
5. Kein `common.sh` als zentrale Sammel-Library.
6. Jeder Command muss eigenstaendig direkt aufrufbar sein.
7. Checks werden vom Job bei Bedarf vor/nach Aktionen aufgerufen (wenn deaktiviert: Command nicht aufrufen).

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
    menu

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
```

## Verantwortlichkeit je Gruppe

### Jobs (Supervisor/Wrapper)

| Datei | Rolle | Darf enthalten | Darf nicht enthalten |
|---|---|---|---|
| `jobs/server` | Prozesssteuerung Server | supervisor/start/stop/status, guard | Backup-/Update-/Profile-Fachlogik |
| `jobs/bootstrap` | Initiale Reihenfolge | init + Auswahl welche Commands laufen | Eigene Update-/Backup-Implementierung |
| `jobs/crond` | Cron-Orchestrierung | start/stop/restart im Job, Check via `check-cron` | Eigene Cron-Businesslogik doppeln |
| `jobs/rsyslogd` | Logging-Prozess | rsyslogd start/health | Fachlogik |
| `jobs/restart` | Restart-Flow Dispatch | config lesen + `check/force/manual/scheduled` aufrufen | Restart-Implementierung im Job |
| `jobs/update` | Update-Flow Dispatch | config lesen + `check/force/manual/scheduled` aufrufen | Update-Implementierung im Job |
| `jobs/backup` | Backup/Restore Dispatch | mode/flags lesen + passende Commands | Zip/restore Details im Job |
| `jobs/profile` | Profil-Dispatch | apply/reset/check-password Commands aufrufen (text view only) | Profil-Merge-Details im Job |
| `jobs/env` | ENV-Dispatch | `check-env`, `check-all-env`, `env-init-runtime` | Vollstaendige Validator-Engine im Job |
| `jobs/menu` | UI/Navigation | Menuefluss + Command-Aufrufe | Fachlogik von backup/update/profile duplizieren |

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

## Job -> Command Aufrufmodell

Standardablauf in Jobs:

1. Eingaben lesen (`args`, `server_manager.json`, `enshrouded_server.json`).
2. Check-Commands aufrufen (nur wenn aktiv).
3. Danach den Aktions-Command aufrufen (`manual`, `scheduled`, `force`, `restore`).
4. Exit-Code unverfaelscht nach oben geben.

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
| `jobs/menu` | Nur UI; ruft neue Commands auf |

## Migrationsphasen

| Phase | Arbeitspaket | Ergebnis |
|---|---|---|
| 1 | Ordnerstruktur anlegen (`commands/*`, `logs/log`) | Zielstruktur steht |
| 2 | Leere Command-Dateien mit Shebang/Exit-Kontrakt anlegen | Standardisiertes Command-API |
| 3 | Check-Logik aus Altcode extrahieren (`check/*`) | Pruefpfad getrennt |
| 4 | Restart/Update in `manual|force|scheduled` zerlegen | Kernablauf entkoppelt |
| 5 | Backup/Restore in feine Commands zerlegen | Komplexitaet sinkt, Wiederverwendung klar |
| 6 | Profile-Apply in `manual/*` und Profile-Reset in `restore/*` splitten | Profil-Logik getrennt |
| 7 | Jobs zu reinen Wrappern reduzieren | Verantwortlichkeit klar |
| 8 | Supervisor + Docker Symlinks auf neue Jobs/Commands mappen | Laufzeit integriert |
| 9 | Menu schrittweise auf neue Commands umstellen | Keine doppelte Fachlogik im Menu |
| 10 | Alte Duplikate entfernen, Doku aktualisieren | Codebasis kompakter und konsistent |

## Definition of Done

1. Jeder Eintrag unter `commands/*` ist direkt aufrufbar.
2. `jobs/*` enthalten keine Fachlogik mehr, nur Dispatch.
3. Kein `run`-Sammelcommand.
4. Kein `common.sh`-Monolith.
5. Menue ruft Commands statt Altlogik.
6. `logs/log` wird von Jobs/Commands konsistent benutzt.
7. Bestehende Nutzerbefehle bleiben funktional (kompatibler Wrapper erlaubt).

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
