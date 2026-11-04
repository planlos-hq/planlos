# planlos

Skripte, um mit allen PlanLos-Repos gleichzeitig zu arbeiten. `clone.sh` klont
die Repos in diesen Ordner (`./planlos-*`, per `.gitignore` ausgeschlossen), per
SSH und bei Fehlschlag per HTTPS.

```bash
./clone.sh               # alle Repos (außer .github) klonen, vorhandene überspringen
./commit.sh "Nachricht"  # in jedem Repo mit Änderungen alles committen
./push.sh                # aktuellen Branch jedes Repos pushen
./pull.sh                # aktuellen Stand in allen Repos pullen
./start.sh               # Stack neu bauen und starten
./stop.sh                # Stack stoppen
./testdata.sh            # Datenbank mit fiktiven Demodaten füllen
./clear.sh               # alle geklonten Repos löschen (Bestätigung mit yes/ja)
```

## Dev-CLI planlos

In der Nix-Shell (`nix develop` bzw. direnv) steht zusätzlich die Go-CLI
`planlos` bereit. Sie bündelt dieselben Skripte als Befehle:

```bash
planlos --help             # zeigt alle Befehle an
planlos clone              # alle Repos (außer .github) klonen, vorhandene überspringen
planlos commit "Nachricht" # in jedem Repo mit Änderungen alles committen
planlos push               # aktuellen Branch jedes Repos pushen
planlos pull               # aktuellen Stand in allen Repos pullen
planlos start              # Stack neu bauen und starten
planlos stop               # Stack stoppen
planlos testdata           # Datenbank mit fiktiven Demodaten füllen
planlos clear              # alle geklonten Repos löschen (Bestätigung mit yes/ja)
```

Ohne Nix lässt sich die CLI im Hauptrepo mit `go run . <befehl>` starten.
