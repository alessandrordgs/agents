#!/bin/sh
# Seletor interativo de setas em POSIX sh puro (sem dependencia).
# UI vai para /dev/tty; o resultado (nomes escolhidos) vai para stdout.
# ponytail: assume catalogo menor que a altura do terminal; listas muito longas
# quebrariam o calculo de redesenho (subir N linhas). Upgrade: paginacao, se preciso.

# Carrega o catalogo em variaveis _ag_N e _ag_name_i / _ag_ver_i / _ag_desc_i.
tui_load_catalog() {
  _ag_N=0
  _ag_w=0
  for mf in "$AGENTS_HOME"/agents/*/manifest; do
    [ -f "$mf" ] || continue
    if manifest_hidden "$mf"; then continue; fi
    _ag_N=$((_ag_N + 1))
    eval "_ag_name_$_ag_N=\$(basename \"\$(dirname \"\$mf\")\")"
    eval "_ag_ver_$_ag_N=\$(manifest_field \"\$mf\" version)"
    eval "_ag_desc_$_ag_N=\$(manifest_field \"\$mf\" description)"
    eval "nm=\$_ag_name_$_ag_N"
    [ "${#nm}" -le "$_ag_w" ] || _ag_w=${#nm}
  done
}

# Largura do terminal. stty ja e dependencia do seletor, tput nao e.
tui_cols() {
  # shellcheck disable=SC2046  # split intencional de "linhas colunas"
  set -- $(stty size </dev/tty 2>/dev/null)
  _c=${2:-}
  case "$_c" in '' | *[!0-9]*) _c=${COLUMNS:-80} ;; esac
  case "$_c" in '' | *[!0-9]*) _c=80 ;; esac
  [ "$_c" -ge 40 ] || _c=80
  printf '%s' "$_c"
}

# Corta no orcamento e marca o corte com reticencias, recuando ate o ultimo espaco
# para nunca partir um caractere multibyte ao meio.
# ponytail: orcamento em bytes no dash e em caracteres no bash; com acento a linha so
# fica mais curta que o disponivel, nunca estoura. Upgrade: contar colunas de verdade.
tui_trunc() { # texto largura
  _t=$1
  _m=$(( $2 - 1 ))
  [ "$_m" -ge 1 ] || _m=1
  [ "${#_t}" -gt "$_m" ] || { printf '%s' "$_t"; return; }
  _x=ç
  while [ "${#_t}" -gt "$_m" ]; do
    case "$_t" in
      *' '*) _t=${_t% *} ;;
      *)
        _t=${_t%?}
        # Sem espaco para recuar: no shell que corta byte (dash), o corte pode cair
        # dentro de um caractere; descarta o resto dele ate sobrar um byte ASCII.
        while [ "${#_x}" -ne 1 ] && [ -n "$_t" ]; do
          case "$_t" in *[!\ -~]) _t=${_t%?} ;; *) break ;; esac
        done
        ;;
    esac
  done
  printf '%s…' "$_t"
}

# Completa com espacos a direita ate a largura (nomes sao slugs ASCII, byte = coluna).
tui_pad() { # texto largura
  _p=$1
  while [ "${#_p}" -lt "$2" ]; do _p="$_p "; done
  printf '%s' "$_p"
}

tui_colors() {
  if [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != dumb ]; then
    T_RESET=$(printf '\033[0m'); T_BOLD=$(printf '\033[1m'); T_DIM=$(printf '\033[2m')
    T_CYAN=$(printf '\033[36m'); T_GREEN=$(printf '\033[32m')
    T_BG=$(printf '\033[48;5;237m')
    T_FGD=$(printf '\033[39m'); T_NORM=$(printf '\033[22m')
  else
    T_RESET='' T_BOLD='' T_DIM='' T_CYAN='' T_GREEN=''
    T_BG='' T_FGD='' T_NORM=''
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
  _ag_dw=$(( $(tui_cols) - _ag_w - 8 ))
  [ "$_ag_dw" -ge 12 ] || _ag_dw=12
  i=1 nm='' ds=''
  while [ "$i" -le "$_ag_N" ]; do
    eval "nm=\$_ag_name_$i"
    eval "ds=\$_ag_desc_$i"
    case "$_ag_sel" in
      *" $i "*) mark="$T_GREEN●" ;;
      *) mark="$T_DIM○" ;;
    esac
    if [ "$i" -eq "$_ag_cur" ]; then
      # ponytail: fundo ate o fim da linha via \033[K com bg ativo (BCE), em vez de
      # padding manual; padding que erre a largura quebra a linha e estraga o redesenho.
      printf '\r%s %s›%s%s %s%s%s %s%s%s  %s%s\033[K%s\n' \
        "$T_BG" "$T_CYAN" "$T_FGD" "$T_NORM" "$mark" "$T_FGD" "$T_NORM" \
        "$T_BOLD" "$(tui_pad "$nm" "$_ag_w")" "$T_NORM" "$T_DIM" "$(tui_trunc "$ds" "$_ag_dw")" "$T_RESET" >/dev/tty
    else
      printf '\r\033[K   %s%s %s  %s%s%s\n' \
        "$mark" "$T_RESET" "$(tui_pad "$nm" "$_ag_w")" "$T_DIM" "$(tui_trunc "$ds" "$_ag_dw")" "$T_RESET" >/dev/tty
    fi
    i=$((i + 1))
  done
  cnt=$(printf '%s' "$_ag_sel" | wc -w | tr -d ' ')
  printf '\r\033[K %s%s de %s marcados%s\n' "$T_DIM" "$cnt" "$_ag_N" "$T_RESET" >/dev/tty
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

  printf '%sEscolha os agentes%s  %s↑↓ navega · espaço marca · a marca todos · enter confirma · q cancela%s\n' \
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
