#!/bin/sh
# Leitura e escrita atomica do lock por projeto.
# Lock: <project>/.agents/lock  linhas: name<TAB>version<TAB>target<TAB>relpath

lock_path() { # project_dir
  printf '%s/.agents/lock' "$1"
}

lock_has() { # lockfile name
  [ -f "$1" ] && grep -q "^$2	" "$1"
}

lock_version() { # lockfile name
  [ -f "$1" ] || return 0
  awk -F'\t' -v n="$2" '$1 == n { print $2; exit }' "$1"
}

lock_target() { # lockfile name
  [ -f "$1" ] || return 0
  awk -F'\t' -v n="$2" '$1 == n { print $3; exit }' "$1"
}

lock_files() { # lockfile name
  [ -f "$1" ] || return 0
  awk -F'\t' -v n="$2" '$1 == n { print $4 }' "$1"
}

# 0 se relpath ja consta como pertencente ao agente name.
lock_belongs() { # lockfile name relpath
  [ -f "$1" ] || return 1
  awk -F'\t' -v n="$2" -v p="$3" '$1 == n && $4 == p { found = 1 } END { exit(found ? 0 : 1) }' "$1"
}

lock_add() { # lockfile name version target relpath
  lf=$1
  d=$(dirname "$lf")
  [ -d "$d" ] || mkdir -p "$d"
  tmp="$lf.tmp.$$"
  [ -f "$lf" ] && cat "$lf" >"$tmp" || : >"$tmp"
  printf '%s\t%s\t%s\t%s\n' "$2" "$3" "$4" "$5" >>"$tmp"
  mv "$tmp" "$lf"
}

lock_remove_agent() { # lockfile name
  lf=$1 name=$2
  [ -f "$lf" ] || return 0
  tmp="$lf.tmp.$$"
  grep -v "^$name	" "$lf" >"$tmp" 2>/dev/null || : >"$tmp"
  mv "$tmp" "$lf"
}
