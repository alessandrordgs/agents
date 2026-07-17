#!/bin/sh
# Parse e validacao do manifesto do agente (schema com source + targets).
# Manifesto: agents/<name>/manifest
#   name: <name>
#   version: <semver>
#   description: <one line>
#   source: <arquivo canonico relativo a agents/<name>/>
#   targets: <lista separada por espaco>

manifest_path() { # catalog name
  printf '%s/agents/%s/manifest' "$1" "$2"
}

manifest_field() { # manifest_file key
  awk -v k="$2" '
    index($0, k ": ") == 1 { print substr($0, length(k) + 3); exit }
  ' "$1"
}

manifest_source() { # manifest_file
  manifest_field "$1" source
}

manifest_targets() { # manifest_file  -> lista separada por espaco
  manifest_field "$1" targets
}

manifest_supports() { # manifest_file target
  for t in $(manifest_targets "$1"); do
    [ "$t" = "$2" ] && return 0
  done
  return 1
}

# 0 se o agente e oculto (hidden: true), do contrario 1.
manifest_hidden() { # manifest_file
  [ "$(manifest_field "$1" hidden)" = "true" ]
}

# Retorna 0 se valido; caso contrario imprime erro em stderr e retorna 1.
manifest_validate() { # catalog name targets_conf
  catalog=$1 name=$2 conf=$3
  mf=$(manifest_path "$catalog" "$name")
  if [ ! -f "$mf" ]; then
    printf 'erro: manifesto ausente para o agente "%s"\n' "$name" >&2
    return 1
  fi
  for k in name version description source; do
    if [ -z "$(manifest_field "$mf" "$k")" ]; then
      printf 'erro: manifesto de "%s" sem campo obrigatorio "%s"\n' "$name" "$k" >&2
      return 1
    fi
  done
  src=$(manifest_source "$mf")
  if [ ! -f "$catalog/agents/$name/$src" ]; then
    printf 'erro: fonte "%s" do agente "%s" nao existe\n' "$src" "$name" >&2
    return 1
  fi
  tgts=$(manifest_targets "$mf")
  if [ -z "$tgts" ]; then
    printf 'erro: manifesto de "%s" nao declara nenhum alvo\n' "$name" >&2
    return 1
  fi
  for t in $tgts; do
    if ! targets_known "$conf" "$t"; then
      printf 'erro: alvo desconhecido "%s" no manifesto de "%s"\n' "$t" "$name" >&2
      return 1
    fi
  done
  return 0
}

# Compara versoes semver. Ecoa: 0 iguais, 1 se a>b, 2 se a<b.
version_cmp() { # a b
  awk -v a="$1" -v b="$2" 'BEGIN {
    na = split(a, A, "."); nb = split(b, B, ".")
    n = (na > nb) ? na : nb
    for (i = 1; i <= n; i++) {
      x = (i <= na) ? A[i] + 0 : 0
      y = (i <= nb) ? B[i] + 0 : 0
      if (x > y) { print 1; exit }
      if (x < y) { print 2; exit }
    }
    print 0
  }'
}
