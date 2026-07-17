#!/bin/sh
# Seletor interativo de setas em POSIX sh puro (sem dependencia).
# UI vai para /dev/tty; o resultado (nomes escolhidos) vai para stdout.
# ponytail: assume catalogo menor que a altura do terminal; listas muito longas
# quebrariam o calculo de redesenho (subir N linhas). Upgrade: paginacao, se preciso.

# Carrega o catalogo em variaveis _ag_N e _ag_name_i / _ag_ver_i / _ag_desc_i.
tui_load_catalog() {
  _ag_N=0
  for mf in "$AGENTS_HOME"/agents/*/manifest; do
    [ -f "$mf" ] || continue
    _ag_N=$((_ag_N + 1))
    eval "_ag_name_$_ag_N=\$(basename \"\$(dirname \"\$mf\")\")"
    eval "_ag_ver_$_ag_N=\$(manifest_field \"\$mf\" version)"
    eval "_ag_desc_$_ag_N=\$(manifest_field \"\$mf\" description)"
  done
}

tui_trunc() { printf '%.44s' "$1"; }

tui_colors() {
  if [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != dumb ]; then
    T_RESET=$(printf '\033[0m'); T_BOLD=$(printf '\033[1m'); T_DIM=$(printf '\033[2m')
    T_CYAN=$(printf '\033[36m'); T_GREEN=$(printf '\033[32m')
  else
    T_RESET='' T_BOLD='' T_DIM='' T_CYAN='' T_GREEN=''
  fi
}

# Le uma tecla de /dev/tty e ecoa um token: UP DOWN SPACE ENTER ALL QUIT OTHER.
tui_read_key() {
  c=$(dd if=/dev/tty bs=1 count=1 2>/dev/null)
  if [ -z "$c" ]; then printf 'ENTER'; return; fi
  case "$c" in
    ' ') printf 'SPACE'; return ;;
    q | Q) printf 'QUIT'; return ;;
    a | A) printf 'ALL'; return ;;
    j | J) printf 'DOWN'; return ;;
    k | K) printf 'UP'; return ;;
  esac
  code=$(printf '%d' "'$c" 2>/dev/null || printf '0')
  if [ "$code" -eq 27 ]; then
    n1=$(dd if=/dev/tty bs=1 count=1 2>/dev/null)
    if [ "$n1" = "[" ] || [ "$n1" = "O" ]; then
      n2=$(dd if=/dev/tty bs=1 count=1 2>/dev/null)
      case "$n2" in A) printf 'UP' ;; B) printf 'DOWN' ;; *) printf 'OTHER' ;; esac
      return
    fi
    printf 'QUIT'
    return
  fi
  printf 'OTHER'
}

tui_render() { # first?
  if [ "$1" -ne 1 ]; then
    printf '\033[%dA' "$((_ag_N + 1))" >/dev/tty
  fi
  i=1 nm='' ds=''
  while [ "$i" -le "$_ag_N" ]; do
    eval "nm=\$_ag_name_$i"
    eval "ds=\$_ag_desc_$i"
    case "$_ag_sel" in
      *" $i "*) box="$T_GREEN●$T_RESET" ;;
      *) box="$T_DIM○$T_RESET" ;;
    esac
    if [ "$i" -eq "$_ag_cur" ]; then
      printf '\r\033[K %s›%s %s %s%-22s%s %s%s%s\n' \
        "$T_CYAN" "$T_RESET" "$box" "$T_BOLD" "$nm" "$T_RESET" "$T_DIM" "$(tui_trunc "$ds")" "$T_RESET" >/dev/tty
    else
      printf '\r\033[K   %s %-22s %s%s%s\n' \
        "$box" "$nm" "$T_DIM" "$(tui_trunc "$ds")" "$T_RESET" >/dev/tty
    fi
    i=$((i + 1))
  done
  cnt=$(printf '%s' "$_ag_sel" | wc -w | tr -d ' ')
  printf '\r\033[K %s%s marcado(s)%s\n' "$T_DIM" "$cnt" "$T_RESET" >/dev/tty
}

tui_toggle() { # selected cur  -> nova string
  case "$1" in
    *" $2 "*) printf '%s' "$1" | sed "s/ $2 / /" ;;
    *) printf '%s %s ' "$1" "$2" ;;
  esac
}

# Seletor. Ecoa os nomes escolhidos (separados por espaco). Retorna 1 se cancelado/vazio.
tui_pick() {
  tui_load_catalog
  if [ "$_ag_N" -eq 0 ]; then
    printf 'catalogo vazio\n' >&2
    return 1
  fi
  tui_colors

  _ag_stty=$(stty -g </dev/tty)
  # shellcheck disable=SC2064
  trap "stty $_ag_stty </dev/tty 2>/dev/null; printf '\033[?25h' >/dev/tty 2>/dev/null" INT TERM
  stty -echo -icanon min 1 time 0 </dev/tty
  printf '\033[?25l' >/dev/tty

  printf '%sEscolha os agentes%s  %ssetas marca com espaco · a todos · enter confirma · q cancela%s\n' \
    "$T_BOLD" "$T_RESET" "$T_DIM" "$T_RESET" >/dev/tty

  _ag_cur=1 _ag_sel=' '
  tui_render 1
  cancel=0
  while :; do
    key=$(tui_read_key)
    case "$key" in
      UP) _ag_cur=$(( _ag_cur > 1 ? _ag_cur - 1 : _ag_N )) ;;
      DOWN) _ag_cur=$(( _ag_cur < _ag_N ? _ag_cur + 1 : 1 )) ;;
      SPACE) _ag_sel=$(tui_toggle "$_ag_sel" "$_ag_cur") ;;
      ALL)
        if [ "$(printf '%s' "$_ag_sel" | wc -w)" -eq "$_ag_N" ]; then
          _ag_sel=' '
        else
          _ag_sel=' '; i=1
          while [ "$i" -le "$_ag_N" ]; do _ag_sel="$_ag_sel$i "; i=$((i + 1)); done
        fi
        ;;
      ENTER) break ;;
      QUIT) cancel=1; break ;;
      *) : ;;
    esac
    tui_render 0
  done

  stty "$_ag_stty" </dev/tty 2>/dev/null || true
  printf '\033[?25h' >/dev/tty
  trap - INT TERM
  printf '\n' >/dev/tty

  [ "$cancel" -eq 0 ] || return 1

  out='' i=1 nm=''
  while [ "$i" -le "$_ag_N" ]; do
    case "$_ag_sel" in
      *" $i "*) eval "nm=\$_ag_name_$i"; out="$out $nm" ;;
    esac
    i=$((i + 1))
  done
  if [ -z "${out# }" ]; then
    printf 'nada selecionado\n' >&2
    return 1
  fi
  printf '%s\n' "$out"
}
