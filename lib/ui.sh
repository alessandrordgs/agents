#!/bin/sh
# Cores, status e spinner. Degrada para texto puro quando stdout nao e um terminal
# (pipe, CI, testes) ou quando NO_COLOR/TERM=dumb.
# shellcheck disable=SC2034  # varias C_* sao usadas pelos scripts que fazem source

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != dumb ]; then
  _UI_TTY=1
  C_RESET=$(printf '\033[0m'); C_BOLD=$(printf '\033[1m'); C_DIM=$(printf '\033[2m')
  C_RED=$(printf '\033[31m'); C_GREEN=$(printf '\033[32m'); C_YELLOW=$(printf '\033[33m')
  C_CYAN=$(printf '\033[36m'); C_GRAY=$(printf '\033[90m')
else
  _UI_TTY=0
  C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_CYAN='' C_GRAY=''
fi

ui_ok()   { if [ "$_UI_TTY" = 1 ]; then printf '%s●%s %s\n' "$C_GREEN" "$C_RESET" "$1"; else printf '%s\n' "$1"; fi; }
ui_info() { if [ "$_UI_TTY" = 1 ]; then printf '%s●%s %s\n' "$C_CYAN" "$C_RESET" "$1"; else printf '%s\n' "$1"; fi; }
ui_warn() { if [ "$_UI_TTY" = 1 ]; then printf '%s●%s %s\n' "$C_YELLOW" "$C_RESET" "$1"; else printf '%s\n' "$1"; fi; }
ui_skip() { if [ "$_UI_TTY" = 1 ]; then printf '%s○%s %s%s%s\n' "$C_GRAY" "$C_RESET" "$C_DIM" "$1" "$C_RESET"; else printf '%s\n' "$1"; fi; }
ui_err()  { if [ "$_UI_TTY" = 1 ]; then printf '%s●%s %s\n' "$C_RED" "$C_RESET" "$1" >&2; else printf 'erro: %s\n' "$1" >&2; fi; }

# Quadro de um spinner pelo indice (frames em variaveis para nao depender de cut -c multibyte).
spin_frame() { # index
  n=$(( $1 % 10 + 1 ))
  set -- ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
  eval "printf '%s' \"\${$n}\""
}

# spinner_run <mensagem> <cmd...>: roda o comando mostrando um spinner (so em terminal).
# Retorna o codigo de saida do comando.
spinner_run() {
  msg=$1; shift
  if [ ! -t 2 ]; then "$@"; return $?; fi
  "$@" &
  _sp=$!
  printf '\033[?25l' >&2
  i=0
  while kill -0 "$_sp" 2>/dev/null; do
    printf '\r%s%s%s %s ' "$C_CYAN" "$(spin_frame "$i")" "$C_RESET" "$msg" >&2
    i=$((i + 1))
    sleep 0.1 2>/dev/null || sleep 1
  done
  _rc=0; wait "$_sp" || _rc=$?
  printf '\r\033[K\033[?25h' >&2
  return "$_rc"
}
