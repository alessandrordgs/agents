#!/bin/sh
# Deteccao de conflito para um artefato. Depende de lock.sh.

# Retorna 0 se seguro escrever destrel; 1 e imprime o conflito se o destino ja
# existe e nao pertence ao agente no lock.
plan_conflict() { # project_dir lockfile name destrel
  proj=$1 lockfile=$2 name=$3 destrel=$4
  destabs="$proj/$destrel"
  if [ -e "$destabs" ] && ! lock_belongs "$lockfile" "$name" "$destrel"; then
    printf 'erro: conflito, o arquivo "%s" ja existe e nao pertence ao agente "%s"\n' "$destrel" "$name" >&2
    return 1
  fi
  return 0
}
