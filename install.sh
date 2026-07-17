#!/bin/sh
# Bootstrap estilo skills.sh: obtem/atualiza o repositorio de agents e coloca
# `agents` no PATH. Dependencias: sh e git.
set -eu

INSTALLER_URL="https://raw.githubusercontent.com/alessandrordgs/agents/main/install.sh"
REPO_URL=${AGENTS_REPO:-https://github.com/alessandrordgs/agents.git}
DEST=${AGENTS_HOME:-$HOME/.local/share/agents}
BINDIR=${AGENTS_BINDIR:-$HOME/.local/bin}

if [ -t 2 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != dumb ]; then
  G=$(printf '\033[32m'); R=$(printf '\033[31m'); B=$(printf '\033[1m'); Z=$(printf '\033[0m')
else
  G='' R='' B='' Z=''
fi

# Roda um comando mostrando um spinner (so em terminal). Retorna o codigo do comando.
spin() { # mensagem cmd...
  m=$1; shift
  if [ ! -t 2 ]; then "$@"; return $?; fi
  "$@" & p=$!
  printf '\033[?25l' >&2
  i=0 f=''
  while kill -0 "$p" 2>/dev/null; do
    n=$((i % 10 + 1))
    set -- ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
    eval "f=\${$n}"
    printf '\r%s%s%s %s ' "$G" "$f" "$Z" "$m" >&2
    i=$((i + 1)); sleep 0.1 2>/dev/null || sleep 1
  done
  r=0; wait "$p" || r=$?
  printf '\r\033[K\033[?25h' >&2
  return "$r"
}

if ! command -v git >/dev/null 2>&1; then
  printf '%s●%s git nao encontrado. Instale o git e rode de novo.\n' "$R" "$Z" >&2
  exit 1
fi

if [ -d "$DEST/.git" ]; then
  if ! spin "Atualizando agents em $DEST" git -C "$DEST" pull --ff-only --quiet; then
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
  spin "Baixando agents para $DEST" git clone --quiet "$REPO_URL" "$DEST"
fi

chmod +x "$DEST/bin/agents"
mkdir -p "$BINDIR"
ln -sf "$DEST/bin/agents" "$BINDIR/agents"

printf '\n%s●%s agents instalado: %s%s%s\n' "$G" "$Z" "$B" "$BINDIR/agents" "$Z"
case ":$PATH:" in
  *":$BINDIR:"*)
    printf 'Pronto. Rode: %sagents list%s\n' "$B" "$Z"
    ;;
  *)
    printf 'Falta so por %s no PATH. Adicione ao seu ~/.bashrc ou ~/.zshrc:\n' "$BINDIR" >&2
    # shellcheck disable=SC2016
    printf '  export PATH="%s:$PATH"\n' "$BINDIR" >&2
    ;;
esac
