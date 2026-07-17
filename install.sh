#!/bin/sh
# Bootstrap estilo skills.sh: obtem/atualiza o repositorio de agents e coloca
# `agents` no PATH. Dependencias: sh e git.
set -eu

REPO_URL=${AGENTS_REPO:-https://github.com/alessandrordgs/agents.git}
DEST=${AGENTS_HOME:-$HOME/.agents}
BINDIR=${AGENTS_BINDIR:-$HOME/.local/bin}

if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only
else
  git clone "$REPO_URL" "$DEST"
fi

chmod +x "$DEST/bin/agents"
mkdir -p "$BINDIR"
ln -sf "$DEST/bin/agents" "$BINDIR/agents"

printf 'agents instalado em %s\n' "$BINDIR/agents"
case ":$PATH:" in
  *":$BINDIR:"*) : ;;
  *) printf 'adicione %s ao seu PATH para usar o comando "agents"\n' "$BINDIR" ;;
esac
