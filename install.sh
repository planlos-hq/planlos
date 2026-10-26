#!/usr/bin/env bash
# Install PlanLos: clone the repos, ask for help/Impressum details, write .env
# and the settings.yml files, then build and start the stack. Offers to install
# git and Docker or Podman when missing.
# Usage: curl -fsSL https://raw.githubusercontent.com/planlos-hq/planlos/main/install.sh | bash
# Target folder via PLANLOS_DIR (default ./planlos). Re-running keeps .env and settings.
set -euo pipefail

# Colours only on a terminal
if [[ -t 1 ]]; then
  B=$'\e[1m' D=$'\e[2m' R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[36m' N=$'\e[0m'
else
  B='' D='' R='' G='' Y='' C='' N=''
fi
step() { printf '\n%s[%s/4]%s %s%s%s\n' "$C" "$1" "$N" "$B" "$2" "$N"; }
ok() { printf '  %s✔%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
die() { printf '  %s✖ %s%s\n' "$R" "$*" "$N" >&2; exit 1; }

# Prompts use the terminal, stdin is this script when piped from curl
ask() { # ask VAR "question" [default]
  local answer
  printf '  %s?%s %s%s: ' "$C" "$N" "$2" "${3:+ $D[$3]$N}" >/dev/tty
  read -r answer </dev/tty
  printf -v "$1" '%s' "${answer:-${3:-}}"
}
confirm() { local a; ask a "$1 (j/n)" "${2:-j}"; [[ $a == [jJyY]* ]]; }

SUDO=''
[[ $EUID -ne 0 ]] && SUDO=sudo
pkg_install() {
  if command -v apt-get >/dev/null; then $SUDO apt-get update -qq && $SUDO apt-get install -y "$@"
  elif command -v dnf >/dev/null; then $SUDO dnf install -y "$@"
  elif command -v pacman >/dev/null; then $SUDO pacman -S --needed --noconfirm "$@"
  elif command -v zypper >/dev/null; then $SUDO zypper install -y "$@"
  else die "Kein unterstützter Paketmanager gefunden, bitte $* selbst installieren"; fi
}

find_compose() {
  local c
  for c in "docker compose" "podman compose" podman-compose docker-compose; do
    if $c version >/dev/null 2>&1; then read -ra COMPOSE <<<"$c"; return; fi
  done
  return 1
}

install_compose() {
  warn "Weder Docker noch Podman (mit Compose) gefunden"
  printf '    1) Docker  %s(offizielles Skript von get.docker.com)%s\n' "$D" "$N"
  printf '    2) Podman  %s(aus den Paketen der Distribution)%s\n' "$D" "$N"
  printf '    3) Abbrechen\n'
  local choice
  ask choice "Auswahl" 1
  case $choice in
    1) curl -fsSL https://get.docker.com | $SUDO sh
       $SUDO systemctl enable --now docker ;;
    2) pkg_install podman podman-compose ;;
    *) die "Abgebrochen. Docker oder Podman installieren und erneut ausführen." ;;
  esac
  find_compose || die "Compose nach der Installation nicht gefunden"
}

