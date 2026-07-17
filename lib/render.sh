#!/bin/sh
# Renderizadores por alvo: transformam a fonte canonica (formato Claude) no
# artefato nativo de cada alvo. Nao escrevem em disco; ecoam no stdout.

# Extrai um campo do frontmatter YAML da fonte (entre a primeira e a segunda linha "---").
render_fm_field() { # source key
  awk -v k="$2" '
    NR == 1 && $0 == "---" { infm = 1; next }
    infm && $0 == "---" { exit }
    infm && index($0, k ": ") == 1 { print substr($0, length(k) + 3); exit }
  ' "$1"
}

# Ecoa o corpo da fonte (tudo apos o segundo "---"), removendo uma linha em branco inicial.
render_body() { # source
  awk '
    NR == 1 && $0 == "---" { infm = 1; next }
    infm && $0 == "---" { infm = 0; started = 1; next }
    started {
      if (!seen && $0 == "") next
      seen = 1
      print
    }
  ' "$1"
}

# Normaliza um nome para identificador valido (Codex): [^A-Za-z0-9_] -> _
render_name_norm() { # name
  printf '%s' "$1" | sed 's/[^A-Za-z0-9_]/_/g'
}

# Escapa \ e " para uso em string com aspas (TOML basic string / YAML double-quoted).
render_str_escape() { # string
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# render_target <target> <source> <name>  -> artefato no stdout
render_target() {
  target=$1 source=$2 name=$3
  desc=$(render_fm_field "$source" description)
  desc_esc=$(render_str_escape "$desc")

  case "$target" in
    claude)
      cat "$source"
      ;;
    codex)
      printf 'name = "%s"\n' "$(render_name_norm "$name")"
      printf 'description = "%s"\n' "$desc_esc"
      printf "developer_instructions = '''\n"
      render_body "$source"
      printf "'''\n"
      ;;
    opencode)
      printf -- '---\n'
      printf 'description: "%s"\n' "$desc_esc"
      printf 'mode: subagent\n'
      printf -- '---\n\n'
      render_body "$source"
      ;;
    *)
      printf 'erro: sem renderizador para o alvo "%s"\n' "$target" >&2
      return 1
      ;;
  esac
}
