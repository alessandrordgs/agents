#!/bin/sh
# Comando: remove

# Apaga apenas os arquivos do agente listados no lock; nunca toca em nada fora dele.
remove_agent_files() { # project_dir lockfile name
  proj=$1 lockfile=$2 name=$3
  lock_files "$lockfile" "$name" | while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    rm -f "$proj/$rel"
    rmdir "$(dirname "$proj/$rel")" 2>/dev/null || true
  done
}

cmd_remove() {
  name=${1:-}
  [ -n "$name" ] || { printf 'erro: informe o nome do agente\n' >&2; return 2; }
  proj=$PWD
  lockfile=$(lock_path "$proj")

  if ! lock_has "$lockfile" "$name"; then
    printf 'nada a remover (%s nao esta instalado)\n' "$name"
    return 0
  fi

  remove_agent_files "$proj" "$lockfile" "$name"
  lock_remove_agent "$lockfile" "$name"
  printf 'removido %s\n' "$name"
  return 0
}
