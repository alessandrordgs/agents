#!/bin/sh
# Auto atualizacao da CLI (git pull no AGENTS_HOME).

# Re-renderiza os agentes instalados no projeto atual a partir do catalogo novo.
# ponytail: usa o codigo ja carregado neste processo; se o proprio render mudou no
# pull, a nova logica so vale no proximo run. Upgrade: re-exec apos o pull.
refresh_installed() {
  proj=$PWD
  lockfile=$(lock_path "$proj")
  [ -f "$lockfile" ] || return 0
  names=$(awk -F'\t' '{ print $1 }' "$lockfile" | sort -u)
  [ -n "$names" ] || return 0

  ui_info "Atualizando agentes instalados em $proj"
  for name in $names; do
    if ! manifest_validate "$AGENTS_HOME" "$name" "$CONF" >/dev/null 2>&1; then
      ui_warn "$name: nao esta mais no catalogo, mantido"
      continue
    fi
    tgts=$(awk -F'\t' -v n="$name" '$1 == n { print $3 }' "$lockfile" | sort -u)
    oldv=$(lock_version "$lockfile" "$name")
    remove_agent_files "$proj" "$lockfile" "$name"
    lock_remove_agent "$lockfile" "$name"
    for t in $tgts; do
      install_agent "$name" "$t" >/dev/null 2>&1 || ui_err "$name ($t): falha"
    done
    newv=$(lock_version "$lockfile" "$name")
    if [ "$oldv" = "$newv" ]; then
      ui_skip "$name: ok ($newv)"
    else
      ui_ok "$name: $oldv -> $newv"
    fi
  done
}

# Atualiza o proprio agents e, em seguida, os agentes instalados no projeto atual.
# Retorna 0 em sucesso/no-op, 1 em erro.
self_update() {
  if [ ! -d "$AGENTS_HOME/.git" ]; then
    printf 'erro: %s nao e um repositorio git; reinstale via install.sh\n' "$AGENTS_HOME" >&2
    return 1
  fi
  if ! spinner_run 'Atualizando agents' git -C "$AGENTS_HOME" pull --ff-only --quiet; then
    ui_err 'falha ao atualizar (git pull)'
    return 1
  fi
  ui_ok 'agents atualizado'
  refresh_installed
  return 0
}

# Check de startup: se houver atualizacao, pergunta uma vez ao usuario.
# Silencioso e nao bloqueante: so age em terminal, no maximo 1x/dia, e nunca
# interrompe o comando por falta de rede.
self_update_check() {
  [ -d "$AGENTS_HOME/.git" ] || return 0

  stamp="$AGENTS_HOME/.last_update_check"
  now=$(date +%s 2>/dev/null || printf '0')
  if [ -f "$stamp" ]; then
    last=$(cat "$stamp" 2>/dev/null || printf '0')
    [ $((now - last)) -lt 86400 ] && return 0
  fi

  if ! spinner_run 'Procurando atualizacoes do agents' git -C "$AGENTS_HOME" fetch --quiet 2>/dev/null; then
    printf '%s\n' "$now" >"$stamp" 2>/dev/null || true
    return 0
  fi
  printf '%s\n' "$now" >"$stamp" 2>/dev/null || true

  behind=$(git -C "$AGENTS_HOME" rev-list --count 'HEAD..@{u}' 2>/dev/null || printf '0')
  [ "$behind" -gt 0 ] 2>/dev/null || return 0

  printf 'Quer atualizar o agents? (%s versao(oes) atras) [y/N] ' "$behind" >/dev/tty 2>/dev/null || return 0
  IFS= read -r ans </dev/tty 2>/dev/null || return 0
  case "$ans" in
    y | Y | s | S) self_update ;;
    *) : ;;
  esac
}
