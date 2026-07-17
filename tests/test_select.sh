#!/bin/sh
# Selecao interativa (numerada) e instalacao de multiplos agentes, em catalogo proprio.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
AGENTS="$ROOT/bin/agents"

cat=$(mktemp -d)
cp "$ROOT/targets.conf" "$cat/targets.conf"
mkdir -p "$cat/lib"
cp -r "$ROOT/lib/." "$cat/lib/"
for a in agente-a agente-b; do
  d="$cat/agents/$a"; mkdir -p "$d"
  printf -- '---\nname: %s\ndescription: agente %s\n---\ncorpo de %s\n' "$a" "$a" "$a" >"$d/agent.md"
  printf 'name: %s\nversion: 1.0.0\ndescription: agente %s\nsource: agent.md\ntargets: claude\n' "$a" "$a" >"$d/manifest"
done

# Selecao interativa por numero (le "1" da entrada padrao; agente-a e o primeiro)
proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"
rc=0; printf '1\n' | AGENTS_HOME="$cat" "$AGENTS" install --target claude >/dev/null 2>&1 || rc=$?
assert_exit 0 "$rc" "selecao interativa por numero sai 0"
assert_file_exists "$proj/.claude/agents/agente-a.md" "primeiro agente selecionado foi instalado"
assert_file_absent "$proj/.claude/agents/agente-b.md" "o nao selecionado nao foi instalado"
cd "$ROOT"; rm -rf "$proj"

# Selecao "all"
proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"
rc=0; printf 'all\n' | AGENTS_HOME="$cat" "$AGENTS" install --target claude >/dev/null 2>&1 || rc=$?
assert_exit 0 "$rc" "selecao all sai 0"
assert_file_exists "$proj/.claude/agents/agente-a.md" "all instala o primeiro"
assert_file_exists "$proj/.claude/agents/agente-b.md" "all instala o segundo"
cd "$ROOT"; rm -rf "$proj"

# Instalacao de multiplos agentes por nome
proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"
rc=0; AGENTS_HOME="$cat" "$AGENTS" install agente-a agente-b --target claude >/dev/null 2>&1 || rc=$?
assert_exit 0 "$rc" "instalacao de multiplos nomes sai 0"
assert_file_exists "$proj/.claude/agents/agente-a.md" "agente-a instalado"
assert_file_exists "$proj/.claude/agents/agente-b.md" "agente-b instalado"
cd "$ROOT"; rm -rf "$proj" "$cat"

assert_done
