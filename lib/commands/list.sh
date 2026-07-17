#!/bin/sh
# Comando: list

cmd_list() {
  only_installed=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --installed) only_installed=1; shift ;;
      *) printf 'erro: opcao desconhecida "%s"\n' "$1" >&2; return 2 ;;
    esac
  done

  proj=$PWD
  lockfile=$(lock_path "$proj")
  found=0

  for mf in "$AGENTS_HOME"/agents/*/manifest; do
    [ -f "$mf" ] || continue
    name=$(basename "$(dirname "$mf")")
    installed=no
    if lock_has "$lockfile" "$name"; then installed=yes; fi
    if [ "$only_installed" -eq 1 ] && [ "$installed" = no ]; then continue; fi
    version=$(manifest_field "$mf" version)
    desc=$(manifest_field "$mf" description)
    tgts=$(manifest_targets "$mf" | paste -sd, -)
    mark=" "
    if [ "$installed" = yes ]; then mark="*"; fi
    printf '%s %-20s %-8s [%s] %s\n' "$mark" "$name" "$version" "$tgts" "$desc"
    found=1
  done

  if [ "$found" -eq 0 ]; then
    if [ "$only_installed" -eq 1 ]; then
      printf '(nenhum agente instalado)\n'
    else
      printf '(catalogo vazio)\n'
    fi
  fi
  return 0
}
