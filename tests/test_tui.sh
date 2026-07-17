#!/bin/sh
# Logica do seletor interativo (toggle e carga do catalogo). A navegacao por
# teclas exige um terminal e e validada manualmente/por pty, nao aqui.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
# shellcheck source=/dev/null
. "$ROOT/lib/manifest.sh"
# shellcheck source=/dev/null
. "$ROOT/lib/tui.sh"
AGENTS_HOME="$ROOT"; export AGENTS_HOME
_ag_N=0; n1=''

# tui_toggle: marca quando ausente, desmarca quando presente (por pertinencia)
s=$(tui_toggle ' ' 2)
case "$s" in *" 2 "*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "toggle marca indice ausente"
s=$(tui_toggle "$s" 2)
case "$s" in *" 2 "*) got=1 ;; *) got=0 ;; esac
assert_eq 0 "$got" "toggle desmarca indice presente"

# tui_load_catalog conta e indexa os agentes do catalogo
tui_load_catalog
exp=$(find "$ROOT"/agents -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq "$exp" "$_ag_N" "load conta todos os agentes"
eval "n1=\$_ag_name_1"
assert_eq example-agent "$n1" "primeiro agente indexado e example-agent"

assert_done
