#!/bin/sh
# Parse e validacao do manifesto do agente.
# Manifesto: agents/<name>/manifest (formato linha a linha, ver data-model.md).

manifest_path() { # catalog name
  printf '%s/agents/%s/manifest' "$1" "$2"
}

manifest_field() { # manifest_file key
  awk -v k="$2" '
    index($0, k ": ") == 1 { print substr($0, length(k) + 3); exit }
  ' "$1"
}

manifest_targets() { # manifest_file
  awk '
    /^target:[[:space:]]/ { v = $0; sub(/^target:[[:space:]]*/, "", v); print v }
  ' "$1"
}

manifest_supports() { # manifest_file target
  manifest_targets "$1" | grep -qx "$2"
}

manifest_target_dest() { # manifest_file target
  awk -v tgt="$2" '
    /^target:[[:space:]]/ { v = $0; sub(/^target:[[:space:]]*/, "", v); incur = (v == tgt); next }
    incur && $0 ~ /^[[:space:]]+dest:[[:space:]]/ { v = $0; sub(/^[[:space:]]*dest:[[:space:]]*/, "", v); print v; exit }
  ' "$1"
}

manifest_target_files() { # manifest_file target
  awk -v tgt="$2" '
    /^target:[[:space:]]/ { v = $0; sub(/^target:[[:space:]]*/, "", v); incur = (v == tgt); next }
    incur && $0 ~ /^[[:space:]]+file:[[:space:]]/ { v = $0; sub(/^[[:space:]]*file:[[:space:]]*/, "", v); print v }
  ' "$1"
}

# Retorna 0 se valido; caso contrario imprime erro em stderr e retorna 1.
manifest_validate() { # catalog name targets_conf
  catalog=$1 name=$2 conf=$3
  mf=$(manifest_path "$catalog" "$name")
  if [ ! -f "$mf" ]; then
    printf 'erro: manifesto ausente para o agente "%s"\n' "$name" >&2
    return 1
  fi
  for k in name version description; do
    if [ -z "$(manifest_field "$mf" "$k")" ]; then
      printf 'erro: manifesto de "%s" sem campo obrigatorio "%s"\n' "$name" "$k" >&2
      return 1
    fi
  done
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
    files=$(manifest_target_files "$mf" "$t")
    if [ -z "$files" ]; then
      printf 'erro: alvo "%s" de "%s" sem nenhum arquivo\n' "$t" "$name" >&2
      return 1
    fi
    for f in $files; do
      if [ ! -f "$catalog/agents/$name/$f" ]; then
        printf 'erro: arquivo "%s" do alvo "%s" nao existe em "%s"\n' "$f" "$t" "$name" >&2
        return 1
      fi
    done
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
