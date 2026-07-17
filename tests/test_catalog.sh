#!/bin/sh
# T015: catalogo de fonte unica e instalacao nos tres alvos declarados.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
AGENTS="$ROOT/bin/agents"

# Cada agente do catalogo tem exatamente agent.md + manifest, sem diretorios por alvo
for d in "$ROOT"/agents/*/; do
  name=$(basename "$d")
  assert_file_exists "$d/agent.md" "$name tem fonte canonica agent.md"
  assert_file_exists "$d/manifest" "$name tem manifest"
  for legacy in claude codex opencode; do
    if [ -d "$d/$legacy" ]; then got=presente; else got=ausente; fi
    assert_eq ausente "$got" "$name sem diretorio por alvo ($legacy)"
  done
done

# example-agent declara os tres alvos e instala nos tres a partir da fonte unica
for tgt in claude codex opencode; do
  proj=$(mktemp -d); mkdir -p "$proj/.$tgt"; cd "$proj"
  rc=0; "$AGENTS" install example-agent --target "$tgt" >/dev/null 2>&1 || rc=$?
  assert_exit 0 "$rc" "example-agent instala em $tgt a partir da fonte unica"
  cd "$ROOT"; rm -rf "$proj"
done

assert_done
