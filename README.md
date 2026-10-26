# planlos

Skripte, um mit allen PlanLos-Repos gleichzeitig zu arbeiten. `clone.sh` klont
die Repos in diesen Ordner (`./planlos-*`, per `.gitignore` ausgeschlossen),
per SSH und bei Fehlschlag per HTTPS.

Bewusst ohne Git-Submodule: Diese verursachen mehr Probleme, als sie lösen.
Jedes Repo bleibt hier deshalb ein einfacher Klon.

```bash
./clone.sh               # alle Repos (außer .github) klonen, vorhandene überspringen
./commit.sh "Nachricht"  # in jedem Repo mit Änderungen alles committen
./push.sh                # aktuellen Branch jedes Repos pushen
```

## Installation auf einem Server

Klont alles nach `./planlos` (anderer Ordner per `PLANLOS_DIR`), fragt die Links
für Hilfe und Impressum, optional das Impressum der Dokumentation und Testdaten ab, legt
`.env` mit zufälligem Datenbank-Passwort an und startet den Stack. Bei erneutem
Aufruf bleiben `.env` und Einstellungen erhalten.

Später ändern: Hilfe- und Impressum-Link in `planlos-web/settings.yml` (Seite neu
laden genügt), das Impressum der Dokumentation in `planlos-docs/settings.yml`
(wird beim Bauen eingebaut, danach `docker compose --profile docs up -d --build docs`).

```bash
curl -fsSL https://raw.githubusercontent.com/planlos-hq/planlos/main/install.sh | bash
```

## Testdaten

`./testdata.sh` füllt die Datenbank des laufenden Stacks mit erfundenen Daten
([`testdata.sql`](testdata.sql)): 6 Studiengänge mit je 3 Jahrgängen, 91 Kurse
mit 183 Terminen, 36 Dozierende und 20 Räume. Der Plan ist überschneidungsfrei
bis auf einige absichtliche Konflikte zum Ausprobieren (im Kopf der Datei
beschrieben). Bricht ab, wenn schon
Daten vorhanden sind. Mit Podman: `./testdata.sh podman-compose`.

Sichtbar sind die Daten nur mit Anmeldung: Der Server beantwortet nur Anfragen,
deren `Remote_user` (Shibboleth) in `authorized_user` steht, sonst Fehler 403.
Zum lokalen Testen ohne Shibboleth `NO_AUTH=1` in `.env` setzen und den Server
neu erstellen (`docker compose up -d server`). Nie auf einem erreichbaren Server.

## Gesamter Stack mit Docker Compose

Baut db, server und web aus den geklonten Repos. docs ist optional und
startet nur mit `docker compose --profile docs up -d --build`.

```bash
cp .env.example .env
docker compose up -d --build
```

| Dienst | Adresse               |
| ------ | --------------------- |
| docs   | http://127.0.0.1:8001 (optional) |
| web    | http://127.0.0.1:8002 |
| db     | 127.0.0.1:8003        |
| server | http://127.0.0.1:8004 |

## Entwicklung

Mit Nix: `direnv allow` bzw. `nix develop` – eine Shell mit den Werkzeugen aller
Repos (Go, Node, PostgreSQL, pgFormatter, JDK, uv, Zensical, …).
