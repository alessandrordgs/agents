#!/bin/sh
# Bootstrap estilo skills.sh: obtem/atualiza o repositorio de agents e coloca
# `agents` no PATH. Dependencias: sh e git.
set -eu

INSTALLER_URL="https://raw.githubusercontent.com/alessandrordgs/agents/main/install.sh"
REPO_URL=${AGENTS_REPO:-https://github.com/alessandrordgs/agents.git}
DEST=${AGENTS_HOME:-$HOME/.local/share/agents}
BINDIR=${AGENTS_BINDIR:-$HOME/.local/bin}

if ! command -v git >/dev/null 2>&1; then
  printf 'erro: git nao encontrado. Instale o git e rode de novo.\n' >&2
  exit 1
fi

if [ -d "$DEST/.git" ]; then
  printf 'Atualizando agents em %s ...\n' "$DEST"
  if ! git -C "$DEST" pull --ff-only >/dev/null 2>&1; then
    printf 'erro: nao consegui atualizar %s (git pull falhou).\n' "$DEST" >&2
    printf 'Para reinstalar limpo:\n' >&2
    printf '  rm -rf %s && curl -fsSL %s | sh\n' "$DEST" "$INSTALLER_URL" >&2
    exit 1
  fi
elif [ -e "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  printf 'erro: "%s" ja existe e nao e uma instalacao do agents.\n' "$DEST" >&2
  printf '\nEscolha uma opcao:\n' >&2
  printf '  1) Reinstalar limpo (apaga %s):\n' "$DEST" >&2
  printf '       rm -rf %s && curl -fsSL %s | sh\n' "$DEST" "$INSTALLER_URL" >&2
  printf '  2) Instalar em outro lugar (defina AGENTS_HOME):\n' >&2
  # shellcheck disable=SC2016
  printf '       AGENTS_HOME="$HOME/.agents-cli" sh -c "curl -fsSL %s | sh"\n' "$INSTALLER_URL" >&2
  printf '\nNada foi alterado.\n' >&2
  exit 1
else
  printf 'Instalando agents em %s ...\n' "$DEST"
  git clone --quiet "$REPO_URL" "$DEST"
fi

chmod +x "$DEST/bin/agents"
mkdir -p "$BINDIR"
ln -sf "$DEST/bin/agents" "$BINDIR/agents"

printf '\nagents instalado: %s\n' "$BINDIR/agents"
case ":$PATH:" in
  *":$BINDIR:"*)
    printf 'Pronto. Rode: agents list\n'
    ;;
  *)
    printf 'Falta so por %s no PATH. Adicione ao seu ~/.bashrc ou ~/.zshrc:\n' "$BINDIR" >&2
    # shellcheck disable=SC2016
    printf '  export PATH="%s:$PATH"\n' "$BINDIR" >&2
    ;;
esac
