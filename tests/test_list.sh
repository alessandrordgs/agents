#!/bin/sh
# T015: listagem com campos e marcacao de instalados (FR-009, FR-010).
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
AGENTS="$ROOT/bin/agents"

proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"

# catalogo mostra example-agent com versao e alvos
out=$("$AGENTS" list 2>&1)
case "$out" in *"example-agent"*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "list mostra example-agent"
case "$out" in *"1.0.0"*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "list mostra a versao"
case "$out" in *"claude,codex,opencode"*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "list mostra os alvos"

# nao instalado ainda: sem marca
line=$(printf '%s\n' "$out" | grep example-agent)
first=$(printf '%s' "$line" | cut -c1)
if [ "$first" = "*" ]; then got=marked; else got=unmarked; fi
assert_eq unmarked "$got" "nao instalado nao tem marca"

"$AGENTS" install example-agent --target claude >/dev/null 2>&1

out=$("$AGENTS" list 2>&1)
line=$(printf '%s\n' "$out" | grep example-agent)
first=$(printf '%s' "$line" | cut -c1)
if [ "$first" = "*" ]; then got=marked; else got=unmarked; fi
assert_eq marked "$got" "instalado tem marca *"

out=$("$AGENTS" list --installed 2>&1)
case "$out" in *"example-agent"*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "--installed lista o instalado"

cd "$ROOT"; rm -rf "$proj"
assert_done
