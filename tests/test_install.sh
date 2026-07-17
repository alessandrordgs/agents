#!/bin/sh
# T010: instalacao (por renderizacao) nos tres alvos + idempotencia (SC-002, SC-003, SC-006).
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
AGENTS="$ROOT/bin/agents"

# target|marker|destfile
for spec in \
  "claude|.claude|.claude/agents/example-agent.md" \
  "codex|.codex|.codex/agents/example-agent.toml" \
  "opencode|.opencode|.opencode/agent/example-agent.md"; do
  tgt=${spec%%|*}; rest=${spec#*|}; marker=${rest%%|*}; destfile=${rest#*|}
  proj=$(mktemp -d)
  mkdir -p "$proj/$marker"
  cd "$proj"

  rc=0; "$AGENTS" install example-agent --target "$tgt" >/dev/null 2>&1 || rc=$?
  assert_exit 0 "$rc" "install $tgt sai 0"
  assert_file_exists "$proj/$destfile" "artefato instalado em $tgt"
  assert_file_exists "$proj/.agents/lock" "lock criado em $tgt"
  lines=$(wc -l <"$proj/.agents/lock" | tr -d ' ')
  assert_eq 1 "$lines" "uma linha no lock em $tgt"

  rc=0; out=$("$AGENTS" install example-agent --target "$tgt" 2>&1) || rc=$?
  assert_exit 0 "$rc" "reinstall $tgt sai 0"
  case "$out" in *"nada a fazer"*) got=noop ;; *) got="$out" ;; esac
  assert_eq noop "$got" "reinstall $tgt e no-op"

  cd "$ROOT"; rm -rf "$proj"
done

# deteccao automatica de alvo (sem --target)
proj=$(mktemp -d); mkdir -p "$proj/.codex"; cd "$proj"
rc=0; "$AGENTS" install example-agent >/dev/null 2>&1 || rc=$?
assert_exit 0 "$rc" "deteccao automatica instala"
assert_file_exists "$proj/.codex/agents/example-agent.toml" "deteccao automatica escreve no alvo certo"
cd "$ROOT"; rm -rf "$proj"

assert_done
