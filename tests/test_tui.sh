#!/bin/sh
# Logica do seletor (toggle, carga do catalogo, filtro de ocultos). A navegacao por
# teclas exige um terminal e e validada por pty, nao aqui.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"

cat=$(mktemp -d)
cp "$ROOT/targets.conf" "$cat/targets.conf"
for spec in "agente-a" "agente-b" "oculto:hidden"; do
  name=${spec%%:*}
  d="$cat/agents/$name"; mkdir -p "$d"
  printf -- '---\nname: %s\ndescription: agente %s\n---\ncorpo\n' "$name" "$name" >"$d/agent.md"
  printf 'name: %s\nversion: 1.0.0\ndescription: agente %s\nsource: agent.md\ntargets: claude\n' "$name" "$name" >"$d/manifest"
  case "$spec" in *:hidden) printf 'hidden: true\n' >>"$d/manifest" ;; esac
done

# shellcheck source=/dev/null
. "$ROOT/lib/manifest.sh"
# shellcheck source=/dev/null
. "$ROOT/lib/tui.sh"
AGENTS_HOME="$cat"; export AGENTS_HOME
_ag_N=0; n1=''

# tui_toggle: marca quando ausente, desmarca quando presente (por pertinencia)
s=$(tui_toggle ' ' 2)
case "$s" in *" 2 "*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "toggle marca indice ausente"
s=$(tui_toggle "$s" 2)
case "$s" in *" 2 "*) got=1 ;; *) got=0 ;; esac
assert_eq 0 "$got" "toggle desmarca indice presente"

# tui_load_catalog conta apenas os visiveis (oculto fora)
tui_load_catalog
assert_eq 2 "$_ag_N" "load ignora agentes ocultos"
eval "n1=\$_ag_name_1"
assert_eq agente-a "$n1" "primeiro agente indexado e agente-a"

rm -rf "$cat"
assert_done
