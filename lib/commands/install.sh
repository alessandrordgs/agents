#!/bin/sh
# Comando: install

# Aplica a instalacao de um agente (ja validado) em um alvo declarado.
# Idempotente. Imprime resultado. Retorna 0 (sucesso/no-op) ou 3 (conflito).
install_agent() { # name target
  name=$1 target=$2
  proj=$PWD
  lockfile=$(lock_path "$proj")
  mf=$(manifest_path "$AGENTS_HOME" "$name")
  version=$(manifest_field "$mf" version)
  dest=$(manifest_target_dest "$mf" "$target")
  [ -n "$dest" ] || dest=$(targets_default_dest "$CONF" "$target")

  tmp="${TMPDIR:-/tmp}/agents.plan.$$"
  plan_lines "$AGENTS_HOME" "$name" "$target" "$dest" >"$tmp"

  if ! plan_check_conflicts "$proj" "$lockfile" "$name" <"$tmp"; then
    rm -f "$tmp"
    return 3
  fi

  changed=0
  while IFS='	' read -r src destrel; do
    [ -n "$destrel" ] || continue
    destabs="$proj/$destrel"
    d=$(dirname "$destabs")
    [ -d "$d" ] || mkdir -p "$d"
    if [ ! -e "$destabs" ]; then
      cp "$src" "$destabs"
      changed=1
    elif ! cmp -s "$src" "$destabs"; then
      cp "$src" "$destabs"
      changed=1
    fi
    if ! lock_belongs "$lockfile" "$name" "$destrel"; then
      lock_add "$lockfile" "$name" "$version" "$target" "$destrel"
      changed=1
    fi
  done <"$tmp"
  rm -f "$tmp"

  if [ "$changed" -eq 1 ]; then
    printf 'instalado %s@%s em %s\n' "$name" "$version" "$target"
  else
    printf 'nada a fazer (%s@%s ja instalado em %s)\n' "$name" "$version" "$target"
  fi
  return 0
}

# Menu interativo: lista o catalogo (em stderr) e le a selecao (stdin).
# Ecoa em stdout os nomes escolhidos. Retorna 1 se catalogo vazio ou nada escolhido.
pick_agents() {
  i=0
  names=''
  for mf in "$AGENTS_HOME"/agents/*/manifest; do
    [ -f "$mf" ] || continue
    i=$((i + 1))
    name=$(basename "$(dirname "$mf")")
    version=$(manifest_field "$mf" version)
    desc=$(manifest_field "$mf" description)
    names="$names $name"
    printf '%3d) %-20s %-8s %s\n' "$i" "$name" "$version" "$desc" >&2
  done
  if [ "$i" -eq 0 ]; then
    printf 'catalogo vazio\n' >&2
    return 1
  fi
  printf 'Selecione os agentes (ex: 1,3  ou  all): ' >&2
  IFS= read -r sel || return 1

  # shellcheck disable=SC2086
  set -- $names
  case "$sel" in
    all | a | All | ALL)
      printf '%s\n' "$names"
      return 0
      ;;
  esac

  chosen=''
  sel=$(printf '%s' "$sel" | tr ',' ' ')
  for tok in $sel; do
    case "$tok" in
      '' | *[!0-9]*) printf 'ignorado: "%s"\n' "$tok" >&2; continue ;;
    esac
    eval "n=\${$tok:-}"
    if [ -n "$n" ]; then
      chosen="$chosen $n"
    else
      printf 'fora do intervalo: %s\n' "$tok" >&2
    fi
  done
  if [ -z "${chosen# }" ]; then
    printf 'nada selecionado\n' >&2
    return 1
  fi
  printf '%s\n' "$chosen"
}

cmd_install() {
  target='' names=''
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --target)
        target=${2:-}
        [ -n "$target" ] || { printf 'erro: --target requer um valor\n' >&2; return 2; }
        shift 2
        ;;
      --target=*) target=${1#--target=}; shift ;;
      -*) printf 'erro: opcao desconhecida "%s"\n' "$1" >&2; return 2 ;;
      *) names="$names $1"; shift ;;
    esac
  done

  # Sem nome: modo interativo (seleciona do catalogo).
  if [ -z "${names# }" ]; then
    names=$(pick_agents) || return 2
  fi

  # Resolve o alvo uma vez para toda a selecao.
  if [ -z "$target" ]; then
    target=$(targets_detect "$CONF" "$PWD") || return 5
  fi
  if ! targets_known "$CONF" "$target"; then
    printf 'erro: alvo "%s" desconhecido\n' "$target" >&2
    return 5
  fi

  rc_all=0
  for name in $names; do
    if ! manifest_validate "$AGENTS_HOME" "$name" "$CONF"; then
      rc_all=4
      continue
    fi
    mf=$(manifest_path "$AGENTS_HOME" "$name")
    if ! manifest_supports "$mf" "$target"; then
      printf 'erro: o agente "%s" nao declara suporte ao alvo "%s"\n' "$name" "$target" >&2
      rc_all=4
      continue
    fi
    install_agent "$name" "$target" || rc_all=$?
  done
  return "$rc_all"
}
