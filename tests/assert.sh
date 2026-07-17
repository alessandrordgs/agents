#!/bin/sh
# Helper minimo de assercao para os testes (POSIX sh, sem framework).

ASSERT_FAILS=0

assert_eq() { # expected actual msg
  if [ "$1" = "$2" ]; then
    printf 'ok: %s\n' "$3"
  else
    printf 'FAIL: %s\n  expected: [%s]\n  actual:   [%s]\n' "$3" "$1" "$2" >&2
    ASSERT_FAILS=$((ASSERT_FAILS + 1))
  fi
}

assert_exit() { # expected_code actual_code msg
  if [ "$1" -eq "$2" ]; then
    printf 'ok: exit %s (%s)\n' "$2" "$3"
  else
    printf 'FAIL: exit expected %s got %s (%s)\n' "$1" "$2" "$3" >&2
    ASSERT_FAILS=$((ASSERT_FAILS + 1))
  fi
}

assert_file_exists() { # path msg
  if [ -e "$1" ]; then
    printf 'ok: exists %s\n' "$1"
  else
    printf 'FAIL: missing %s (%s)\n' "$1" "$2" >&2
    ASSERT_FAILS=$((ASSERT_FAILS + 1))
  fi
}

assert_file_absent() { # path msg
  if [ ! -e "$1" ]; then
    printf 'ok: absent %s\n' "$1"
  else
    printf 'FAIL: present %s (%s)\n' "$1" "$2" >&2
    ASSERT_FAILS=$((ASSERT_FAILS + 1))
  fi
}

assert_done() {
  if [ "$ASSERT_FAILS" -ne 0 ]; then
    printf '\n%s assertion(s) failed\n' "$ASSERT_FAILS" >&2
    exit 1
  fi
  printf '\nall assertions passed\n'
}
