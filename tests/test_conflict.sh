#!/bin/sh
# T011: conflito, recusa por alvo, agente desconhecido, manifesto invalido (SC-004, FR-004/06/07/14).
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
AGENTS="$ROOT/bin/agents"

# 1) Conflito com arquivo do usuario: aborta sem sobrescrever
proj=$(mktemp -d); mkdir -p "$proj/.claude/agents"; cd "$proj"
printf 'CONTEUDO DO USUARIO\n' >"$proj/.claude/agents/example-agent.md"
rc=0; out=$("$AGENTS" install example-agent --target claude 2>&1) || rc=$?
assert_exit 3 "$rc" "conflito retorna 3"
assert_eq "CONTEUDO DO USUARIO" "$(cat "$proj/.claude/agents/example-agent.md")" "arquivo do usuario nao foi sobrescrito"
assert_file_absent "$proj/.agents/lock" "nada gravado no lock em conflito"
cd "$ROOT"; rm -rf "$proj"

# 2) Agente desconhecido
proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"
rc=0; out=$("$AGENTS" install inexistente --target claude 2>&1) || rc=$?
assert_exit 4 "$rc" "agente desconhecido retorna 4"
cd "$ROOT"; rm -rf "$proj"

# Catalogo temporario para casos de suporte e manifesto invalido
cat=$(mktemp -d)
cp "$ROOT/targets.conf" "$cat/targets.conf"
mkdir -p "$cat/lib" "$cat/agents"
cp -r "$ROOT/lib/." "$cat/lib/"
cp "$ROOT/bin/agents" "$cat/agents-bin" 2>/dev/null || true

# 3) Alvo nao suportado: agente que so declara claude, instalar em codex
mkdir -p "$cat/agents/only-claude/claude"
printf '# only\n' >"$cat/agents/only-claude/claude/a.md"
cat >"$cat/agents/only-claude/manifest" <<'EOF'
name: only-claude
version: 1.0.0
description: suporta apenas claude
target: claude
  dest: .claude/agents
  file: claude/a.md
EOF
proj=$(mktemp -d); mkdir -p "$proj/.codex"; cd "$proj"
rc=0; out=$(AGENTS_HOME="$cat" "$AGENTS" install only-claude --target codex 2>&1) || rc=$?
assert_exit 4 "$rc" "alvo nao suportado retorna 4"
assert_file_absent "$proj/.agents/lock" "nada instalado quando alvo nao suportado"
cd "$ROOT"; rm -rf "$proj"

# 4) Manifesto invalido (sem version): rejeitado antes de escrever
mkdir -p "$cat/agents/broken/claude"
printf '# x\n' >"$cat/agents/broken/claude/a.md"
cat >"$cat/agents/broken/manifest" <<'EOF'
name: broken
description: sem versao
target: claude
  dest: .claude/agents
  file: claude/a.md
EOF
proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"
rc=0; out=$(AGENTS_HOME="$cat" "$AGENTS" install broken --target claude 2>&1) || rc=$?
assert_exit 4 "$rc" "manifesto invalido retorna 4"
assert_file_absent "$proj/.claude/agents/a.md" "nada escrito com manifesto invalido"
cd "$ROOT"; rm -rf "$proj"

rm -rf "$cat"
assert_done
