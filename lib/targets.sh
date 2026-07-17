#!/bin/sh
# Deteccao de alvo e resolucao de destino a partir de targets.conf.
# targets.conf: target|dest_default|marker|min_version

targets_field() { # conf target fieldnum
  awk -F'|' -v tgt="$2" -v n="$3" '
    /^[[:space:]]*#/ { next }
    $1 == tgt { print $n; exit }
  ' "$1"
}

targets_known() { # conf target
  awk -F'|' -v tgt="$2" '
    /^[[:space:]]*#/ { next }
    $1 == tgt { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$1"
}

targets_default_dest() { targets_field "$1" "$2" 2; }
targets_marker() { targets_field "$1" "$2" 3; }
targets_min_version() { targets_field "$1" "$2" 4; }

targets_all() { # conf
  awk -F'|' '/^[[:space:]]*#/ { next } NF >= 1 && $1 != "" { print $1 }' "$1"
}

# Detecta o alvo em uso no projeto pelos diretorios marcadores.
# Ecoa o alvo detectado e retorna 0; se nenhum ou multiplos, retorna 1 (erro em stderr).
targets_detect() { # conf project_dir
  conf=$1 proj=$2 found='' count=0
  for t in $(targets_all "$conf"); do
    m=$(targets_marker "$conf" "$t")
    if [ -n "$m" ] && [ -d "$proj/$m" ]; then
      found=$t
      count=$((count + 1))
    fi
  done
  if [ "$count" -eq 1 ]; then
    printf '%s\n' "$found"
    return 0
  fi
  if [ "$count" -eq 0 ]; then
    printf 'erro: nenhum alvo suportado detectado no projeto; informe --target <claude|codex|opencode>\n' >&2
  else
    printf 'erro: multiplos alvos detectados no projeto; informe --target <claude|codex|opencode>\n' >&2
  fi
  return 1
}
