#!/bin/sh
# T021: remocao restaura o projeto sem tocar arquivos alheios (FR-012, FR-013, SC-005).
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
AGENTS="$ROOT/bin/agents"

proj=$(mktemp -d); mkdir -p "$proj/.claude/agents"; cd "$proj"
printf 'ARQUIVO ALHEIO\n' >"$proj/.claude/agents/keep.md"

"$AGENTS" install example-agent --target claude >/dev/null
assert_file_exists "$proj/.claude/agents/example-agent.md" "agente instalado antes de remover"

rc=0; out=$("$AGENTS" remove example-agent 2>&1) || rc=$?
assert_exit 0 "$rc" "remove sai 0"
assert_file_absent "$proj/.claude/agents/example-agent.md" "arquivo do agente removido"
assert_eq "ARQUIVO ALHEIO" "$(cat "$proj/.claude/agents/keep.md")" "arquivo alheio intacto"
if lock_line=$(grep example-agent "$proj/.agents/lock" 2>/dev/null); then got=present; else got=absent; fi
assert_eq absent "$got" "lock nao referencia mais o agente"

# remover de novo: no-op
rc=0; out=$("$AGENTS" remove example-agent 2>&1) || rc=$?
assert_exit 0 "$rc" "remove no-op sai 0"
case "$out" in *"nada a remover"*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "remover nao instalado e no-op"

cd "$ROOT"; rm -rf "$proj"
assert_done
