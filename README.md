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
für Hilfe und Impressum sowie optional das Impressum der Dokumentation ab, legt
`.env` mit zufälligem Datenbank-Passwort an und startet den Stack. Bei erneutem
Aufruf bleiben `.env` und Einstellungen erhalten.

Später ändern: Hilfe- und Impressum-Link in `planlos-web/settings.yml` (Seite neu
laden genügt), das Impressum der Dokumentation in `planlos-docs/settings.yml`
(wird beim Bauen eingebaut, danach `docker compose --profile docs up -d --build docs`).

```bash
curl -fsSL https://raw.githubusercontent.com/planlos-hq/planlos/main/install.sh | bash
```

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
