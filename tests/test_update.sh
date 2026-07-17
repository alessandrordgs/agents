#!/bin/sh
# T018 (feature 001) + renderizacao: atualizacao de versao, no-op e nao instalado.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
AGENTS="$ROOT/bin/agents"

cat=$(mktemp -d)
cp "$ROOT/targets.conf" "$cat/targets.conf"
mkdir -p "$cat/lib" "$cat/agents/upd"
cp -r "$ROOT/lib/." "$cat/lib/"
write_source() { # marker-de-versao
  printf -- '---\nname: upd\ndescription: teste update\n---\n%s\n' "$1" >"$cat/agents/upd/agent.md"
}
write_manifest() { # version
  cat >"$cat/agents/upd/manifest" <<EOF
name: upd
version: $1
description: agente para teste de update
source: agent.md
targets: claude
EOF
}
write_source v1
write_manifest 1.0.0

proj=$(mktemp -d); mkdir -p "$proj/.claude/agents"; cd "$proj"
AGENTS_HOME="$cat" "$AGENTS" install upd --target claude >/dev/null
printf 'ARQUIVO ALHEIO\n' >"$proj/.claude/agents/keep.md"

# bump para 2.0.0 com novo corpo
write_source v2
write_manifest 2.0.0

rc=0; out=$(AGENTS_HOME="$cat" "$AGENTS" update upd 2>&1) || rc=$?
assert_exit 0 "$rc" "update sai 0"
case "$out" in *"1.0.0 -> 2.0.0"*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "update reporta troca de versao"
if grep -q '^v2$' "$proj/.claude/agents/upd.md"; then got=1; else got=0; fi
assert_eq 1 "$got" "artefato atualizado para v2"
assert_eq 2.0.0 "$(awk -F'\t' '$1=="upd"{print $2}' "$proj/.agents/lock")" "lock atualizado para 2.0.0"
assert_eq "ARQUIVO ALHEIO" "$(cat "$proj/.claude/agents/keep.md")" "arquivo alheio intacto"

# update de novo: no-op
rc=0; out=$(AGENTS_HOME="$cat" "$AGENTS" update upd 2>&1) || rc=$?
assert_exit 0 "$rc" "update no-op sai 0"
case "$out" in *"nada a fazer"*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "update ja na versao mais nova e no-op"

# update de agente nao instalado
proj2=$(mktemp -d); mkdir -p "$proj2/.claude"; cd "$proj2"
rc=0; AGENTS_HOME="$cat" "$AGENTS" update upd >/dev/null 2>&1 || rc=$?
assert_exit 4 "$rc" "update de nao instalado retorna 4"

cd "$ROOT"; rm -rf "$proj" "$proj2" "$cat"
assert_done
