#!/bin/sh
# T010: instalacao nos tres alvos + idempotencia (cobre SC-002, SC-003, SC-006).
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
AGENTS="$ROOT/bin/agents"

# target|marker|destfile
for spec in \
  "claude|.claude|.claude/agents/example-agent.md" \
  "codex|.codex|.codex/prompts/example-agent.md" \
  "opencode|.opencode|.opencode/agent/example-agent.md"; do
  tgt=${spec%%|*}; rest=${spec#*|}; marker=${rest%%|*}; destfile=${rest#*|}
  proj=$(mktemp -d)
  mkdir -p "$proj/$marker"
  cd "$proj"

  rc=0; out=$("$AGENTS" install example-agent --target "$tgt" 2>&1) || rc=$?
  assert_exit 0 "$rc" "install $tgt sai 0"
  assert_file_exists "$proj/$destfile" "arquivo instalado em $tgt"
  assert_file_exists "$proj/.agents/lock" "lock criado em $tgt"
  lines=$(wc -l <"$proj/.agents/lock" | tr -d ' ')
  assert_eq 1 "$lines" "uma linha no lock em $tgt"

  # reinstalar: no-op idempotente
  rc=0; out=$("$AGENTS" install example-agent --target "$tgt" 2>&1) || rc=$?
  assert_exit 0 "$rc" "reinstall $tgt sai 0"
  case "$out" in *"nada a fazer"*) got=noop ;; *) got="$out" ;; esac
  assert_eq noop "$got" "reinstall $tgt e no-op"
  lines=$(wc -l <"$proj/.agents/lock" | tr -d ' ')
  assert_eq 1 "$lines" "lock inalterado apos reinstall em $tgt"

  cd "$ROOT"; rm -rf "$proj"
done

# deteccao automatica de alvo (sem --target), com um unico marcador
proj=$(mktemp -d); mkdir -p "$proj/.claude"; cd "$proj"
rc=0; out=$("$AGENTS" install example-agent 2>&1) || rc=$?
assert_exit 0 "$rc" "deteccao automatica instala"
assert_file_exists "$proj/.claude/agents/example-agent.md" "deteccao automatica escreve no alvo certo"
cd "$ROOT"; rm -rf "$proj"

assert_done
