#!/bin/sh
# T015 (feature 001) + hidden: listagem com campos, marcacao e filtro de ocultos.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
AGENTS="$ROOT/bin/agents"

cat=$(mktemp -d)
cp "$ROOT/targets.conf" "$cat/targets.conf"
mkdir -p "$cat/lib"
cp -r "$ROOT/lib/." "$cat/lib/"
mkagent() { # name [hidden]
  d="$cat/agents/$1"; mkdir -p "$d"
  printf -- '---\nname: %s\ndescription: agente %s\n---\ncorpo\n' "$1" "$1" >"$d/agent.md"
  printf 'name: %s\nversion: 1.2.3\ndescription: agente %s\nsource: agent.md\ntargets: claude\n' "$1" "$1" >"$d/manifest"
  if [ "${2:-}" = hidden ]; then printf 'hidden: true\n' >>"$d/manifest"; fi
  return 0
}
mkagent vis
mkagent hid hidden

proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"

out=$(AGENTS_HOME="$cat" "$AGENTS" list 2>&1)
case "$out" in *vis*) g=1 ;; *) g=0 ;; esac
assert_eq 1 "$g" "list mostra o agente visivel"
case "$out" in *hid*) g=1 ;; *) g=0 ;; esac
assert_eq 0 "$g" "list oculta o agente hidden"
case "$out" in *1.2.3*) g=1 ;; *) g=0 ;; esac
assert_eq 1 "$g" "list mostra a versao"

out=$(AGENTS_HOME="$cat" "$AGENTS" list --all 2>&1)
case "$out" in *hid*) g=1 ;; *) g=0 ;; esac
assert_eq 1 "$g" "list --all mostra ocultos"

AGENTS_HOME="$cat" "$AGENTS" install vis --target claude >/dev/null 2>&1
out=$(AGENTS_HOME="$cat" "$AGENTS" list 2>&1)
line=$(printf '%s\n' "$out" | grep vis)
first=$(printf '%s' "$line" | cut -c1)
if [ "$first" = "*" ]; then g=marked; else g=unmarked; fi
assert_eq marked "$g" "instalado tem marca *"

cd "$ROOT"; rm -rf "$cat" "$proj"
assert_done
