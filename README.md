# planlos

Skripte, um mit allen PlanLos-Repos gleichzeitig zu arbeiten. `clone.sh` klont
die Repos in diesen Ordner (`./planlos-*`, per `.gitignore` ausgeschlossen),
per SSH und bei Fehlschlag per HTTPS.

```bash
./clone.sh               # alle Repos (außer .github) klonen, vorhandene überspringen
./commit.sh "Nachricht"  # in jedem Repo mit Änderungen alles committen
./push.sh                # aktuellen Branch jedes Repos pushen
./pull.sh                # pulled den aktuellen stand in  allen Repos
./testdata.sh            # füllt die Datenbank mit Unechten Daten für Demozwecke
```
