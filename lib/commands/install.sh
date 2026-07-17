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

cmd_install() {
  name='' target=''
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --target)
        target=${2:-}
        [ -n "$target" ] || { printf 'erro: --target requer um valor\n' >&2; return 2; }
        shift 2
        ;;
      --target=*) target=${1#--target=}; shift ;;
      -*) printf 'erro: opcao desconhecida "%s"\n' "$1" >&2; return 2 ;;
      *) [ -n "$name" ] || name=$1; shift ;;
    esac
  done
  [ -n "$name" ] || { printf 'erro: informe o nome do agente\n' >&2; return 2; }

  manifest_validate "$AGENTS_HOME" "$name" "$CONF" || return 4

  if [ -z "$target" ]; then
    target=$(targets_detect "$CONF" "$PWD") || return 5
  fi
  if ! targets_known "$CONF" "$target"; then
    printf 'erro: alvo "%s" desconhecido\n' "$target" >&2
    return 5
  fi
  mf=$(manifest_path "$AGENTS_HOME" "$name")
  if ! manifest_supports "$mf" "$target"; then
    printf 'erro: o agente "%s" nao declara suporte ao alvo "%s"\n' "$name" "$target" >&2
    return 4
  fi

  install_agent "$name" "$target" || return $?
}
