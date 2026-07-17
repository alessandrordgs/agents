#!/bin/sh
# Comando: update

cmd_update() {
  name=${1:-}
  [ -n "$name" ] || { printf 'erro: informe o nome do agente\n' >&2; return 2; }
  proj=$PWD
  lockfile=$(lock_path "$proj")

  if ! lock_has "$lockfile" "$name"; then
    printf 'erro: agente "%s" nao esta instalado\n' "$name" >&2
    return 4
  fi
  manifest_validate "$AGENTS_HOME" "$name" "$CONF" || return 4

  mf=$(manifest_path "$AGENTS_HOME" "$name")
  newv=$(manifest_field "$mf" version)
  oldv=$(lock_version "$lockfile" "$name")
  target=$(lock_target "$lockfile" "$name")

  if [ "$(version_cmp "$newv" "$oldv")" != "1" ]; then
    printf 'nada a fazer (%s ja na versao mais nova: %s)\n' "$name" "$oldv"
    return 0
  fi

  # Pre-checa conflito no destino atual (o artefato antigo pertence ao agente),
  # para nunca deixar estado parcial.
  dest=$(targets_default_dest "$CONF" "$target"); dest=${dest%/}
  ext=$(targets_ext "$CONF" "$target")
  destrel="$dest/$name.$ext"
  if ! plan_conflict "$proj" "$lockfile" "$name" "$destrel"; then
    return 3
  fi

  remove_agent_files "$proj" "$lockfile" "$name"
  lock_remove_agent "$lockfile" "$name"
  install_agent "$name" "$target" >/dev/null || return $?

  printf 'atualizado %s %s -> %s\n' "$name" "$oldv" "$newv"
  return 0
}
