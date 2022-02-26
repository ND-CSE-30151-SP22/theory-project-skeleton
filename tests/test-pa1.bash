#!/bin/bash

set -e
set -u
set -o pipefail

ROOT="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"/..
BIN=$ROOT/bin.$(uname | tr A-Z a-z)
SUBMIT=$ROOT/pa1
EXAMPLES=$ROOT/examples
TMPDIR=${TMPDIR:-/tmp}/test-pa1.$$
mkdir -p $TMPDIR
trap "rm -rf -- $TMPDIR" EXIT
trap "pkill -9 -g0; exit 130" INT

test_inputs() {
  local nfa_file=$1
  local check_path=$2
  shift 2
  local inputs=("$@")
  for W in "${inputs[@]}"; do
    echo -n "nfa_path $nfa_file \"$W\": "
    if {
      if $check_path; then
        diff <("$BIN/nfa_path" "$EXAMPLES/$nfa_file" "$W") <("$SUBMIT/nfa_path" "$EXAMPLES/$nfa_file" "$W")
      else
        diff <("$BIN/nfa_path" "$EXAMPLES/$nfa_file" "$W" | head -1) <("$SUBMIT/nfa_path" "$EXAMPLES/$nfa_file" "$W" | head -1)
      fi
    }; then
      echo PASSED
    else
      echo FAILED
    fi
  done
}

if [[ -x $SUBMIT/nfa_path ]]; then

    test_inputs sipser-n1.nfa false 010110 111
    test_inputs sipser-n1.nfa true "" 0 1 00 01 10 11 000 001 010 011 100 101 110
    test_inputs sipser-n3.nfa false "" 000000
    test_inputs sipser-n3.nfa true 0 00 000 0000 00000
    test_inputs sipser-n4.nfa true "" a baba baa b bb babba
    test_inputs epsilons.nfa false "" a aa aaa
    test_inputs cycle.nfa false "" a
    test_inputs slow1.nfa false "" a aa aaa
    test_inputs slow2.nfa false "" a aa aaa aaaa aaaaa
    test_inputs slow3.nfa false "" a aa aaa aaaa aaaaa aaaaaa aaaaaaa

    echo "time nfa_path (this should look linear):"
    RE=
    W=
    for I in $(seq 1 100); do
	RE="(a|)(|a)${RE}aa"
	W="${W}aa"
	if [ $(($I**2/1000)) -gt $((($I-1)**2/1000)) ]; then
	    printf "n=%3d: " "$I"
            nfa_file=$TMPDIR/n$I.nfa
            stdout=$TMPDIR/n$I.out
            timefile=$TMPDIR/n$I.time
	    "$BIN/re_to_nfa" "$RE" > "$nfa_file"
            timeout 5s bash -c 'time -p "$@"' -- "$SUBMIT/nfa_path" "$nfa_file" "$W" >"$stdout" 2>"$timefile" &
            wait $! && rc=$? || rc=$?
            if [[ $rc -eq 124 ]]; then
              echo "FAILED (TIMEOUT)"
              echo "Running command again for debugging:"
              timeout 5s "$SUBMIT/nfa_path" "$nfa_file" "$W" || true
            else
              diff <("$BIN/nfa_path" "$nfa_file" "$W") "$stdout" || echo "FAILED"
              awk '/^(user|sys)/ { t += $2; } !/^(real|user|sys)/ { print "WARNING:", $0; } END { printf "%*s\n", t*50, "*"; }' "$timefile"
            fi
	fi
    done

else
  echo "nfa_path: SKIPPED"
fi
