#!/bin/sh
# T011: conflito, recusa por alvo, agente desconhecido, manifesto invalido (SC-004, FR-004/06/07/10).
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
AGENTS="$ROOT/bin/agents"

# 1) Conflito com arquivo do usuario: aborta sem sobrescrever
proj=$(mktemp -d); mkdir -p "$proj/.claude/agents"; cd "$proj"
printf 'CONTEUDO DO USUARIO\n' >"$proj/.claude/agents/example-agent.md"
rc=0; "$AGENTS" install example-agent --target claude >/dev/null 2>&1 || rc=$?
assert_exit 3 "$rc" "conflito retorna 3"
assert_eq "CONTEUDO DO USUARIO" "$(cat "$proj/.claude/agents/example-agent.md")" "arquivo do usuario nao foi sobrescrito"
assert_file_absent "$proj/.agents/lock" "nada gravado no lock em conflito"
cd "$ROOT"; rm -rf "$proj"

# 2) Agente desconhecido
proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"
rc=0; "$AGENTS" install inexistente --target claude >/dev/null 2>&1 || rc=$?
assert_exit 4 "$rc" "agente desconhecido retorna 4"
cd "$ROOT"; rm -rf "$proj"

# Catalogo temporario para casos de suporte e manifesto invalido
cat=$(mktemp -d)
cp "$ROOT/targets.conf" "$cat/targets.conf"
mkdir -p "$cat/lib"
cp -r "$ROOT/lib/." "$cat/lib/"

# 3) Alvo nao suportado: agente que so declara claude, instalar em codex
mkdir -p "$cat/agents/only-claude"
printf -- '---\nname: only-claude\ndescription: so claude\n---\ncorpo\n' >"$cat/agents/only-claude/agent.md"
cat >"$cat/agents/only-claude/manifest" <<'EOF'
name: only-claude
version: 1.0.0
description: suporta apenas claude
source: agent.md
targets: claude
EOF
proj=$(mktemp -d); mkdir -p "$proj/.codex"; cd "$proj"
rc=0; AGENTS_HOME="$cat" "$AGENTS" install only-claude --target codex >/dev/null 2>&1 || rc=$?
assert_exit 4 "$rc" "alvo nao suportado retorna 4"
assert_file_absent "$proj/.agents/lock" "nada instalado quando alvo nao suportado"
cd "$ROOT"; rm -rf "$proj"

# 4) Manifesto invalido (sem version): rejeitado antes de escrever
mkdir -p "$cat/agents/broken"
printf -- '---\nname: broken\ndescription: x\n---\ncorpo\n' >"$cat/agents/broken/agent.md"
cat >"$cat/agents/broken/manifest" <<'EOF'
name: broken
description: sem versao
source: agent.md
targets: claude
EOF
proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"
rc=0; AGENTS_HOME="$cat" "$AGENTS" install broken --target claude >/dev/null 2>&1 || rc=$?
assert_exit 4 "$rc" "manifesto invalido retorna 4"
assert_file_absent "$proj/.claude/agents/broken.md" "nada escrito com manifesto invalido"
cd "$ROOT"; rm -rf "$proj"

rm -rf "$cat"
assert_done
