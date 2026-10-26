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

## Gesamter Stack mit Docker Compose

Baut db, server, web und docs aus den geklonten Repos.

```bash
cp .env.example .env
docker compose up -d --build
```

| Dienst | Adresse               |
| ------ | --------------------- |
| docs   | http://127.0.0.1:8001 |
| web    | http://127.0.0.1:8002 |
| db     | 127.0.0.1:8003        |
| server | http://127.0.0.1:8004 |

## Entwicklung

Mit Nix: `direnv allow` bzw. `nix develop` – eine Shell mit den Werkzeugen aller
Repos (Go, Node, PostgreSQL, pgFormatter, JDK, uv, Zensical, …).