# Replace a scalar in a 2-space indented YAML file, e.g. set_yaml f.yml help.link "https://…"
set_yaml() {
  local s=${3//\\/\\\\}
  K=$2 V="\"${s//\"/\\\"}\"" awk '
    /^ *[A-Za-z_]+:/ {
      n = match($0, /[^ ]/) - 1
      key = $0; sub(/^ */, "", key); sub(/:.*/, "", key)
      path[n / 2] = key; p = path[0]
      for (i = 1; i <= n / 2; i++) p = p "." path[i]
      if (p == ENVIRON["K"]) $0 = substr($0, 1, n) key ": " ENVIRON["V"]
    } 1' "$1" >"$1.tmp" && mv "$1.tmp" "$1"
}

main() {
  local dir="${PLANLOS_DIR:-$PWD/planlos}" docs=n testdata=n v rc=0
  printf '\n%sPlanLos%s %s– Installation nach %s%s\n' "$B" "$N" "$D" "$dir" "$N"

  step 1 "Voraussetzungen prüfen"
  if ! command -v git >/dev/null; then
    confirm "git fehlt. Jetzt installieren?" || die "Abgebrochen, git wird benötigt"
    pkg_install git
  fi
  ok "git"
  find_compose || install_compose
  # Docker: daemon running and usable without root, otherwise via sudo
  if [[ ${COMPOSE[0]} == docker* ]] && ! docker info >/dev/null 2>&1; then
    $SUDO systemctl start docker 2>/dev/null || true
    if ! docker info >/dev/null 2>&1; then
      $SUDO docker info >/dev/null 2>&1 || die "Docker läuft nicht (sudo systemctl start docker)"
      COMPOSE=("$SUDO" "${COMPOSE[@]}")
      warn "Docker nur mit sudo nutzbar"
    fi
  fi
  ok "${COMPOSE[*]}"

  step 2 "Herunterladen"
  # SSH when a GitHub key works (ssh -T exits 1 on success), HTTPS otherwise
  ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com >/dev/null 2>&1 || rc=$?
  if [[ $rc -eq 1 ]]; then export PLANLOS_ORG="git@github.com:planlos-hq"; ok "per SSH"
  else export PLANLOS_ORG="https://github.com/planlos-hq"; ok "per HTTPS"; fi
  [[ -d "$dir" ]] || git clone -q "$PLANLOS_ORG/planlos.git" "$dir"
  "$dir/clone.sh"
  cd "$dir"

  step 3 "Einstellungen"
  # Asked on first run only, .env is written last so an abort asks again
  if [[ -f .env ]]; then
    ok "vorhanden, übersprungen (.env löschen, um neu zu fragen)"
    grep -q '^COMPOSE_PROFILES=docs' .env && docs=j
  else
    printf '  %sLeer lassen blendet die Zeile aus.%s\n' "$D" "$N"
    ask v "Link zur Hilfe/Dokumentation"
    set_yaml planlos-web/settings.yml help.link "$v"
    ask v "Link zum Impressum"
    set_yaml planlos-web/settings.yml impressum.link "$v"

    if confirm "Dokumentation mitstarten?" n; then
      docs=j
      printf '\n  %sImpressum der Dokumentation%s\n' "$B" "$N"
      while IFS='|' read -r key prompt default; do
        ask v "$prompt" "$default"
        set_yaml planlos-docs/settings.yml "impressum.$key" "$v"
      done <<'EOF'
anbieter.name|Name der Hochschule
anbieter.einheit|Organisationseinheit (z. B. Fachbereich)
anbieter.strasse|Straße und Hausnummer
anbieter.ort|PLZ und Ort
anbieter.land|Land|Deutschland
vertreten_durch|Vertreten durch (Name, Funktion)
kontakt.telefon|Telefon
kontakt.email|E-Mail (möglichst Funktionspostfach)
verantwortlich.name|Inhaltlich verantwortlich (Name oder Funktion)
datenschutz_url|Link zur Datenschutzerklärung
EOF
    fi

    printf '\n'
    confirm "PlanLos mit Testdaten füllen? (erfundene Kurse, Räume, Dozierende)" n && testdata=j

    sed "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')/" \
      .env.example >.env.tmp
    [[ $docs == j ]] && echo "COMPOSE_PROFILES=docs" >>.env.tmp
    mv .env.tmp .env
    ok ".env mit zufälligem Datenbank-Passwort angelegt"
  fi

  step 4 "Bauen und starten"
  local profile=()
  [[ $docs == j ]] && profile=(--profile docs)
  "${COMPOSE[@]}" "${profile[@]}" up -d --build
  if [[ $testdata == j ]]; then
    ./testdata.sh "${COMPOSE[@]}" >/dev/null && ok "Testdaten eingefügt" ||
      warn "Testdaten nicht eingefügt, später mit ./testdata.sh ${COMPOSE[*]}"
  fi

  printf '\n%s✔ PlanLos läuft%s\n' "$G$B" "$N"
  printf '  Web     http://localhost:%s\n' "$(sed -n 's/^WEB_PORT=//p' .env)"
  [[ $docs == j ]] && printf '  Docs    http://127.0.0.1:%s\n' "$(sed -n 's/^DOCS_PORT=//p' .env)"
  printf '  Ordner  %s\n' "$dir"
  printf '  %sÄnderbar: .env, planlos-web/settings.yml (Seite neu laden genügt)%s\n' "$D" "$N"
  [[ $docs == j ]] &&
    printf '  %sImpressum der Doku: planlos-docs/settings.yml, danach neu bauen:%s\n    %s --profile docs up -d --build docs\n' \
      "$D" "$N" "${COMPOSE[*]}"
  echo
}

main "$@"
