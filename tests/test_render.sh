#!/bin/sh
# T008/T011/T014: renderizacao por alvo (codex TOML, opencode md, claude passthrough).
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tests/assert.sh"
# shellcheck source=/dev/null
. "$ROOT/lib/render.sh"

src=$(mktemp)
cat >"$src" <<'EOF'
---
name: my-agent
description: Faz "coisas" e mais
model: sonnet
---

# Titulo

Linha 1
Linha 2
EOF

# claude: passthrough byte a byte
out=$(render_target claude "$src" my-agent)
assert_eq "$(cat "$src")" "$out" "claude passthrough identico a fonte"

# codex: name normalizado, TOML valido (escaping de aspas), corpo em developer_instructions
codex_out=$(render_target codex "$src" my-agent)
case "$codex_out" in *'name = "my_agent"'*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "codex normaliza o nome para identificador"
case "$codex_out" in *"# Titulo"*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "codex inclui o corpo em developer_instructions"
if command -v python3 >/dev/null 2>&1; then
  tf=$(mktemp); printf '%s\n' "$codex_out" >"$tf"
  if python3 -c 'import tomllib,sys; tomllib.load(open(sys.argv[1],"rb"))' "$tf" 2>/dev/null; then got=1; else got=0; fi
  assert_eq 1 "$got" "codex gera TOML valido (aspas escapadas)"
  rm -f "$tf"
fi

# opencode: frontmatter com description e mode subagent, corpo preservado, sem model/tools
oc_out=$(render_target opencode "$src" my-agent)
case "$oc_out" in *'mode: subagent'*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "opencode define mode subagent"
case "$oc_out" in *"# Titulo"*) got=1 ;; *) got=0 ;; esac
assert_eq 1 "$got" "opencode preserva o corpo"
case "$oc_out" in *"model:"*) got=1 ;; *) got=0 ;; esac
assert_eq 0 "$got" "opencode nao propaga modelo na v1"

rm -f "$src"
assert_done
