#!/bin/sh
# Planejamento de escrita e deteccao de conflito.
# Depende de manifest.sh, targets.sh e lock.sh (carregados pelo entrypoint).

# Ecoa linhas "src<TAB>destrel" (uma por arquivo). Nao escreve nada.
plan_lines() { # catalog name target dest
  catalog=$1 name=$2 target=$3 dest=$4
  dest=${dest%/}
  mf=$(manifest_path "$catalog" "$name")
  manifest_target_files "$mf" "$target" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    base=$(basename "$f")
    printf '%s/agents/%s/%s\t%s/%s\n' "$catalog" "$name" "$f" "$dest" "$base"
  done
}

# Verifica conflitos: destino existente que nao pertence ao agente no lock.
# Retorna 0 se seguro; 1 e imprime o conflito se houver colisao.
plan_check_conflicts() { # project_dir lockfile name plan(stdin)
  proj=$1 lockfile=$2 name=$3 conflict=0
  while IFS='	' read -r _ destrel; do
    [ -n "$destrel" ] || continue
    destabs="$proj/$destrel"
    if [ -e "$destabs" ] && ! lock_belongs "$lockfile" "$name" "$destrel"; then
      printf 'erro: conflito, o arquivo "%s" ja existe e nao pertence ao agente "%s"\n' "$destrel" "$name" >&2
      conflict=1
    fi
  done
  return "$conflict"
}
