#!/bin/sh
# T028 (feature 001): selecao interativa e instalacao de multiplos agentes.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
AGENTS="$ROOT/bin/agents"

# Selecao interativa por numero (le "1" da entrada padrao; agentes em ordem alfabetica)
proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"
rc=0; printf '1\n' | "$AGENTS" install --target claude >/dev/null 2>&1 || rc=$?
assert_exit 0 "$rc" "selecao interativa por numero sai 0"
assert_file_exists "$proj/.claude/agents/example-agent.md" "primeiro agente selecionado foi instalado"
cd "$ROOT"; rm -rf "$proj"

# Selecao "all"
proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"
rc=0; printf 'all\n' | "$AGENTS" install --target claude >/dev/null 2>&1 || rc=$?
assert_exit 0 "$rc" "selecao all sai 0"
assert_file_exists "$proj/.claude/agents/example-agent.md" "all instala o catalogo"
cd "$ROOT"; rm -rf "$proj"

# Instalacao de multiplos agentes por nome, com catalogo temporario de dois agentes
cat=$(mktemp -d)
cp "$ROOT/targets.conf" "$cat/targets.conf"
mkdir -p "$cat/lib"
cp -r "$ROOT/lib/." "$cat/lib/"
for a in agent-a agent-b; do
  mkdir -p "$cat/agents/$a"
  printf -- '---\nname: %s\ndescription: agente %s\n---\ncorpo de %s\n' "$a" "$a" "$a" >"$cat/agents/$a/agent.md"
  cat >"$cat/agents/$a/manifest" <<EOF
name: $a
version: 1.0.0
description: agente $a para teste multi
source: agent.md
targets: claude
EOF
done

proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"
rc=0; AGENTS_HOME="$cat" "$AGENTS" install agent-a agent-b --target claude >/dev/null 2>&1 || rc=$?
assert_exit 0 "$rc" "instalacao de multiplos nomes sai 0"
assert_file_exists "$proj/.claude/agents/agent-a.md" "agent-a instalado"
assert_file_exists "$proj/.claude/agents/agent-b.md" "agent-b instalado"
cd "$ROOT"; rm -rf "$proj" "$cat"

assert_done
