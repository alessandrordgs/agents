#!/bin/sh
# Auto atualizacao da CLI (git pull no AGENTS_HOME).

# Atualiza o proprio agents. Retorna 0 em sucesso/no-op, 1 em erro.
self_update() {
  if [ ! -d "$AGENTS_HOME/.git" ]; then
    printf 'erro: %s nao e um repositorio git; reinstale via install.sh\n' "$AGENTS_HOME" >&2
    return 1
  fi
  printf 'Atualizando agents em %s ...\n' "$AGENTS_HOME"
  if git -C "$AGENTS_HOME" pull --ff-only; then
    printf 'agents atualizado.\n'
    return 0
  fi
  printf 'erro: falha ao atualizar (git pull).\n' >&2
  return 1
}

# Check de startup: se houver atualizacao, pergunta uma vez ao usuario.
# Silencioso e nao bloqueante: so age em terminal, no maximo 1x/dia, e nunca
# interrompe o comando por falta de rede.
self_update_check() {
  [ -d "$AGENTS_HOME/.git" ] || return 0

  stamp="$AGENTS_HOME/.last_update_check"
  now=$(date +%s 2>/dev/null || printf '0')
  if [ -f "$stamp" ]; then
    last=$(cat "$stamp" 2>/dev/null || printf '0')
    [ $((now - last)) -lt 86400 ] && return 0
  fi

  if ! git -C "$AGENTS_HOME" fetch --quiet 2>/dev/null; then
    printf '%s\n' "$now" >"$stamp" 2>/dev/null || true
    return 0
  fi
  printf '%s\n' "$now" >"$stamp" 2>/dev/null || true

  behind=$(git -C "$AGENTS_HOME" rev-list --count 'HEAD..@{u}' 2>/dev/null || printf '0')
  [ "$behind" -gt 0 ] 2>/dev/null || return 0

  printf 'Quer atualizar o agents? (%s versao(oes) atras) [y/N] ' "$behind" >/dev/tty 2>/dev/null || return 0
  IFS= read -r ans </dev/tty 2>/dev/null || return 0
  case "$ans" in
    y | Y | s | S) self_update ;;
    *) : ;;
  esac
}
